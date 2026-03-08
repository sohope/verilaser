module Crossline_Display (
    input logic [ 9:0] vga_x,      // VGA 현재 X 좌표
    input logic [ 9:0] vga_y,      // VGA 현재 Y 좌표
    input logic [11:0] camera_rgb, // 원본 카메라 영상 (배경용)

    // Centroid 모듈에서 나오는 3색 타겟 좌표
    input logic [9:0] r_target_x,
    input logic [9:0] r_target_y,
    input logic [9:0] g_target_x,
    input logic [9:0] g_target_y,
    input logic [9:0] b_target_x,
    input logic [9:0] b_target_y,

    output logic [11:0] vga_rgb  // 최종 모니터 출력 RGB
);

    // 각 색상별 십자가 구역인지 판별 (타겟이 0,0인 경우는 무시)
    logic draw_r, draw_g, draw_b;

    assign draw_r = (r_target_x != 0 && r_target_y != 0) &&
                    ((vga_x == r_target_x && vga_y >= r_target_y - 10 && vga_y <= r_target_y + 10) ||
                     (vga_y == r_target_y && vga_x >= r_target_x - 10 && vga_x <= r_target_x + 10));

    assign draw_g = (g_target_x != 0 && g_target_y != 0) &&
                    ((vga_x == g_target_x && vga_y >= g_target_y - 10 && vga_y <= g_target_y + 10) ||
                     (vga_y == g_target_y && vga_x >= g_target_x - 10 && vga_x <= g_target_x + 10));

    assign draw_b = (b_target_x != 0 && b_target_y != 0) &&
                    ((vga_x == b_target_x && vga_y >= b_target_y - 10 && vga_y <= b_target_y + 10) ||
                     (vga_y == b_target_y && vga_x >= b_target_x - 10 && vga_x <= b_target_x + 10));

    // 화면 출력 결정
    always_comb begin
        if (draw_r) vga_rgb = 12'hF00;  // 빨간색 십자가 출력
        else if (draw_g) vga_rgb = 12'h0F0;  // 초록색 십자가 출력
        else if (draw_b) vga_rgb = 12'h00F;  // 파란색 십자가 출력
        else
            vga_rgb = camera_rgb; // 아무 십자가도 아니면 원본 영상 출력
    end

endmodule
