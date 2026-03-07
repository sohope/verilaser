`timescale 1ns / 1ps

module OV7670_Init_Controller (
    input  logic clk,
    input  logic reset,
    inout  wire  sda,
    output logic scl
);

    logic       sccb_en;
    logic       sccb_start;
    logic       sccb_stop;
    logic [7:0] tx_data;
    logic       tx_done;
    logic       tx_ready;

    sccb_master U_SCCB_MASTER (
        .clk       (clk),
        .reset     (reset),
        .sccb_en   (sccb_en),
        .sccb_start(sccb_start),
        .sccb_stop (sccb_stop),
        .tx_data   (tx_data),
        .tx_done   (tx_done),
        .tx_ready  (tx_ready),
        .scl       (scl),
        .sda       (sda)
    );

    sccb_sequencer U_SCCB_SEQUENCER (
        .clk       (clk),
        .reset     (reset),
        .sccb_en   (sccb_en),
        .sccb_start(sccb_start),
        .sccb_stop (sccb_stop),
        .tx_data   (tx_data),
        .tx_done   (tx_done),
        .tx_ready  (tx_ready)
    );
endmodule

module sccb_sequencer (
    input  logic       clk,
    input  logic       reset,
    output logic       sccb_en,
    output logic       sccb_start,
    output logic       sccb_stop,
    output logic [7:0] tx_data,
    input  logic       tx_done,
    input  logic       tx_ready
);

endmodule


