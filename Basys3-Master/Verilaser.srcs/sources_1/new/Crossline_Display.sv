`timescale 1ns / 1ps

module Crossline_Display #(
    parameter ROI_X_MIN = 10'd120,
    parameter ROI_X_MAX = 10'd160,
    parameter ROI_Y_MIN = 10'd120,
    parameter ROI_Y_MAX = 10'd160
)(
    input logic [ 9:0] vga_x,
    input logic [ 9:0] vga_y,
    input logic [11:0] camera_rgb,

    // red target 1~3
    input logic [9:0] r1_target_x, input logic [9:0] r1_target_y,
    input logic [9:0] r2_target_x, input logic [9:0] r2_target_y,
    input logic [9:0] r3_target_x, input logic [9:0] r3_target_y,
    // green target 1~3
    input logic [9:0] g1_target_x, input logic [9:0] g1_target_y,
    input logic [9:0] g2_target_x, input logic [9:0] g2_target_y,
    input logic [9:0] g3_target_x, input logic [9:0] g3_target_y,
    // blue target 1~3
    input logic [9:0] b1_target_x, input logic [9:0] b1_target_y,
    input logic [9:0] b2_target_x, input logic [9:0] b2_target_y,
    input logic [9:0] b3_target_x, input logic [9:0] b3_target_y,

    input logic red_blob,
    input logic green_blob,
    input logic blue_blob,

    output logic [11:0] vga_rgb,
    output logic [ 9:0] o_vga_x,
    output logic [ 9:0] o_vga_y

);
        

    // cross line Macro 
    `define IS_CROSS(X, Y) ((X != 0 && Y != 0) && ((vga_x == X && vga_y >= Y - 10 && vga_y <= Y + 10) || (vga_y == Y && vga_x >= X - 10 && vga_x <= X + 10)))

    logic draw_r_cross, draw_g_cross, draw_b_cross;
    
    // 같은 색깔의 십자가 중 하나라도 걸리면 1
    assign draw_r_cross = `IS_CROSS(r1_target_x, r1_target_y) || `IS_CROSS(r2_target_x, r2_target_y) || `IS_CROSS(r3_target_x, r3_target_y);
    assign draw_g_cross = `IS_CROSS(g1_target_x, g1_target_y) || `IS_CROSS(g2_target_x, g2_target_y) || `IS_CROSS(g3_target_x, g3_target_y);
    assign draw_b_cross = `IS_CROSS(b1_target_x, b1_target_y) || `IS_CROSS(b2_target_x, b2_target_y) || `IS_CROSS(b3_target_x, b3_target_y);

    // logic draw_roi_border;
    // assign draw_roi_border = 
        // ((vga_x == ROI_X_MIN || vga_x == ROI_X_MAX) && (vga_y >= ROI_Y_MIN && vga_y <= ROI_Y_MAX)) ||
        // ((vga_y == ROI_Y_MIN || vga_y == ROI_Y_MAX) && (vga_x >= ROI_X_MIN && vga_x <= ROI_X_MAX));

    always_comb begin
        if (vga_y < 240) begin
            if (vga_x < 320) begin
                // if (draw_roi_border) vga_rgb = 12'h000;
                // else 
                if (draw_r_cross) vga_rgb = 12'hF00;
                else if (draw_g_cross) vga_rgb = 12'h0F0;
                else if (draw_b_cross) vga_rgb = 12'h00F;
                else vga_rgb = camera_rgb;
            end else begin
                vga_rgb = red_blob ? 12'hF00 : 12'h000;
            end
        end else begin
            if (vga_x < 320) begin
                vga_rgb = green_blob ? 12'h0F0 : 12'h000;
            end else begin
                vga_rgb = blue_blob ? 12'h00F : 12'h000;
            end
        end
    end

    `undef IS_CROSS
endmodule