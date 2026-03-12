`timescale 1ns / 1ps

module ImgMemReader (
    input  logic                       clk,
    input  logic                       DE,
    input  logic [                9:0] x_pixel,
    input  logic [                9:0] y_pixel,
    input  logic                       upscale,  // 0: 타일링(4분할), 1: 2배 업스케일
    output logic [$clog2(320*240)-1:0] addr,
    input  logic [               15:0] imgData,
    output logic [                3:0] red_o,
    output logic [                3:0] green_o,
    output logic [                3:0] blue_o,
    output logic                       DE_o,
    output logic [                9:0] x_pixel_o,
    output logic [                9:0] y_pixel_o
);
    logic [8:0] map_x;
    logic [8:0] map_y;
    always_comb begin
        if (upscale) begin
            map_x = x_pixel[9:1];  // 640 -> 320 (2배 업스케일)
            map_y = y_pixel[9:1];  // 480 -> 240
        end else begin
            map_x = (x_pixel >= 320) ? (x_pixel - 320) : x_pixel;  // 타일링
            map_y = (y_pixel >= 240) ? (y_pixel - 240) : y_pixel;
        end
    end

    logic valid_640x480;
    assign valid_640x480 = DE && (x_pixel < 640) && (y_pixel < 480);

    assign addr = valid_640x480 ? (320 * map_y + map_x) : 'bz;
    assign {red_o,green_o,blue_o} = valid_640x480 ? {imgData[15:12],imgData[10:7],imgData[4:1]} : 0;

    always_ff @(posedge clk) begin
        DE_o <= valid_640x480;
        x_pixel_o <= x_pixel;
        y_pixel_o <= y_pixel;
    end
endmodule

module ImgMemReader_upscaler (
    input  logic                       DE,
    input  logic [                9:0] x_pixel,
    input  logic [                9:0] y_pixel,
    output logic [$clog2(320*240)-1:0] addr,
    input  logic [               15:0] imgData,
    output logic [                3:0] port_red,
    output logic [                3:0] port_green,
    output logic [                3:0] port_blue
);
    assign addr = DE ? (320 * y_pixel[9:1] + x_pixel[9:1]) : 'bz;
    assign {port_red, port_green, port_blue} = DE ? {imgData[15:12], imgData[10:7], imgData[4:1]} : 0;
endmodule
