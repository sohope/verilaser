`timescale 1ns / 1ps

module edge_detector (
    input logic clk,
    input logic reset,
    input logic i_sig,
    output logic rising_edge,
    output logic falling_edge,
    output logic both_edge
);
    logic [1:0] edge_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_reg <= 2'b0;
        end else begin
            edge_reg[0] <= i_sig;
            edge_reg[1] <= edge_reg[0];
        end
    end

    assign rising_edge = edge_reg[0] & ~edge_reg[1];
    assign falling_edge = ~edge_reg[0] & edge_reg[1];
    assign both_edge = rising_edge | falling_edge;
endmodule
