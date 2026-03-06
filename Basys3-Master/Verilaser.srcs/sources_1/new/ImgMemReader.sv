`timescale 1ns / 1ps

module ImgMemReader (
    input  logic                       DE,
    input  logic [                9:0] x_pixel,
    input  logic [                9:0] y_pixel,
    output logic [$clog2(320*240)-1:0] addr,
    input  logic [               15:0] imgData,
    output logic [                3:0] port_red,
    output logic [                3:0] port_green,
    output logic [                3:0] port_blue
);
    logic qvga_de;
    assign qvga_de = DE && (x_pixel < 320) && (y_pixel < 240);

    assign addr = qvga_de? (320 * y_pixel + x_pixel) : 'bz;
    // assign addr = DE ? (320 * (y_pixel >> 1) + (x_pixel >> 1)) : 'bz;
    assign {port_red, port_green, port_blue} = qvga_de ? {imgData[15:12], imgData[10:7], imgData[4:1]} : 0;

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
