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
    //vga port side
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue,
    //
    output logic [2:0] led
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

    logic mask_red, mask_green, mask_blue;
    logic [8:0] c_x_pixel;
    logic [7:0] c_y_pixel;
    logic [8:0] center_x_r;
    logic [7:0] center_y_r;
    logic [8:0] center_x_g;
    logic [7:0] center_y_g;
    logic [8:0] center_x_b;
    logic [7:0] center_y_b;
    logic       valid_r;
    logic       valid_g;
    logic       valid_b;


    assign led[0] = valid_r;
    assign led[1] = valid_g;
    assign led[2] = valid_b;

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

    // ImgMemReader U_FBufferReader (
    //     .DE        (DE),
    //     .x_pixel   (x_pixel),
    //     .y_pixel   (y_pixel),
    //     .addr      (rAddr),
    //     .imgData   (rData),
    //     .port_red  (port_red),
    //     .port_green(port_green),
    //     .port_blue (port_blue)
    // );
    logic [3:0] orig_r, orig_g, orig_b;
    ImgMemReader U_FBufferReader (
        .DE        (DE),
        .x_pixel   (x_pixel),
        .y_pixel   (y_pixel),
        .addr      (rAddr),
        .imgData   (rData),
        .port_red  (orig_r),
        .port_green(orig_g),
        .port_blue (orig_b)
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

    OV7670_MemController U_OV7670_MemController (
        .pclk (pclk),
        .reset(reset),
        .href (href),
        .vsync(vsync),
        .data (data),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        .x_pixel(c_x_pixel),
        .y_pixel(c_y_pixel)
    );
    logic vga_mask_red, vga_mask_green, vga_mask_blue;
    RGB2HSV u_RGB2HSV_r (
        .pixel_data(rData),
        .mask_red  (vga_mask_red),
        .mask_green(vga_mask_green),
        .mask_blue (vga_mask_blue)
    );
    assign port_red   = vga_mask_red ? 4'hF : orig_r;
    assign port_green = vga_mask_green ? 4'hF : orig_g;
    assign port_blue  = vga_mask_blue ? 4'hF : orig_b;


    RGB2HSV u_RGB2HSV (
        .pixel_data(wData),
        .mask_red  (mask_red),
        .mask_green(mask_green),
        .mask_blue (mask_blue)
    );

    Blob_Detector u_blob_detector (
        .pclk(pclk),
        .reset(reset),
        .we(we),
        .mask_red(mask_red),
        .mask_green(mask_green),
        .mask_blue(mask_blue),
        .x_pixel(c_x_pixel),
        .y_pixel(c_y_pixel),
        .vsync(vsync),
        .center_x_r(center_x_r),
        .center_y_r(center_y_r),
        .center_x_g(center_x_g),
        .center_y_g(center_y_g),
        .center_x_b(center_x_b),
        .center_y_b(center_y_b),
        .valid_r(valid_r),
        .valid_g(valid_g),
        .valid_b(valid_b)

    );

endmodule
