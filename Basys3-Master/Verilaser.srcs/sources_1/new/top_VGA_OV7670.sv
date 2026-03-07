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

    ImgMemReader U_FBufferReader (
        .DE        (DE),
        .x_pixel   (x_pixel),
        .y_pixel   (y_pixel),
        .addr      (rAddr),
        .imgData   (rData),
        .port_red  (port_red),
        .port_green(port_green),
        .port_blue (port_blue)
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
        .wData(wData)
    );

    OV7670_Init_Controller #(
        .N_REGS(60)
    ) U_INIT_CONTROLLER (
        .clk  (clk_100m),
        .reset(reset),
        .sda  (sda),
        .scl  (scl)
    );

endmodule
