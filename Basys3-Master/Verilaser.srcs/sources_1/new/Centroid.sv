`timescale 1ns / 1ps

module Centroid (
    input logic clk,
    input logic reset,

    input logic       DE_in,
    input logic [9:0] x_in,
    input logic [9:0] y_in,
    input logic       red_blob,
    input logic       green_blob,
    input logic       blue_blob,

    output logic [9:0] r_target_x,
    output logic [9:0] r_target_y,
    output logic [9:0] g_target_x,
    output logic [9:0] g_target_y,
    output logic [9:0] b_target_x,
    output logic [9:0] b_target_y,
    output logic       done
);

    logic [31:0] r_sum_x, r_sum_y;
    logic [31:0] g_sum_x, g_sum_y;
    logic [31:0] b_sum_x, b_sum_y;
    logic [19:0] r_count;
    logic [19:0] g_count;
    logic [19:0] b_count;

    logic frame_done;
    assign frame_done = (x_in == 319 && y_in == 239 && DE_in);

    logic q1_active;
    assign q1_active = DE_in && (x_in < 320) && (y_in < 240);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            r_sum_x <= 0;
            r_sum_y <= 0;
            g_sum_x <= 0;
            g_sum_y <= 0;
            b_sum_x <= 0;
            b_sum_y <= 0;
            r_count <= 0;
            g_count <= 0;
            b_count <= 0;
        end else if (frame_done) begin
            if (r_count > 0) begin
                r_target_x <= r_sum_x / r_count;
                r_target_y <= r_sum_y / r_count;
            end
            if (g_count > 0) begin
                g_target_x <= g_sum_x / g_count;
                g_target_y <= g_sum_y / g_count;
            end
            if (b_count > 0) begin
                b_target_x <= b_sum_x / b_count;
                b_target_y <= b_sum_y / b_count;
            end
            done    <= 1;
            r_sum_x <= 0;
            r_sum_y <= 0;
            r_count <= 0;
            g_sum_x <= 0;
            g_sum_y <= 0;
            g_count <= 0;
            b_sum_x <= 0;
            b_sum_y <= 0;
            b_count <= 0;

        end else if (q1_active) begin
            done <= 0;
            if (red_blob) begin
                r_sum_x <= r_sum_x + x_in;
                r_sum_y <= r_sum_y + y_in;
                r_count <= r_count + 1;
            end
            if (green_blob) begin
                g_sum_x <= g_sum_x + x_in;
                g_sum_y <= g_sum_y + y_in;
                g_count <= g_count + 1;
            end
            if (blue_blob) begin
                b_sum_x <= b_sum_x + x_in;
                b_sum_y <= b_sum_y + y_in;
                b_count <= b_count + 1;
            end
        end
    end

endmodule
