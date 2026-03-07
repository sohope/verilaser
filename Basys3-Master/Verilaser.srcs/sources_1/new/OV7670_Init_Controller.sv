`timescale 1ns / 1ps

module OV7670_Init_Controller #(
    parameter N_REGS = 20
) (
    input  logic clk,
    input  logic reset,
    inout  wire  sda,
    output logic scl
);

    logic        sccb_en;
    logic        sccb_start;
    logic        sccb_stop;
    logic [ 7:0] tx_data;
    logic        tx_done;
    logic        tx_ready;

    logic [ 7:0] rom_addr;
    logic [15:0] rom_data;

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

    sccb_sequencer #(
        .N_REGS(N_REGS)
    ) U_SCCB_SEQUENCER (
        .clk       (clk),
        .reset     (reset),
        .sccb_en   (sccb_en),
        .sccb_start(sccb_start),
        .sccb_stop (sccb_stop),
        .tx_data   (tx_data),
        .tx_done   (tx_done),
        .tx_ready  (tx_ready),
        .rom_addr  (rom_addr),
        .rom_data  (rom_data)
    );

    OV7670_reg_rom #(
        .N_REGS(N_REGS)
    ) U_OV7670_REG_ROM (
        .rom_addr(rom_addr),
        .rom_data(rom_data)
    );

endmodule

module sccb_sequencer #(
    parameter N_REGS = 20
) (
    input  logic        clk,
    input  logic        reset,
    output logic        sccb_en,
    output logic        sccb_start,
    output logic        sccb_stop,
    output logic [ 7:0] tx_data,
    input  logic        tx_done,
    input  logic        tx_ready,
    output logic [ 7:0] rom_addr,
    input  logic [15:0] rom_data
);
    localparam START_SEND = 4'd0;
    localparam START_WAIT = 4'd1;
    localparam WRITE_ID_SEND = 4'd2;
    localparam WRITE_ID_WAIT = 4'd3;
    localparam WRITE_ADDR_SEND = 4'd4;
    localparam WRITE_ADDR_WAIT = 4'd5;
    localparam WRITE_DATA_SEND = 4'd6;
    localparam WRITE_DATA_WAIT = 4'd7;
    localparam STOP_SEND = 4'd8;
    localparam STOP_WAIT = 4'd9;
    localparam DONE = 4'd10;

    logic [3:0] state, state_next;
    logic [7:0] regIdx, regIdx_next;

    assign rom_addr = regIdx;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state  <= START_SEND;
            regIdx <= 0;
        end else begin
            state  <= state_next;
            regIdx <= regIdx_next;
        end
    end

    always_comb begin
        state_next = state;
        regIdx_next = regIdx;
        sccb_en = 1'b0;
        sccb_start = 1'b0;
        sccb_stop = 1'b0;
        tx_data = 8'h0;
        case (state)
            START_SEND: begin
                sccb_en = 1'b1;
                sccb_start = 1'b1;
                sccb_stop = 1'b0;
                state_next = START_WAIT;
            end
            START_WAIT: begin
                sccb_en = 1'b0;
                sccb_start = 1'b0;
                sccb_stop = 1'b0;
                if (tx_ready) begin
                    state_next = WRITE_ID_SEND;
                end
            end
            WRITE_ID_SEND: begin
                sccb_en = 1'b1;
                sccb_start = 1'b0;
                sccb_stop = 1'b0;
                tx_data = 8'h42;
                state_next = WRITE_ID_WAIT;
            end
            WRITE_ID_WAIT: begin
                sccb_en = 1'b0;
                sccb_start = 1'b0;
                sccb_stop = 1'b0;
                if (tx_done) begin
                    state_next = WRITE_ADDR_SEND;
                end
            end
            WRITE_ADDR_SEND: begin
                sccb_en = 1'b1;
                sccb_start = 1'b0;
                sccb_stop = 1'b0;
                tx_data = rom_data[15:8];  // reg addr
                state_next = WRITE_ADDR_WAIT;
            end
            WRITE_ADDR_WAIT: begin
                sccb_en = 1'b0;
                sccb_start = 1'b0;
                sccb_stop = 1'b0;
                if (tx_done) begin
                    state_next = WRITE_DATA_SEND;
                end
            end
            WRITE_DATA_SEND: begin
                sccb_en = 1'b1;
                sccb_start = 1'b0;
                sccb_stop = 1'b0;
                tx_data = rom_data[7:0];  // reg data
                state_next = WRITE_DATA_WAIT;
            end
            WRITE_DATA_WAIT: begin
                sccb_en = 1'b0;
                sccb_start = 1'b0;
                sccb_stop = 1'b0;
                if (tx_done) begin
                    state_next = STOP_SEND;
                end
            end
            STOP_SEND: begin
                sccb_en = 1'b1;
                sccb_start = 1'b0;
                sccb_stop = 1'b1;
                state_next = STOP_WAIT;
            end
            STOP_WAIT: begin
                sccb_en = 1'b0;
                sccb_start = 1'b0;
                sccb_stop = 1'b0;
                if (tx_ready) begin
                    if(regIdx == N_REGS -1) begin
                        state_next = DONE;
                    end else begin
                        regIdx_next = regIdx + 1;
                        state_next = START_SEND;
                    end
                end
            end
            DONE: begin
                sccb_en = 1'b0;
                sccb_start = 1'b0;
                sccb_stop = 1'b0;
            end
        endcase
    end
endmodule

module OV7670_reg_rom #(
    parameter N_REGS = 20
) (
    input  logic [ 7:0] rom_addr,
    output logic [15:0] rom_data
);

    logic [15:0] mem[0:N_REGS -1];

    initial begin
        $readmemh("OV7670_init_regs.mem", mem);
    end

    assign rom_data = mem[rom_addr];
endmodule
