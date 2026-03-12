`timescale 1ns / 1ps

// Vision 처리 파이프라인 탑 모듈
// HSV_Converter → Color_Detect → Blob_Filter → Multi_Centroid x3
module Vision_Pipeline #(
    parameter ROI_X_MIN = 10'd10,
    parameter ROI_X_MAX = 10'd310,
    parameter ROI_Y_MIN = 10'd10,
    parameter ROI_Y_MAX = 10'd230
) (
    input  logic       clk,
    input  logic       reset,
    // 픽셀 입력
    input  logic       DE_in,
    input  logic [9:0] x_in,
    input  logic [9:0] y_in,
    input  logic [3:0] R_in,
    input  logic [3:0] G_in,
    input  logic [3:0] B_in,
    // Blob 출력 (VGA 디스플레이용)
    output logic       DE_out,
    output logic [9:0] x_out,
    output logic [9:0] y_out,
    output logic       red_blob,
    output logic       green_blob,
    output logic       blue_blob,
    // Red target 좌표
    output logic [9:0] r1_target_x,
    output logic [9:0] r1_target_y,
    output logic [9:0] r2_target_x,
    output logic [9:0] r2_target_y,
    output logic [9:0] r3_target_x,
    output logic [9:0] r3_target_y,
    output logic       r1_status,
    output logic       done_r,
    // Green target 좌표
    output logic [9:0] g1_target_x,
    output logic [9:0] g1_target_y,
    output logic [9:0] g2_target_x,
    output logic [9:0] g2_target_y,
    output logic [9:0] g3_target_x,
    output logic [9:0] g3_target_y,
    output logic       g1_status,
    output logic       done_g,
    // Blue target 좌표
    output logic [9:0] b1_target_x,
    output logic [9:0] b1_target_y,
    output logic [9:0] b2_target_x,
    output logic [9:0] b2_target_y,
    output logic [9:0] b3_target_x,
    output logic [9:0] b3_target_y,
    output logic       b1_status,
    output logic       done_b
);

    // HSV 출력
    logic       w_DE_HSV;
    logic [9:0] w_x_HSV, w_y_HSV;
    logic [7:0] w_H, w_S, w_V;

    HSV_Converter u_HSV_Converter (
        .clk   (clk),
        .reset (reset),
        .DE_in (DE_in),
        .x_in  (x_in),
        .y_in  (y_in),
        .R_in  (R_in),
        .G_in  (G_in),
        .B_in  (B_in),
        .DE_out(w_DE_HSV),
        .x_out (w_x_HSV),
        .y_out (w_y_HSV),
        .H_out (w_H),
        .S_out (w_S),
        .V_out (w_V)
    );

    // Color Detect 출력
    logic       w_DE_CD;
    logic [9:0] w_x_CD, w_y_CD;
    logic       w_red_detect, w_green_detect, w_blue_detect;

    Color_Detect #(
        .ROI_X_MIN(ROI_X_MIN),
        .ROI_X_MAX(ROI_X_MAX),
        .ROI_Y_MIN(ROI_Y_MIN),
        .ROI_Y_MAX(ROI_Y_MAX)
    ) u_Color_Detect (
        .clk         (clk),
        .reset       (reset),
        .DE_in       (w_DE_HSV),
        .x_in        (w_x_HSV),
        .y_in        (w_y_HSV),
        .H_in        (w_H),
        .S_in        (w_S),
        .V_in        (w_V),
        .DE_out      (w_DE_CD),
        .x_out       (w_x_CD),
        .y_out       (w_y_CD),
        .red_detect  (w_red_detect),
        .green_detect(w_green_detect),
        .blue_detect (w_blue_detect)
    );

    // Blob Filter
    Blob_Filter u_Blob_Filter (
        .clk         (clk),
        .reset       (reset),
        .DE_in       (w_DE_CD),
        .x_in        (w_x_CD),
        .y_in        (w_y_CD),
        .red_detect  (w_red_detect),
        .green_detect(w_green_detect),
        .blue_detect (w_blue_detect),
        .DE_out      (DE_out),
        .x_out       (x_out),
        .y_out       (y_out),
        .red_blob    (red_blob),
        .green_blob  (green_blob),
        .blue_blob   (blue_blob)
    );

    // Multi_Centroid x3
    Multi_Centroid u_Centroid_R (
        .clk        (clk),
        .reset      (reset),
        .DE_in      (DE_out),
        .x_in       (x_out),
        .y_in       (y_out),
        .blob_in    (red_blob),
        .t1_target_x(r1_target_x),
        .t1_target_y(r1_target_y),
        .t1_status  (r1_status),
        .t2_target_x(r2_target_x),
        .t2_target_y(r2_target_y),
        .t2_status  (),
        .t3_target_x(r3_target_x),
        .t3_target_y(r3_target_y),
        .t3_status  (),
        .done       (done_r)
    );

    Multi_Centroid u_Centroid_G (
        .clk        (clk),
        .reset      (reset),
        .DE_in      (DE_out),
        .x_in       (x_out),
        .y_in       (y_out),
        .blob_in    (green_blob),
        .t1_target_x(g1_target_x),
        .t1_target_y(g1_target_y),
        .t1_status  (g1_status),
        .t2_target_x(g2_target_x),
        .t2_target_y(g2_target_y),
        .t2_status  (),
        .t3_target_x(g3_target_x),
        .t3_target_y(g3_target_y),
        .t3_status  (),
        .done       (done_g)
    );

    Multi_Centroid u_Centroid_B (
        .clk        (clk),
        .reset      (reset),
        .DE_in      (DE_out),
        .x_in       (x_out),
        .y_in       (y_out),
        .blob_in    (blue_blob),
        .t1_target_x(b1_target_x),
        .t1_target_y(b1_target_y),
        .t1_status  (b1_status),
        .t2_target_x(b2_target_x),
        .t2_target_y(b2_target_y),
        .t2_status  (),
        .t3_target_x(b3_target_x),
        .t3_target_y(b3_target_y),
        .t3_status  (),
        .done       (done_b)
    );

endmodule
