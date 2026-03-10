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
    output logic       done,

    output logic r_status,
    output logic g_status,
    output logic b_status

);

    localparam IMG_WIDTH = 320;
    localparam IMG_HEIGHT = 240;
    localparam TARGET_PERCENT = 1;
    localparam THRESHOLD = (IMG_WIDTH * IMG_HEIGHT * TARGET_PERCENT) / 100;

    logic [31:0] r_sum_x, r_sum_y;
    logic [31:0] g_sum_x, g_sum_y;
    logic [31:0] b_sum_x, b_sum_y;
    logic [19:0] r_count;
    logic [19:0] g_count;
    logic [19:0] b_count;

    logic frame_done;
    assign frame_done = (x_in == (IMG_WIDTH -1) && y_in == (IMG_HEIGHT - 1) && DE_in);

    logic q1_active;
    assign q1_active = DE_in && (x_in < IMG_WIDTH) && (y_in < IMG_HEIGHT);

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
            if (r_count > THRESHOLD) begin
                r_target_x <= r_sum_x / r_count;
                r_target_y <= r_sum_y / r_count;
                r_status   <= 1'b1;
            end else begin
                r_target_x <= 0;
                r_target_y <= 0;
                r_status   <= 1'b0;
            end
            if (g_count > THRESHOLD) begin
                g_target_x <= g_sum_x / g_count;
                g_target_y <= g_sum_y / g_count;
                g_status   <= 1'b1;
            end else begin
                g_target_x <= 0;
                g_target_y <= 0;
                g_status   <= 1'b0;
            end

            if (b_count > THRESHOLD) begin
                b_target_x <= b_sum_x / b_count;
                b_target_y <= b_sum_y / b_count;
                b_status   <= 1'b1;
            end else begin
                b_target_x <= 0;
                b_target_y <= 0;
                b_status   <= 1'b0;
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


