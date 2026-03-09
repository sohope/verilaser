`timescale 1ns / 1ps

module Color_Detect #(
    parameter ROI_X_MIN = 10'd120,
    parameter ROI_X_MAX = 10'd160,
    parameter ROI_Y_MIN = 10'd120,
    parameter ROI_Y_MAX = 10'd160
) (

    input logic clk,
    input logic reset,

    input logic       DE_in,
    input logic [9:0] x_in,
    input logic [9:0] y_in,
    input logic [7:0] H_in,   // 0~179
    input logic [7:0] S_in,   // 0~255
    input logic [7:0] V_in,   // 0~255

    output logic       DE_out,
    output logic [9:0] x_out,
    output logic [9:0] y_out,
    output logic       red_detect,
    output logic       green_detect,
    output logic       blue_detect
);

    parameter S_MIN = 8'd150;
    parameter V_MIN = 8'd60;

    logic in_roi_sig;

    ROI_Filter #(
        .X_MIN(ROI_X_MIN),
        .X_MAX(ROI_X_MAX),
        .Y_MIN(ROI_Y_MIN),
        .Y_MAX(ROI_Y_MAX)
    ) u_roi_filter (
        .x_in  (x_in),
        .y_in  (y_in),
        .in_roi(in_roi_sig)
    );


    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            DE_out       <= 0;
            x_out        <= 0;
            y_out        <= 0;
            red_detect   <= 0;
            green_detect <= 0;
            blue_detect  <= 0;
        end else begin
            //1clk 지연 동기화
            DE_out <= DE_in;
            x_out  <= x_in;
            y_out  <= y_in;

            if (DE_in && in_roi_sig && (S_in >= S_MIN) && V_in > V_MIN) begin
                // Red : 0~10 or 170~179
                red_detect   <= ((H_in <= 8'd6) || (H_in >= 8'd173)) ? 1'b1 : 1'b0;
                green_detect <= ((H_in <= 8'd75) && (H_in >= 8'd45)) ? 1'b1 : 1'b0;
                blue_detect  <= ((H_in <= 8'd135) && (H_in >= 8'd105)) ? 1'b1 : 1'b0;
            end else begin
                red_detect   <= 1'b0;
                green_detect <= 1'b0;
                blue_detect  <= 1'b0;
            end
        end
    end

endmodule

module ROI_Filter #(
    parameter X_MIN = 10'd120,
    parameter X_MAX = 10'd160,
    parameter Y_MIN = 10'd120,
    parameter Y_MAX = 10'd160
) (
    input  logic [9:0] x_in,
    input  logic [9:0] y_in,
    output logic       in_roi
);

    assign in_roi = (x_in >= X_MIN) && (x_in <= X_MAX) && 
                    (y_in >= Y_MIN) && (y_in <= Y_MAX);

endmodule
