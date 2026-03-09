`timescale 1ns / 1ps

module top_VGA_OV7670 (
    input  logic       clk,
    input  logic       reset,
    //ov 7670 side
    output logic       xclk,
    input  logic       pclk,
    input  logic       href,
    input  logic       vsync,
    input  logic [7:0] data,
    output logic       scl,
    inout  wire        sda,
    //vga port side
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue,
    // I2C for STM32 (Pmod JA)
    output logic       i2c_scl,
    inout  wire        i2c_sda
);
    logic                         clk_100m;
    logic [                  9:0] x_pixel;
    logic [                  9:0] y_pixel;
    logic                         DE;

    logic                         rclk;
    logic [$clog2(320*240) - 1:0] rAddr;
    logic [                 15:0] rData;

    logic                         we;
    logic [$clog2(320*240) - 1:0] wAddr;
    logic [                 15:0] wData;

    logic                         locked;

    clk_wiz_0 instance_name (
        // Clock out ports
        .clk_out1(clk_100m),  // output clk_out1 -> 100MHz 
        .clk_out2(xclk),      // output clk_out2 -> 25MHz
        // Status and control signals
        .reset   (reset),     // input reset
        .locked  (locked),    // output locked
        // Clock in ports
        .clk_in1 (clk)
    );  // input clk_in1

    VGA_Decoder U_VGA_DECODER (
        .clk    (clk_100m),
        .reset  (reset),
        .pclk   (rclk),
        .h_sync (h_sync),
        .v_sync (v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE     (DE)
    );

    OV7670_MemController U_OV7670_MemController (
        .pclk (pclk),
        .reset(reset),
        .href (href),
        .vsync(vsync),
        .data (data),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData)
    );

    FrameBuffer U_FRAMEBUFFER (
        // write side
        .wclk (pclk),
        .we   (we),
        .waddr(wAddr),
        .wData(wData),
        .rclk (rclk),
        .raddr(rAddr),
        .rData(rData)
    );

    logic w_DE;
    logic [9:0] w_x_pixel_o, w_y_pixel_o;
    logic [3:0] w_red_o, w_green_o, w_blue_o;

    logic w_DE_o_HSV;
    logic [9:0] w_x_out_HSV, w_y_out_HSV;
    logic [7:0] w_H_o_HSV, w_S_o_HSV, w_V_o_HSV;

    ImgMemReader U_FBufferReader (
        .clk      (rclk),
        .DE       (DE),
        .x_pixel  (x_pixel),
        .y_pixel  (y_pixel),
        .addr     (rAddr),
        .imgData  (rData),
        .red_o    (w_red_o),
        .green_o  (w_green_o),
        .blue_o   (w_blue_o),
        .DE_o     (w_DE),
        .x_pixel_o(w_x_pixel_o),
        .y_pixel_o(w_y_pixel_o)
    );

    OV7670_Init_Controller #(
        .N_REGS(66)
    ) U_INIT_CONTROLLER (
        .clk  (clk_100m),
        .reset(reset),
        .sda  (sda),
        .scl  (scl)
    );

    HSV_Converter u_HSV_Converter (
        .clk   (rclk),
        .reset (reset),
        .DE_in (w_DE),
        .x_in  (w_x_pixel_o),
        .y_in  (w_y_pixel_o),
        .R_in  (w_red_o),
        .G_in  (w_green_o),
        .B_in  (w_blue_o),
        .DE_out(w_DE_o_HSV),
        .x_out (w_x_out_HSV),
        .y_out (w_y_out_HSV),
        .H_out (w_H_o_HSV),
        .S_out (w_S_o_HSV),
        .V_out (w_V_o_HSV)
    );

    logic w_DE_o_CD;
    logic [9:0] w_x_out_CD, w_y_out_CD;
    logic w_red_detect, w_green_detect, w_blue_detect;

    Color_Detect u_Color_Detect (
        .clk         (rclk),
        .reset       (reset),
        .DE_in       (w_DE_o_HSV),
        .x_in        (w_x_out_HSV),
        .y_in        (w_y_out_HSV),
        .H_in        (w_H_o_HSV),
        .S_in        (w_S_o_HSV),
        .V_in        (w_V_o_HSV),
        .DE_out      (w_DE_o_CD),
        .x_out       (w_x_out_CD),
        .y_out       (w_y_out_CD),
        .red_detect  (w_red_detect),
        .green_detect(w_green_detect),
        .blue_detect (w_blue_detect)
    );

    logic w_DE_o_BF;
    logic [9:0] w_x_out_BF, w_y_out_BF;
    logic w_red_blob, w_green_blob, w_blue_blob;

    Blob_Filter u_Blob_Filter (
        .clk         (rclk),
        .reset       (reset),
        .DE_in       (w_DE_o_CD),
        .x_in        (w_x_out_CD),
        .y_in        (w_y_out_CD),
        .red_detect  (w_red_detect),
        .green_detect(w_green_detect),
        .blue_detect (w_blue_detect),
        .DE_out      (w_DE_o_BF),
        .x_out       (w_x_out_BF),
        .y_out       (w_y_out_BF),
        .red_blob    (w_red_blob),
        .green_blob  (w_green_blob),
        .blue_blob   (w_blue_blob)
    );

    logic [9:0] w_r_target_x, w_r_target_y;
    logic [9:0] w_g_target_x, w_g_target_y;
    logic [9:0] w_b_target_x, w_b_target_y;
    logic w_done;

    Centroid u_Centroid (
        .clk       (rclk),
        .reset     (reset),
        .DE_in     (w_DE_o_BF),
        .x_in      (w_x_out_BF),
        .y_in      (w_y_out_BF),
        .red_blob  (w_red_blob),
        .green_blob(w_green_blob),
        .blue_blob (w_blue_blob),
        .r_target_x(w_r_target_x),
        .r_target_y(w_r_target_y),
        .g_target_x(w_g_target_x),
        .g_target_y(w_g_target_y),
        .b_target_x(w_b_target_x),
        .b_target_y(w_b_target_y),
        .done      (w_done),
        .r_status(),
        .g_status(),
        .b_status()
    );

    logic [11:0] w_camera_rgb;
    assign w_camera_rgb = {w_red_o, w_green_o, w_blue_o};
    logic [11:0] w_vga_rgb;

    Crossline_Display u_Crossline_Display (
        .vga_x     (w_x_pixel_o),
        .vga_y     (w_y_pixel_o),
        .camera_rgb(w_camera_rgb),
        .r_target_x(w_r_target_x),
        .r_target_y(w_r_target_y),
        .g_target_x(w_g_target_x),
        .g_target_y(w_g_target_y),
        .b_target_x(w_b_target_x),
        .b_target_y(w_b_target_y),
        .red_blob(w_red_blob),
        .green_blob(w_green_blob),
        .blue_blob(w_blue_blob),
        .vga_rgb   (w_vga_rgb)
    );

    assign port_red   = w_DE ? w_vga_rgb[11:8] : 4'd0;
    assign port_green = w_DE ? w_vga_rgb[7:4] : 4'd0;
    assign port_blue  = w_DE ? w_vga_rgb[3:0] : 4'd0;

    // I2C serializer + master (clk_100m domain)
    wire       w_i2c_en, w_i2c_start, w_i2c_stop, w_i2c_nack;
    wire [7:0] w_i2c_tx_data;
    wire       w_i2c_tx_done, w_i2c_tx_ready;
    wire [7:0] w_i2c_rx_data;
    wire       w_i2c_rx_done;

    i2c_serializer #(
        .SLAVE_ADDR_1(7'h10),
        .SLAVE_ADDR_2(7'h11),
        .SLAVE_ADDR_3(7'h12)
    ) u_i2c_serializer (
        .clk       (clk_100m),
        .reset     (reset),
        .done      (w_done),
        .r_target_x(w_r_target_x),
        .r_target_y(w_r_target_y),
        .g_target_x(w_g_target_x),
        .g_target_y(w_g_target_y),
        .b_target_x(w_b_target_x),
        .b_target_y(w_b_target_y),
        .i2c_en    (w_i2c_en),
        .i2c_start (w_i2c_start),
        .i2c_stop  (w_i2c_stop),
        .i2c_nack  (w_i2c_nack),
        .tx_data   (w_i2c_tx_data),
        .tx_done   (w_i2c_tx_done),
        .tx_ready  (w_i2c_tx_ready)
    );

    i2c_master u_i2c_master (
        .clk      (clk_100m),
        .reset    (reset),
        .i2c_en   (w_i2c_en),
        .i2c_start(w_i2c_start),
        .i2c_stop (w_i2c_stop),
        .i2c_nack (w_i2c_nack),
        .tx_data  (w_i2c_tx_data),
        .tx_done  (w_i2c_tx_done),
        .tx_ready (w_i2c_tx_ready),
        .rx_data  (w_i2c_rx_data),
        .rx_done  (w_i2c_rx_done),
        .scl      (i2c_scl),
        .sda      (i2c_sda)
    );
endmodule