module Multi_Centroid (
    input logic clk,
    input logic reset,

    input logic       DE_in,
    input logic [9:0] x_in,
    input logic [9:0] y_in,
    input logic       blob_in, // general color

    output logic [9:0] t1_target_x, output logic [9:0] t1_target_y, output logic t1_status,
    output logic [9:0] t2_target_x, output logic [9:0] t2_target_y, output logic t2_status,
    output logic [9:0] t3_target_x, output logic [9:0] t3_target_y, output logic t3_status,
    output logic       done
);

    localparam IMG_WIDTH = 320;
    localparam IMG_HEIGHT = 240;
    localparam TARGET_PERCENT = 1;
    localparam THRESHOLD = (IMG_WIDTH * IMG_HEIGHT * TARGET_PERCENT) / 100;

    logic [31:0] t1_sum_x, t1_sum_y; logic [19:0] t1_count;
    logic [31:0] t2_sum_x, t2_sum_y; logic [19:0] t2_count;
    logic [31:0] t3_sum_x, t3_sum_y; logic [19:0] t3_count;

    logic [9:0] t1_prev_x, t1_prev_y;
    logic [9:0] t2_prev_x, t2_prev_y;
    logic [9:0] t3_prev_x, t3_prev_y;

    logic frame_done;
    assign frame_done = (x_in == (IMG_WIDTH - 1) && y_in == (IMG_HEIGHT - 1) && DE_in);
    
    logic q1_active;
    assign q1_active = DE_in && (x_in < IMG_WIDTH) && (y_in < IMG_HEIGHT);

    logic [10:0] dist1_x, dist1_y, dist2_x, dist2_y, dist3_x, dist3_y;
    logic [10:0] dist1, dist2, dist3;

    assign dist1_x = (x_in > t1_prev_x) ? (x_in - t1_prev_x) : (t1_prev_x - x_in);
    assign dist1_y = (y_in > t1_prev_y) ? (y_in - t1_prev_y) : (t1_prev_y - y_in);
    assign dist1   = dist1_x + dist1_y;

    assign dist2_x = (x_in > t2_prev_x) ? (x_in - t2_prev_x) : (t2_prev_x - x_in);
    assign dist2_y = (y_in > t2_prev_y) ? (y_in - t2_prev_y) : (t2_prev_y - y_in);
    assign dist2   = dist2_x + dist2_y;

    assign dist3_x = (x_in > t3_prev_x) ? (x_in - t3_prev_x) : (t3_prev_x - x_in);
    assign dist3_y = (y_in > t3_prev_y) ? (y_in - t3_prev_y) : (t3_prev_y - y_in);
    assign dist3   = dist3_x + dist3_y;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            t1_sum_x <= 0; t1_sum_y <= 0; t1_count <= 0;
            t2_sum_x <= 0; t2_sum_y <= 0; t2_count <= 0;
            t3_sum_x <= 0; t3_sum_y <= 0; t3_count <= 0;
            
            t1_prev_x <= 10'd50;  t1_prev_y <= 10'd120;
            t2_prev_x <= 10'd160; t2_prev_y <= 10'd120;
            t3_prev_x <= 10'd270; t3_prev_y <= 10'd120;
            
            t1_target_x <= 0; t1_target_y <= 0; t1_status <= 0;
            t2_target_x <= 0; t2_target_y <= 0; t2_status <= 0;
            t3_target_x <= 0; t3_target_y <= 0; t3_status <= 0;
            done <= 0;
            
        end else if (frame_done) begin
            if (t1_count > THRESHOLD) begin
                t1_target_x <= t1_sum_x / t1_count; t1_target_y <= t1_sum_y / t1_count;
                t1_prev_x   <= t1_sum_x / t1_count; t1_prev_y   <= t1_sum_y / t1_count;
                t1_status   <= 1'b1;
            end else begin
                t1_target_x <= 0; t1_target_y <= 0; t1_status <= 1'b0;
                t1_prev_x   <= 10'd50; t1_prev_y <= 10'd120; 
            end

            if (t2_count > THRESHOLD) begin
                t2_target_x <= t2_sum_x / t2_count; t2_target_y <= t2_sum_y / t2_count;
                t2_prev_x   <= t2_sum_x / t2_count; t2_prev_y   <= t2_sum_y / t2_count;
                t2_status   <= 1'b1;
            end else begin
                t2_target_x <= 0; t2_target_y <= 0; t2_status <= 1'b0;
                t2_prev_x   <= 10'd160; t2_prev_y <= 10'd120; 
            end

            if (t3_count > THRESHOLD) begin
                t3_target_x <= t3_sum_x / t3_count; t3_target_y <= t3_sum_y / t3_count;
                t3_prev_x   <= t3_sum_x / t3_count; t3_prev_y   <= t3_sum_y / t3_count;
                t3_status   <= 1'b1;
            end else begin
                t3_target_x <= 0; t3_target_y <= 0; t3_status <= 1'b0;
                t3_prev_x   <= 10'd270; t3_prev_y <= 10'd120; 
            end

            done <= 1;
            t1_sum_x <= 0; t1_sum_y <= 0; t1_count <= 0;
            t2_sum_x <= 0; t2_sum_y <= 0; t2_count <= 0;
            t3_sum_x <= 0; t3_sum_y <= 0; t3_count <= 0;

        end else if (q1_active) begin
            done <= 0;
            if (blob_in) begin //  detect specific color
                if ((dist1 <= dist2) && (dist1 <= dist3)) begin
                    t1_sum_x <= t1_sum_x + x_in; t1_sum_y <= t1_sum_y + y_in; t1_count <= t1_count + 1;
                end else if ((dist2 <= dist1) && (dist2 <= dist3)) begin
                    t2_sum_x <= t2_sum_x + x_in; t2_sum_y <= t2_sum_y + y_in; t2_count <= t2_count + 1;
                end else begin
                    t3_sum_x <= t3_sum_x + x_in; t3_sum_y <= t3_sum_y + y_in; t3_count <= t3_count + 1;
                end
            end
        end
    end
endmodule