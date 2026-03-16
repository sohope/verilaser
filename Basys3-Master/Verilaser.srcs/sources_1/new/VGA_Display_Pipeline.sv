`timescale 1ns / 1ps

// VGA 디스플레이 파이프라인 탑 모듈
module VGA_Display_Pipeline #(
    parameter ROI_X_MIN = 10'd120,
    parameter ROI_X_MAX = 10'd160,
    parameter ROI_Y_MIN = 10'd120,
    parameter ROI_Y_MAX = 10'd160
) (
    input  logic        sw,
    input  logic        sw1,  // Crossline 표시 (0: 끔, 1: 켬)
    input  logic        DE,
    input  logic [ 9:0] vga_x,
    input  logic [ 9:0] vga_y,
    input  logic [11:0] camera_rgb,
    // target 좌표
    input  logic [ 9:0] r1_target_x,
    input  logic [ 9:0] r1_target_y,
    input  logic [ 9:0] r2_target_x,
    input  logic [ 9:0] r2_target_y,
    input  logic [ 9:0] r3_target_x,
    input  logic [ 9:0] r3_target_y,
    input  logic [ 9:0] g1_target_x,
    input  logic [ 9:0] g1_target_y,
    input  logic [ 9:0] g2_target_x,
    input  logic [ 9:0] g2_target_y,
    input  logic [ 9:0] g3_target_x,
    input  logic [ 9:0] g3_target_y,
    input  logic [ 9:0] b1_target_x,
    input  logic [ 9:0] b1_target_y,
    input  logic [ 9:0] b2_target_x,
    input  logic [ 9:0] b2_target_y,
    input  logic [ 9:0] b3_target_x,
    input  logic [ 9:0] b3_target_y,
    // Bounding Box
    input  logic [ 9:0] r_bbox_x1, r_bbox_y1, r_bbox_x2, r_bbox_y2,
    input  logic [ 9:0] g_bbox_x1, g_bbox_y1, g_bbox_x2, g_bbox_y2,
    input  logic [ 9:0] b_bbox_x1, b_bbox_y1, b_bbox_x2, b_bbox_y2,
    // blob
    input  logic        red_blob,
    input  logic        green_blob,
    input  logic        blue_blob,
    // VGA 출력
    output logic [ 3:0] port_red,
    output logic [ 3:0] port_green,
    output logic [ 3:0] port_blue
);

    logic [11:0] w_debug_rgb;
    logic [11:0] w_vga_rgb;

    Crossline_Display #(
        .ROI_X_MIN(ROI_X_MIN),
        .ROI_X_MAX(ROI_X_MAX),
        .ROI_Y_MIN(ROI_Y_MIN),
        .ROI_Y_MAX(ROI_Y_MAX)
    ) u_Crossline_Display (
        .sw(sw),
        .sw1(sw1),
        .vga_x(vga_x),
        .vga_y(vga_y),
        .camera_rgb(camera_rgb),
        .r1_target_x(r1_target_x),
        .r1_target_y(r1_target_y),
        .r2_target_x(r2_target_x),
        .r2_target_y(r2_target_y),
        .r3_target_x(r3_target_x),
        .r3_target_y(r3_target_y),
        .g1_target_x(g1_target_x),
        .g1_target_y(g1_target_y),
        .g2_target_x(g2_target_x),
        .g2_target_y(g2_target_y),
        .g3_target_x(g3_target_x),
        .g3_target_y(g3_target_y),
        .b1_target_x(b1_target_x),
        .b1_target_y(b1_target_y),
        .b2_target_x(b2_target_x),
        .b2_target_y(b2_target_y),
        .b3_target_x(b3_target_x),
        .b3_target_y(b3_target_y),
        .r_bbox_x1(r_bbox_x1), .r_bbox_y1(r_bbox_y1), .r_bbox_x2(r_bbox_x2), .r_bbox_y2(r_bbox_y2),
        .g_bbox_x1(g_bbox_x1), .g_bbox_y1(g_bbox_y1), .g_bbox_x2(g_bbox_x2), .g_bbox_y2(g_bbox_y2),
        .b_bbox_x1(b_bbox_x1), .b_bbox_y1(b_bbox_y1), .b_bbox_x2(b_bbox_x2), .b_bbox_y2(b_bbox_y2),
        .red_blob(red_blob),
        .green_blob(green_blob),
        .blue_blob(blue_blob),
        .vga_rgb(w_debug_rgb),
        .o_vga_x(),
        .o_vga_y()
    );

    // Crossline_Display가 sw에 따라 직접 모드 처리하므로 Mux 불필요
    assign w_vga_rgb = w_debug_rgb;

    VGA_Output u_VGA_Output (
        .DE(DE),
        .vga_rgb(w_vga_rgb),
        .port_red(port_red),
        .port_green(port_green),
        .port_blue(port_blue)
    );

endmodule

module Crossline_Display #(
    parameter ROI_X_MIN = 10'd120,
    parameter ROI_X_MAX = 10'd160,
    parameter ROI_Y_MIN = 10'd120,
    parameter ROI_Y_MAX = 10'd160
) (
    input logic        sw,   // 0: 업스케일(원본), 1: 타일링(디버깅)
    input logic        sw1,  // Crossline 표시 (0: 켬, 1: 끔)
    input logic [ 9:0] vga_x,
    input logic [ 9:0] vga_y,
    input logic [11:0] camera_rgb,

    // red target 1~3
    input logic [9:0] r1_target_x,
    input logic [9:0] r1_target_y,
    input logic [9:0] r2_target_x,
    input logic [9:0] r2_target_y,
    input logic [9:0] r3_target_x,
    input logic [9:0] r3_target_y,
    // green target 1~3
    input logic [9:0] g1_target_x,
    input logic [9:0] g1_target_y,
    input logic [9:0] g2_target_x,
    input logic [9:0] g2_target_y,
    input logic [9:0] g3_target_x,
    input logic [9:0] g3_target_y,
    // blue target 1~3
    input logic [9:0] b1_target_x,
    input logic [9:0] b1_target_y,
    input logic [9:0] b2_target_x,
    input logic [9:0] b2_target_y,
    input logic [9:0] b3_target_x,
    input logic [9:0] b3_target_y,

    // Bounding Box
    input logic [9:0] r_bbox_x1, r_bbox_y1, r_bbox_x2, r_bbox_y2,
    input logic [9:0] g_bbox_x1, g_bbox_y1, g_bbox_x2, g_bbox_y2,
    input logic [9:0] b_bbox_x1, b_bbox_y1, b_bbox_x2, b_bbox_y2,

    input logic red_blob,
    input logic green_blob,
    input logic blue_blob,

    output logic [11:0] vga_rgb,
    output logic [ 9:0] o_vga_x,
    output logic [ 9:0] o_vga_y

);

    // 십자선 매크로 (좌표는 상위에서 sw에 따라 미리 스케일링됨)
    `define IS_CROSS(X, Y) ((X != 0 && Y != 0) && ((vga_x == X && vga_y >= Y - 10 && vga_y <= Y + 10) || (vga_y == Y && vga_x >= X - 10 && vga_x <= X + 10)))
    // 바운딩 박스 매크로
    `define IS_BBOX(X1, Y1, X2, Y2) ((X1 != X2 && Y1 != Y2) && (((vga_x == X1 || vga_x == X2) && (vga_y >= Y1 && vga_y <= Y2)) || ((vga_y == Y1 || vga_y == Y2) && (vga_x >= X1 && vga_x <= X2))))

    logic draw_r_cross, draw_g_cross, draw_b_cross;
    logic draw_r_bbox,  draw_g_bbox,  draw_b_bbox;

    assign draw_r_cross =
        `IS_CROSS(r1_target_x, r1_target_y) ||
        `IS_CROSS(r2_target_x, r2_target_y) ||
        `IS_CROSS(r3_target_x, r3_target_y);
    assign draw_g_cross =
        `IS_CROSS(g1_target_x, g1_target_y) ||
        `IS_CROSS(g2_target_x, g2_target_y) ||
        `IS_CROSS(g3_target_x, g3_target_y);
    assign draw_b_cross =
        `IS_CROSS(b1_target_x, b1_target_y) ||
        `IS_CROSS(b2_target_x, b2_target_y) ||
        `IS_CROSS(b3_target_x, b3_target_y);

    assign draw_r_bbox = `IS_BBOX(r_bbox_x1, r_bbox_y1, r_bbox_x2, r_bbox_y2);
    assign draw_g_bbox = `IS_BBOX(g_bbox_x1, g_bbox_y1, g_bbox_x2, g_bbox_y2);
    assign draw_b_bbox = `IS_BBOX(b_bbox_x1, b_bbox_y1, b_bbox_x2, b_bbox_y2);

    always_comb begin
        if (sw) begin
            // 타일링/디버깅 모드: 4분할 + Q1에 십자선/바운딩박스
            if (vga_y < 240) begin
                if (vga_x < 320) begin
                    if      (~sw1 && draw_r_cross) vga_rgb = 12'hF00;
                    else if (~sw1 && draw_g_cross) vga_rgb = 12'h0F0;
                    else if (~sw1 && draw_b_cross) vga_rgb = 12'h00F;
                    else if (~sw1 && draw_r_bbox)  vga_rgb = 12'hF00;
                    else if (~sw1 && draw_g_bbox)  vga_rgb = 12'h0F0;
                    else if (~sw1 && draw_b_bbox)  vga_rgb = 12'h00F;
                    else vga_rgb = camera_rgb;
                end else begin
                    vga_rgb = red_blob ? 12'hF00 : 12'h000;
                end
            end else begin
                if (vga_x < 320)
                    vga_rgb = green_blob ? 12'h0F0 : 12'h000;
                else
                    vga_rgb = blue_blob ? 12'h00F : 12'h000;
            end
        end else begin
            // 업스케일 모드: 전체 화면 + 스케일 십자선/바운딩박스
            if      (~sw1 && draw_r_cross) vga_rgb = 12'hF00;
            else if (~sw1 && draw_g_cross) vga_rgb = 12'h0F0;
            else if (~sw1 && draw_b_cross) vga_rgb = 12'h00F;
            else if (~sw1 && draw_r_bbox)  vga_rgb = 12'hF00;
            else if (~sw1 && draw_g_bbox)  vga_rgb = 12'h0F0;
            else if (~sw1 && draw_b_bbox)  vga_rgb = 12'h00F;
            else vga_rgb = camera_rgb;
        end
    end

    assign o_vga_x = vga_x;
    assign o_vga_y = vga_y;

    `undef IS_CROSS
    `undef IS_BBOX
endmodule

// 4분할 디버깅 화면 구성
module Debug_View (
    input logic [9:0] vga_x,
    input logic [9:0] vga_y,
    input logic [11:0] rgb_with_cross,
    input logic red_blob,
    input logic green_blob,
    input logic blue_blob,
    output logic [11:0] debug_rgb
);
    always_comb begin
        if (vga_y < 240) begin
            if (vga_x < 320) debug_rgb = rgb_with_cross;
            else debug_rgb = red_blob ? 12'hF00 : 12'h000;
        end else begin
            if (vga_x < 320) debug_rgb = green_blob ? 12'h0F0 : 12'h000;
            else debug_rgb = blue_blob ? 12'h00F : 12'h000;
        end
    end
endmodule

// sw에 따라 원본/디버깅 선택
module Display_Mux (
    input  logic        sw,
    input  logic [11:0] camera_rgb,
    input  logic [11:0] debug_rgb,
    output logic [11:0] vga_rgb
);
    assign vga_rgb = sw ? debug_rgb : camera_rgb;
endmodule

// DE 신호로 VGA 출력 게이팅
module VGA_Output (
    input  logic        DE,
    input  logic [11:0] vga_rgb,
    output logic [ 3:0] port_red,
    output logic [ 3:0] port_green,
    output logic [ 3:0] port_blue
);
    assign port_red   = DE ? vga_rgb[11:8] : 4'd0;
    assign port_green = DE ? vga_rgb[7:4] : 4'd0;
    assign port_blue  = DE ? vga_rgb[3:0] : 4'd0;
endmodule
