`timescale 1ns / 1ps

module Blob_Filter (
    input logic clk,
    input logic reset,

    input logic       DE_in,
    input logic [9:0] x_in,
    input logic [9:0] y_in,
    input logic       red_detect,
    input logic       green_detect,
    input logic       blue_detect,

    output logic       DE_out,
    output logic [9:0] x_out,
    output logic [9:0] y_out,
    output logic       red_blob,
    output logic       green_blob,
    output logic       blue_blob
);
    //색깔들 한 번에 묶어서 처리
    logic [2:0] color_in;
    assign color_in = {red_detect, green_detect, blue_detect};

    logic [2:0] line_buf1[0:639];
    logic [2:0] line_buf2[0:639];

    logic [2:0] w11, w12, w13;
    logic [2:0] w21, w22, w23;
    logic [2:0] w31, w32, w33;

    // 동기화용
    logic r_DE1, r_DE2;
    logic [9:0] r_x_d1, r_x_d2, r_y_d1, r_y_d2;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            DE_out <= 0;
            r_DE1 <= 0;
            r_DE2 <= 0;
            r_x_d1 <= 0;
            r_x_d2 <= 0;
            r_y_d1 <= 0;
            r_y_d2 <= 0;
            red_blob <= 0;
            green_blob <= 0;
            blue_blob <= 0;
        end else begin

            r_DE1  <= DE_in;
            r_DE2  <= r_DE1;
            DE_out <= r_DE2;

            r_x_d1 <= x_in;
            r_x_d2 <= r_x_d1;
            x_out  <= r_x_d2;

            r_y_d1 <= y_in;
            r_y_d2 <= r_y_d1;
            y_out  <= r_y_d2;
            if (DE_in) begin

                line_buf1[x_in] <= color_in;
                line_buf2[x_in] <= line_buf1[x_in];

                w11 <= w12;
                w12 <= w13;
                w13 <= line_buf2[x_in];
                w21 <= w22;
                w22 <= w23;
                w23 <= line_buf1[x_in];
                w31 <= w32;
                w32 <= w33;
                w33 <= color_in;

                red_blob <=   (w22[2] & (w12[2] | w21[2] | w23[2] | w32[2])) | 
                          (w12[2] & w21[2] & w23[2] & w32[2]);
                green_blob <= (w22[1] & (w12[1] | w21[1] | w23[1] | w32[1])) |
                          (w12[1] & w21[1] & w23[1] & w32[1]);
                blue_blob <=  (w22[0] & (w12[0] | w21[0] | w23[0] | w32[0])) |
                          (w12[0] & w21[0] & w23[0] & w32[0]);

            end else begin
                red_blob   <= 0;
                green_blob <= 0;
                blue_blob  <= 0;
            end
        end
    end

endmodule
