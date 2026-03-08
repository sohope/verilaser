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

    //2,3,4 분할용
    input logic red_blob,
    input logic green_blob,
    input logic blue_blob,

    output logic [11:0] vga_rgb  // 최종 모니터 출력 RGB
);

    // 각 색상별 십자가 구역인지 판별 (타겟이 0,0인 경우는 무시)
    logic draw_r_cross, draw_g_cross, draw_b_cross;

    assign draw_r_cross = (r_target_x != 0 && r_target_y != 0) &&
                    ((vga_x == r_target_x && vga_y >= r_target_y - 10 && vga_y <= r_target_y + 10) ||
                     (vga_y == r_target_y && vga_x >= r_target_x - 10 && vga_x <= r_target_x + 10));

    assign draw_g_cross = (g_target_x != 0 && g_target_y != 0) &&
                    ((vga_x == g_target_x && vga_y >= g_target_y - 10 && vga_y <= g_target_y + 10) ||
                     (vga_y == g_target_y && vga_x >= g_target_x - 10 && vga_x <= g_target_x + 10));

    assign draw_b_cross = (b_target_x != 0 && b_target_y != 0) &&
                    ((vga_x == b_target_x && vga_y >= b_target_y - 10 && vga_y <= b_target_y + 10) ||
                     (vga_y == b_target_y && vga_x >= b_target_x - 10 && vga_x <= b_target_x + 10));

 // 화면 출력 결정
    always_comb begin
        if (vga_y < 240) begin
            if (vga_x < 320) begin
                if (draw_r_cross)
                    vga_rgb = 12'hF00;  // 빨간색 십자가 출력
                else if (draw_g_cross)
                    vga_rgb = 12'h0F0;  // 초록색 십자가 출력
                else if (draw_b_cross)
                    vga_rgb = 12'h00F;  // 파란색 십자가 출력
                else vga_rgb = camera_rgb;
            end else begin
                //2사분면(오른쪽위)
                vga_rgb = red_blob ? 12'hF00 : 12'h000;
            end
        end else begin
            if (vga_x < 320) begin
                //3사분면(왼쪽아래)
                vga_rgb = green_blob ? 12'h0F0 : 12'h000;
            end else begin
                //4사분면(오른쪽아래)
                vga_rgb = blue_blob ? 12'h00F : 12'h000;

            end
        end
    end

endmodule
