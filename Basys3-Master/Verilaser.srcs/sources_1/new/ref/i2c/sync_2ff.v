`timescale 1ns / 1ps

module sync_2ff #(
    parameter INIT = 1'b1
) (
    input  wire clk,
    input  wire reset_n,
    input  wire d,
    output wire q
);

    reg ff1, ff2;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ff1 <= INIT;
            ff2 <= INIT;
        end else begin
            ff1 <= d;
            ff2 <= ff1;
        end
    end

    assign q = ff2;

endmodule
