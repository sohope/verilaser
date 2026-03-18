`timescale 1ns / 1ps

// 파이프라인 동기화를 위한 지연 모듈
// Vision Pipeline(5clk) + ImgMemReader(1clk) 지연에 맞춰
// camera_rgb, 디스플레이 좌표, DE를 동기화한다.
module Pipeline_Delay #(
    parameter RGB_DELAY  = 5,  // camera_rgb 지연 클럭 수
    parameter DISP_DELAY = 6   // x/y/DE 지연 클럭 수 (ImgMemReader + Vision Pipeline)
) (
    input  logic        clk,
    // 지연 입력
    input  logic [11:0] camera_rgb,   // {R[3:0], G[3:0], B[3:0]}
    input  logic [ 9:0] x_pixel,      // VGA 원본 좌표 (지연 전)
    input  logic [ 9:0] y_pixel,
    input  logic        DE,
    // 지연 출력
    output logic [11:0] camera_rgb_d, // RGB_DELAY 클럭 지연된 RGB
    output logic [ 9:0] x_pixel_d,    // DISP_DELAY 클럭 지연된 좌표
    output logic [ 9:0] y_pixel_d,
    output logic        DE_d
);

    // RGB 시프트 레지스터
    logic [11:0] rgb_sr [0:RGB_DELAY-1];

    // 디스플레이 좌표/DE 시프트 레지스터
    logic [9:0] x_sr  [0:DISP_DELAY-1];
    logic [9:0] y_sr  [0:DISP_DELAY-1];
    logic       DE_sr [0:DISP_DELAY-1];

    always_ff @(posedge clk) begin
        rgb_sr[0] <= camera_rgb;
        x_sr[0]   <= x_pixel;
        y_sr[0]   <= y_pixel;
        DE_sr[0]  <= DE;

        for (int i = 1; i < DISP_DELAY; i++) begin
            x_sr[i]  <= x_sr[i-1];
            y_sr[i]  <= y_sr[i-1];
            DE_sr[i] <= DE_sr[i-1];
        end

        for (int i = 1; i < RGB_DELAY; i++) begin
            rgb_sr[i] <= rgb_sr[i-1];
        end
    end

    assign camera_rgb_d = rgb_sr[RGB_DELAY-1];
    assign x_pixel_d    = x_sr[DISP_DELAY-1];
    assign y_pixel_d    = y_sr[DISP_DELAY-1];
    assign DE_d         = DE_sr[DISP_DELAY-1];

endmodule
