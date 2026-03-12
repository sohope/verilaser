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
    output logic       sccb_scl,
    inout  wire        sccb_sda,
    //vga port side
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue,
    // I2C for STM32 (Pmod JA)
    output logic       i2c_scl,
    inout  wire        i2c_sda,
    input  logic       RsRx,
    output logic       RsTx,
    // Display mode switch (0: 원본, 1: 디버깅)
    input  logic       sw
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

    localparam TARGET_X_MIN = 10'd010;  //x_min:000 
    localparam TARGET_X_MAX = 10'd310;  //x_max:320
    localparam TARGET_Y_MIN = 10'd010;  //y_min:000
    localparam TARGET_Y_MAX = 10'd230;  //y_max:240

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

    ImgMemReader U_FBufferReader (
        .clk(rclk),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .sw(sw),  // 0: 업스케일(원본), 1: 타일링(디버깅)
        .addr(rAddr),
        .imgData(rData),
        .red_o(w_red_o),
        .green_o(w_green_o),
        .blue_o(w_blue_o),
        .DE_o(w_DE),
        .x_pixel_o(w_x_pixel_o),
        .y_pixel_o(w_y_pixel_o)
    );

    OV7670_Init_Controller #(
        .N_REGS(66)
    ) U_INIT_CONTROLLER (
        .clk  (clk_100m),
        .reset(reset),
        .sda  (sccb_sda),
        .scl  (sccb_scl)
    );

    // Vision Pipeline
    logic w_DE_VP;
    logic [9:0] w_x_VP, w_y_VP;
    logic w_red_blob, w_green_blob, w_blue_blob;
    logic [9:0] w_r1_x, w_r1_y, w_r2_x, w_r2_y, w_r3_x, w_r3_y;
    logic [9:0] w_g1_x, w_g1_y, w_g2_x, w_g2_y, w_g3_x, w_g3_y;
    logic [9:0] w_b1_x, w_b1_y, w_b2_x, w_b2_y, w_b3_x, w_b3_y;
    logic r1_status, g1_status, b1_status;
    logic w_done_r, w_done_g, w_done_b;

    Vision_Pipeline #(
        .ROI_X_MIN(TARGET_X_MIN),
        .ROI_X_MAX(TARGET_X_MAX),
        .ROI_Y_MIN(TARGET_Y_MIN),
        .ROI_Y_MAX(TARGET_Y_MAX)
    ) u_Vision_Pipeline (
        .clk        (rclk),
        .reset      (reset),
        .DE_in      (w_DE),
        .x_in       (w_x_pixel_o),
        .y_in       (w_y_pixel_o),
        .R_in       (w_red_o),
        .G_in       (w_green_o),
        .B_in       (w_blue_o),
        // Blob 출력
        .DE_out     (w_DE_VP),
        .x_out      (w_x_VP),
        .y_out      (w_y_VP),
        .red_blob   (w_red_blob),
        .green_blob (w_green_blob),
        .blue_blob  (w_blue_blob),
        // Red targets
        .r1_target_x(w_r1_x),
        .r1_target_y(w_r1_y),
        .r2_target_x(w_r2_x),
        .r2_target_y(w_r2_y),
        .r3_target_x(w_r3_x),
        .r3_target_y(w_r3_y),
        .r1_status  (r1_status),
        .done_r     (w_done_r),
        // Green targets
        .g1_target_x(w_g1_x),
        .g1_target_y(w_g1_y),
        .g2_target_x(w_g2_x),
        .g2_target_y(w_g2_y),
        .g3_target_x(w_g3_x),
        .g3_target_y(w_g3_y),
        .g1_status  (g1_status),
        .done_g     (w_done_g),
        // Blue targets
        .b1_target_x(w_b1_x),
        .b1_target_y(w_b1_y),
        .b2_target_x(w_b2_x),
        .b2_target_y(w_b2_y),
        .b3_target_x(w_b3_x),
        .b3_target_y(w_b3_y),
        .b1_status  (b1_status),
        .done_b     (w_done_b)
    );

    logic [11:0] w_camera_rgb;
    assign w_camera_rgb = {w_red_o, w_green_o, w_blue_o};

    VGA_Display_Pipeline #(
        .ROI_X_MIN(TARGET_X_MIN),
        .ROI_X_MAX(TARGET_X_MAX),
        .ROI_Y_MIN(TARGET_Y_MIN),
        .ROI_Y_MAX(TARGET_Y_MAX)
    ) u_VGA_Display_Pipeline (
        .sw(sw),
        .DE(w_DE),
        .vga_x(w_x_VP),
        .vga_y(w_y_VP),
        .camera_rgb(w_camera_rgb),
        .r1_target_x(w_r1_x),
        .r1_target_y(w_r1_y),
        .r2_target_x(w_r2_x),
        .r2_target_y(w_r2_y),
        .r3_target_x(w_r3_x),
        .r3_target_y(w_r3_y),
        .g1_target_x(w_g1_x),
        .g1_target_y(w_g1_y),
        .g2_target_x(w_g2_x),
        .g2_target_y(w_g2_y),
        .g3_target_x(w_g3_x),
        .g3_target_y(w_g3_y),
        .b1_target_x(w_b1_x),
        .b1_target_y(w_b1_y),
        .b2_target_x(w_b2_x),
        .b2_target_y(w_b2_y),
        .b3_target_x(w_b3_x),
        .b3_target_y(w_b3_y),
        .red_blob(w_red_blob),
        .green_blob(w_green_blob),
        .blue_blob(w_blue_blob),
        .port_red(port_red),
        .port_green(port_green),
        .port_blue(port_blue)
    );

    // I2C serializer + master (clk_100m domain)
    // Multi_Centroid의 첫 번째 타겟을 I2C/UART로 전송
    wire w_i2c_en, w_i2c_start, w_i2c_stop, w_i2c_nack;
    wire [7:0] w_i2c_tx_data;
    wire w_i2c_tx_done, w_i2c_tx_ready;
    wire [7:0] w_i2c_rx_data;
    wire       w_i2c_rx_done;

    i2c_controller #(
        .SLAVE_ADDR_1(7'h10),
        .SLAVE_ADDR_2(7'h11),
        .SLAVE_ADDR_3(7'h12)
    ) u_i2c_controller (
        .clk       (clk_100m),
        .reset     (reset),
        .done      (w_done_r),
        .r_target_x(w_r1_x),
        .r_target_y(w_r1_y),
        .g_target_x(w_g1_x),
        .g_target_y(w_g1_y),
        .b_target_x(w_b1_x),
        .b_target_y(w_b1_y),
        .r_status  (r1_status),
        .g_status  (g1_status),
        .b_status  (b1_status),
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

    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //          UART
    logic       w_fifo_full;
    logic [7:0] w_fifo_wdata;
    logic       w_fifo_wr_en;

    uart_controller U_uart_controller (
        .clk(clk_100m),
        .reset(reset),
        .done(w_done_r),
        .r_target_x(w_r1_x),
        .r_target_y(w_r1_y),
        .r_status(r1_status),
        .g_target_x(w_g1_x),
        .g_target_y(w_g1_y),
        .g_status(g1_status),
        .b_target_x(w_b1_x),
        .b_target_y(w_b1_y),
        .b_status(b1_status),
        .fifo_full(w_fifo_full),
        .fifo_wdata(w_fifo_wdata),
        .fifo_wr_en(w_fifo_wr_en)
    );

    uart_tx_fifo #(
        .BPS(115200)
    ) U_uart_tx_fifo (
        .clk  (clk_100m),
        .reset(reset),
        .wdata(w_fifo_wdata),
        .wr   (w_fifo_wr_en),
        .full (w_fifo_full),
        .tx   (RsTx)
    );

    uart_rx_fifo #(
        .BPS(115200)
    ) U_uart_rx_fifo (
        .clk  (clk_100m),
        .reset(reset),
        .rx   (RsRx),
        .rd   (),
        .rdata(),
        .empty(),
        .full ()
    );
    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
endmodule
