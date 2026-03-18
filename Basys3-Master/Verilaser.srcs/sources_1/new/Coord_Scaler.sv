`timescale 1ns / 1ps

// QVGA → VGA 좌표 스케일러
// sw=0 (업스케일 모드): QVGA 좌표를 ×2 하여 VGA 해상도에 매핑
// sw=1 (타일링 모드):   QVGA 좌표를 그대로 통과
module Coord_Scaler (
    input  logic        sw,
    // Target 좌표 입력 (QVGA)
    input  logic [ 9:0] r_target_x,  r_target_y,
    input  logic [ 9:0] g_target_x,  g_target_y,
    input  logic [ 9:0] b_target_x,  b_target_y,
    // Bounding Box 입력 (QVGA)
    input  logic [ 9:0] r_bbox_x1,   r_bbox_y1,   r_bbox_x2,   r_bbox_y2,
    input  logic [ 9:0] g_bbox_x1,   g_bbox_y1,   g_bbox_x2,   g_bbox_y2,
    input  logic [ 9:0] b_bbox_x1,   b_bbox_y1,   b_bbox_x2,   b_bbox_y2,
    // Target 좌표 출력 (스케일 적용)
    output logic [ 9:0] disp_r_x,    disp_r_y,
    output logic [ 9:0] disp_g_x,    disp_g_y,
    output logic [ 9:0] disp_b_x,    disp_b_y,
    // Bounding Box 출력 (스케일 적용)
    output logic [ 9:0] disp_r_bx1,  disp_r_by1,  disp_r_bx2,  disp_r_by2,
    output logic [ 9:0] disp_g_bx1,  disp_g_by1,  disp_g_bx2,  disp_g_by2,
    output logic [ 9:0] disp_b_bx1,  disp_b_by1,  disp_b_bx2,  disp_b_by2
);

    // sw=0: shift left 1 (×2),  sw=1: pass through
    function automatic logic [9:0] scale(input logic sw_in, input logic [9:0] coord);
        scale = sw_in ? coord : {coord[8:0], 1'b0};
    endfunction

    // Target 좌표
    assign disp_r_x = scale(sw, r_target_x);
    assign disp_r_y = scale(sw, r_target_y);
    assign disp_g_x = scale(sw, g_target_x);
    assign disp_g_y = scale(sw, g_target_y);
    assign disp_b_x = scale(sw, b_target_x);
    assign disp_b_y = scale(sw, b_target_y);

    // Bounding Box 좌표
    assign disp_r_bx1 = scale(sw, r_bbox_x1);
    assign disp_r_by1 = scale(sw, r_bbox_y1);
    assign disp_r_bx2 = scale(sw, r_bbox_x2);
    assign disp_r_by2 = scale(sw, r_bbox_y2);

    assign disp_g_bx1 = scale(sw, g_bbox_x1);
    assign disp_g_by1 = scale(sw, g_bbox_y1);
    assign disp_g_bx2 = scale(sw, g_bbox_x2);
    assign disp_g_by2 = scale(sw, g_bbox_y2);

    assign disp_b_bx1 = scale(sw, b_bbox_x1);
    assign disp_b_by1 = scale(sw, b_bbox_y1);
    assign disp_b_bx2 = scale(sw, b_bbox_x2);
    assign disp_b_by2 = scale(sw, b_bbox_y2);

endmodule
