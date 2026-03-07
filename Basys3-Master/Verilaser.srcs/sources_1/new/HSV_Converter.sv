`timescale 1ns / 1ps

module HSV_Converter (
    input logic clk,
    input logic reset,

    input logic DE_in,
    input logic [9:0] x_in,
    input logic [9:0] y_in,
    input logic [3:0] R_in,
    input logic [3:0] G_in,
    input logic [3:0] B_in,

    output logic       DE_out,
    output logic [9:0] x_out,
    output logic [9:0] y_out,
    output logic [7:0] H_out,   // 0~179
    output logic [7:0] S_out,   // 0~255
    output logic [7:0] V_out    // 0~255
);
//수정필요

    // upscaling 
    logic [7:0] R8, G8, B8;
    assign R8 = {R_in, R_in};
    assign G8 = {G_in, G_in};
    assign B8 = {B_in, B_in};

    logic [7:0] max_val, min_val, delta;

    always_comb begin
        max_val = R8;
        if (G8 > max_val) max_val = G8;
        if (B8 > max_val) max_val = B8;

        min_val = R8;
        if (G8 < min_val) min_val = G8;
        if (B8 < min_val) min_val = B8;

        delta = max_val - min_val;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            DE_out <= 0;
            x_out  <= 0;
            y_out  <= 0;
            H_out  <= 0;
            S_out  <= 0;
            V_out  <= 0;
        end else begin
            DE_out <= DE_in;
            x_out  <= x_in;
            y_out  <= y_in;
            
            V_out  <= max_val;
            
            if (max_val == 0) begin
                S_out <= 0;
            end else begin
                S_out <= (delta * 8'd255) / max_val;
            end

            if (delta == 0) begin
                H_out <= 0;
            end else if (max_val == R8) begin
                if (G8 >= B8) begin
                    H_out <= ((G8 - B8) * 8'd30) / delta;
                end else begin
                    H_out <= 8'd180 - (((B8 - G8) * 8'd30) / delta);
                end
            end else if (max_val == G8) begin
                if (B8 >= R8) begin
                    H_out <= 8'd60 + (((B8 - R8) * 8'd30) / delta);
                end else begin
                    H_out <= 8'd60 - (((R8 - B8) * 8'd30) / delta);
                end
            end else begin
                if (R8 >= G8) begin
                    H_out <= 8'd120 + (((R8 - G8) * 8'd30) / delta);
                end else begin
                    H_out <= 8'd120 - (((G8 - R8) * 8'd30) / delta);
                end
            end
        end
    end

endmodule
