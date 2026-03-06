`timescale 1ns / 1ps

module FrameBuffer (
    // write side
    input logic wclk,
    input logic we,
    input logic [$clog2(320*240) - 1:0] waddr,
    input logic [15:0] wData,
    // read side 
    input logic rclk,
    input logic [$clog2(320*240) - 1:0] raddr,
    output logic [15:0] rData
);

    logic [15:0] mem[0:(320*240)-1];

    // write
    always_ff @(posedge wclk) begin
        if(we) mem[waddr] <= wData;
    end

    // read
    always_ff @(posedge rclk ) begin
        rData <= mem[raddr];
    end

    // LUT RAM
    // assign rData = mem[raddr];

endmodule
