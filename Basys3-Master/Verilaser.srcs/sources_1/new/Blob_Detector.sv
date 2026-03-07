`timescale 1ns / 1ps

module Blob_Detector (
    input  logic       pclk,
    input  logic       reset,
    input  logic       we,
    input  logic       mask_red,
    input  logic       mask_green,
    input  logic       mask_blue,
    input  logic [8:0] x_pixel,
    input  logic [7:0] y_pixel,
    input  logic       vsync,
    output logic [8:0] center_x_r,
    output logic [7:0] center_y_r,
    output logic [8:0] center_x_g,
    output logic [7:0] center_y_g,
    output logic [8:0] center_x_b,
    output logic [7:0] center_y_b,
    output logic       valid_r,
    output logic       valid_g,
    output logic       valid_b

);
    localparam THRESHOLD = (320*240)/10;

    logic [$clog2(320*240)-1:0]
        pixel_counter_r, pixel_counter_g, pixel_counter_b;

    //sum_max_x =(0 + 1 + ... + 319) * 240 = 12,249,600
    //sum_max_y =(0 + 1 + ... + 239) * 320 = 9,177,600
    logic [25:0] sum_x_r, sum_y_r, sum_x_g, sum_y_g, sum_x_b, sum_y_b;

    logic vsync_delay;
    wire  vsync_rising_edge = (vsync == 1'b1) && (vsync_delay == 1'b0);

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            valid_r         <= 0;
            valid_g         <= 0;
            valid_b         <= 0;
            sum_x_r         <= 0;
            sum_y_r         <= 0;
            sum_x_g         <= 0;
            sum_y_g         <= 0;
            sum_x_b         <= 0;
            sum_y_b         <= 0;
            pixel_counter_r <= 0;
            pixel_counter_g <= 0;
            pixel_counter_b <= 0;
            center_x_r      <= 0;
            center_x_g      <= 0;
            center_x_b      <= 0;
            center_y_r      <= 0;
            center_y_g      <= 0;
            center_y_b      <= 0;
            vsync_delay     <= 0;
        end else begin
            vsync_delay <= vsync;
            if (vsync_rising_edge) begin
                // Noise filtering & Division by Zero Prevention
                if (pixel_counter_r > THRESHOLD) begin
                    center_x_r <= sum_x_r / pixel_counter_r;
                    center_y_r <= sum_y_r / pixel_counter_r;
                    valid_r    <= 1'b1;
                end else begin
                    valid_r <= 1'b0;
                end
                if (pixel_counter_g > THRESHOLD) begin
                    center_x_g <= sum_x_g / pixel_counter_g;
                    center_y_g <= sum_y_g / pixel_counter_g;
                    valid_g    <= 1'b1;
                end else begin
                    valid_g <= 1'b0;
                end
                if (pixel_counter_b > THRESHOLD) begin
                    center_x_b <= sum_x_b / pixel_counter_b;
                    center_y_b <= sum_y_b / pixel_counter_b;
                    valid_b    <= 1'b1;
                end else begin
                    valid_b <= 1'b0;
                end
                sum_x_r <= 0;
                sum_y_r <= 0;
                pixel_counter_r <= 0;
                sum_x_g <= 0;
                sum_y_g <= 0;
                pixel_counter_g <= 0;
                sum_x_b <= 0;
                sum_y_b <= 0;
                pixel_counter_b <= 0;
            end else begin
                if (mask_red && we) begin
                    sum_x_r <= sum_x_r + x_pixel;
                    sum_y_r <= sum_y_r + y_pixel;
                    pixel_counter_r <= pixel_counter_r + 1;
                end
                if (mask_green && we) begin
                    sum_x_g <= sum_x_g + x_pixel;
                    sum_y_g <= sum_y_g + y_pixel;
                    pixel_counter_g <= pixel_counter_g + 1;
                end
                if (mask_blue && we) begin
                    sum_x_b <= sum_x_b + x_pixel;
                    sum_y_b <= sum_y_b + y_pixel;
                    pixel_counter_b <= pixel_counter_b + 1;
                end
            end
        end
    end
endmodule

