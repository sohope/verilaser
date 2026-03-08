`timescale 1ns / 1ps

module Color_Detect (

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

    parameter S_MIN = 8'd100;
    parameter V_MIN = 8'd50;

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
            if (DE_in && (S_in >= S_MIN) && V_in > V_MIN) begin
                // Red : 0~10 or 170~179
                red_detect   <= ((H_in <= 8'd15) || (H_in >= 8'd165)) ? 1'b1 : 1'b0;
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
