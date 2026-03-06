`timescale 1ns / 1ps

module OV7670_MemController (
    input  logic                       pclk,
    input  logic                       reset,
    // ov7670 side
    input  logic                       href,
    input  logic                       vsync,
    input  logic [                7:0] data,
    // mem side
    output logic                       we,
    output logic [$clog2(320*240)-1:0] wAddr,
    output logic [               15:0] wData,
    output logic [                8:0] x_pixel,
    output logic [                7:0] y_pixel
);

    logic [15:0] pixelData;
    logic        pixelEvenOdd;

    assign wData = pixelData;

    always_ff @(posedge pclk, posedge reset) begin
        if (reset) begin
            we           <= 0;
            pixelData    <= 0;
            pixelEvenOdd <= 0;
            wAddr        <= 0;
            x_pixel      <= 0;
            y_pixel      <= 0;
        end else begin
            if (href) begin
                if (pixelEvenOdd == 1'b0) begin
                    we              <= 1'b0;
                    pixelData[15:8] <= data;
                    pixelEvenOdd    <= ~pixelEvenOdd;
                end else begin
                    we             <= 1'b1;
                    pixelData[7:0] <= data;
                    pixelEvenOdd   <= ~pixelEvenOdd;
                    wAddr          <= wAddr + 1;
                    if (x_pixel == 319) begin
                        x_pixel <= 0;
                        y_pixel <= y_pixel + 1;

                    end else begin
                        x_pixel <= x_pixel + 1;
                    end

                end
            end else if (vsync) begin
                we           <= 0;
                pixelEvenOdd <= 0;
                wAddr        <= 0;
                x_pixel      <= 0;
                y_pixel      <= 0;
            end
        end
    end
endmodule
