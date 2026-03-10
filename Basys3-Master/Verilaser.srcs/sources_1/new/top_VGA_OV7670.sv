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
    output logic [3:0] port_blue
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

    Color_Detect #(
        .ROI_X_MIN(TARGET_X_MIN),
        .ROI_X_MAX(TARGET_X_MAX),
        .ROI_Y_MIN(TARGET_Y_MIN),
        .ROI_Y_MAX(TARGET_Y_MAX)
    ) u_color_detect (
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


    logic [9:0] w_r1_x, w_r1_y, w_r2_x, w_r2_y, w_r3_x, w_r3_y;
    logic [9:0] w_g1_x, w_g1_y, w_g2_x, w_g2_y, w_g3_x, w_g3_y;
    logic [9:0] w_b1_x, w_b1_y, w_b2_x, w_b2_y, w_b3_x, w_b3_y;

    // red channel centroid tracker
    Multi_Centroid u_Tracker_Red (
        .clk(rclk),
        .reset(reset),
        .DE_in(w_DE_o_BF),
        .x_in(w_x_out_BF),
        .y_in(w_y_out_BF),
        .blob_in(w_red_blob),  // input red_blob
        .t1_target_x(w_r1_x),
        .t1_target_y(w_r1_y),
        .t1_status(),
        .t2_target_x(w_r2_x),
        .t2_target_y(w_r2_y),
        .t2_status(),
        .t3_target_x(w_r3_x),
        .t3_target_y(w_r3_y),
        .t3_status(),
        .done()
    );

    // green channel centroid tracker
    Multi_Centroid u_Tracker_Green (
        .clk(rclk),
        .reset(reset),
        .DE_in(w_DE_o_BF),
        .x_in(w_x_out_BF),
        .y_in(w_y_out_BF),
        .blob_in(w_green_blob),  // input green_blob
        .t1_target_x(w_g1_x),
        .t1_target_y(w_g1_y),
        .t1_status(),
        .t2_target_x(w_g2_x),
        .t2_target_y(w_g2_y),
        .t2_status(),
        .t3_target_x(w_g3_x),
        .t3_target_y(w_g3_y),
        .t3_status(),
        .done()
    );

    // blue channel centroid tracker
    Multi_Centroid u_Tracker_Blue (
        .clk(rclk),
        .reset(reset),
        .DE_in(w_DE_o_BF),
        .x_in(w_x_out_BF),
        .y_in(w_y_out_BF),
        .blob_in(w_blue_blob),  // input blue_blob
        .t1_target_x(w_b1_x),
        .t1_target_y(w_b1_y),
        .t1_status(),
        .t2_target_x(w_b2_x),
        .t2_target_y(w_b2_y),
        .t2_status(),
        .t3_target_x(w_b3_x),
        .t3_target_y(w_b3_y),
        .t3_status(),
        .done()
    );


    logic [11:0] w_camera_rgb;
    assign w_camera_rgb = {w_red_o, w_green_o, w_blue_o};
    logic [11:0] w_vga_rgb;

    Crossline_Display #(
        .ROI_X_MIN(TARGET_X_MIN),
        .ROI_X_MAX(TARGET_X_MAX),
        .ROI_Y_MIN(TARGET_Y_MIN),
        .ROI_Y_MAX(TARGET_Y_MAX)
    ) u_display (
        .vga_x     (w_x_out_BF),
        .vga_y     (w_y_out_BF),
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

        .red_blob  (w_red_blob),
        .green_blob(w_green_blob),
        .blue_blob (w_blue_blob),
        .vga_rgb   (w_vga_rgb)
    );


    assign port_red   = w_DE ? w_vga_rgb[11:8] : 4'd0;
    assign port_green = w_DE ? w_vga_rgb[7:4] : 4'd0;
    assign port_blue  = w_DE ? w_vga_rgb[3:0] : 4'd0;

endmodule
