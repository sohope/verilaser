`timescale 1ns / 1ps

module sync_2ff #(
    parameter INIT = 1'b0
) (
    input  wire clk,
    input  wire reset,
    input  wire d,
    output wire q
);

    reg ff1, ff2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ff1 <= INIT;
            ff2 <= INIT;
        end else begin
            ff1 <= d;
            ff2 <= ff1;
        end
    end

    assign q = ff2;

endmodule
