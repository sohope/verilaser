`timescale 1ns / 1ps

// 바운딩 박스 렌더링 모듈
// 현재 VGA 픽셀 좌표가 바운딩 박스 테두리 위에 있는지 판별하여
// 해당 색상의 draw 신호를 출력한다.
module BBox_Drawer #(
    parameter LINE_WIDTH = 1  // 테두리 두께 (픽셀)
) (
    input  logic [ 9:0] vga_x,
    input  logic [ 9:0] vga_y,
    // Red bounding box
    input  logic [ 9:0] r_bbox_x1,
    input  logic [ 9:0] r_bbox_y1,
    input  logic [ 9:0] r_bbox_x2,
    input  logic [ 9:0] r_bbox_y2,
    // Green bounding box
    input  logic [ 9:0] g_bbox_x1,
    input  logic [ 9:0] g_bbox_y1,
    input  logic [ 9:0] g_bbox_x2,
    input  logic [ 9:0] g_bbox_y2,
    // Blue bounding box
    input  logic [ 9:0] b_bbox_x1,
    input  logic [ 9:0] b_bbox_y1,
    input  logic [ 9:0] b_bbox_x2,
    input  logic [ 9:0] b_bbox_y2,
    // 출력: 각 색상의 바운딩 박스 테두리 위에 있는지 여부
    output logic        draw_r_bbox,
    output logic        draw_g_bbox,
    output logic        draw_b_bbox,
    // 오버레이된 RGB 출력 (bbox가 그려질 경우 해당 색상, 아니면 원본)
    input  logic [11:0] camera_rgb,
    output logic [11:0] bbox_rgb,
    output logic        bbox_active  // bbox 중 하나라도 그려지면 1
);

    // 단일 바운딩 박스 테두리 판정 함수
    function automatic logic is_on_bbox(
        input logic [9:0] px, py,
        input logic [9:0] x1, y1, x2, y2
    );
        logic valid, on_v_edge, on_h_edge, in_y_range, in_x_range;

        valid      = (x1 != x2) && (y1 != y2);
        in_y_range = (py >= y1) && (py <= y2);
        in_x_range = (px >= x1) && (px <= x2);

        if (LINE_WIDTH == 1) begin
            on_v_edge = (px == x1 || px == x2);
            on_h_edge = (py == y1 || py == y2);
        end else begin
            on_v_edge = (px >= x1 && px < x1 + LINE_WIDTH) ||
                        (px <= x2 && px > x2 - LINE_WIDTH);
            on_h_edge = (py >= y1 && py < y1 + LINE_WIDTH) ||
                        (py <= y2 && py > y2 - LINE_WIDTH);
        end

        is_on_bbox = valid && ((on_v_edge && in_y_range) || (on_h_edge && in_x_range));
    endfunction

    assign draw_r_bbox = is_on_bbox(vga_x, vga_y, r_bbox_x1, r_bbox_y1, r_bbox_x2, r_bbox_y2);
    assign draw_g_bbox = is_on_bbox(vga_x, vga_y, g_bbox_x1, g_bbox_y1, g_bbox_x2, g_bbox_y2);
    assign draw_b_bbox = is_on_bbox(vga_x, vga_y, b_bbox_x1, b_bbox_y1, b_bbox_x2, b_bbox_y2);

    assign bbox_active = draw_r_bbox || draw_g_bbox || draw_b_bbox;

    // 우선순위: Red > Green > Blue > 원본
    always_comb begin
        if (draw_r_bbox)
            bbox_rgb = 12'hF00;
        else if (draw_g_bbox)
            bbox_rgb = 12'h0F0;
        else if (draw_b_bbox)
            bbox_rgb = 12'h00F;
        else
            bbox_rgb = camera_rgb;
    end

endmodule
