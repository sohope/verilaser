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

    input logic [9:0] r1_target_x,
    input logic [9:0] r1_target_y,
    input logic [9:0] r2_target_x,
    input logic [9:0] r2_target_y,
    input logic [9:0] g_target_x,
    input logic [9:0] g_target_y,
    input logic [9:0] b_target_x,
    input logic [9:0] b_target_y,

    input logic red_blob,
    input logic green_blob,
    input logic blue_blob,

    output logic [11:0] vga_rgb
);

    logic draw_r1_cross, draw_r2_cross;
    logic draw_g_cross, draw_b_cross;

    assign draw_r1_cross = (r1_target_x != 0 && r1_target_y != 0) &&
                    ((vga_x == r1_target_x && vga_y >= r1_target_y - 10 && vga_y <= r1_target_y + 10) ||
                     (vga_y == r1_target_y && vga_x >= r1_target_x - 10 && vga_x <= r1_target_x + 10));

    assign draw_r2_cross = (r2_target_x != 0 && r2_target_y != 0) &&
                    ((vga_x == r2_target_x && vga_y >= r2_target_y - 10 && vga_y <= r2_target_y + 10) ||
                     (vga_y == r2_target_y && vga_x >= r2_target_x - 10 && vga_x <= r2_target_x + 10));

    assign draw_g_cross = (g_target_x != 0 && g_target_y != 0) &&
                    ((vga_x == g_target_x && vga_y >= g_target_y - 10 && vga_y <= g_target_y + 10) ||
                     (vga_y == g_target_y && vga_x >= g_target_x - 10 && vga_x <= g_target_x + 10));

    assign draw_b_cross = (b_target_x != 0 && b_target_y != 0) &&
                    ((vga_x == b_target_x && vga_y >= b_target_y - 10 && vga_y <= b_target_y + 10) ||
                     (vga_y == b_target_y && vga_x >= b_target_x - 10 && vga_x <= b_target_x + 10));

    logic draw_roi_border;
    assign draw_roi_border = 
        ((vga_x == ROI_X_MIN || vga_x == ROI_X_MAX) && (vga_y >= ROI_Y_MIN && vga_y <= ROI_Y_MAX)) ||
        ((vga_y == ROI_Y_MIN || vga_y == ROI_Y_MAX) && (vga_x >= ROI_X_MIN && vga_x <= ROI_X_MAX));

    always_comb begin
        if (vga_y < 240) begin
            if (vga_x < 320) begin
                if (draw_roi_border)
                    vga_rgb = 12'h000;
                else if (draw_r1_cross || draw_r2_cross)
                    vga_rgb = 12'hF00;
                else if (draw_g_cross)
                    vga_rgb = 12'h0F0;
                else if (draw_b_cross)
                    vga_rgb = 12'h00F;
                else 
                    vga_rgb = camera_rgb;
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

endmodule