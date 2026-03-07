`timescale 1ns / 1ps

module sccb_master (
    input  wire       clk,
    input  wire       reset,
    input  wire       sccb_en,
    input  wire       sccb_start,
    input  wire       sccb_stop,
    input  wire [7:0] tx_data,
    output wire       tx_done,
    output wire       tx_ready,
    output wire       scl,
    inout  wire       sda
);

    localparam IDLE      = 3'h0;
    localparam START     = 3'h1;
    localparam STOP      = 3'h2;
    localparam WRITE     = 3'h3;
    localparam ACK_WRITE = 3'h4;

    reg [2:0] state, state_next;
    reg [9:0] clk_cnt_reg, clk_cnt_next;
    reg [7:0] tx_data_reg, tx_data_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg scl_reg, scl_next;
    reg sda_reg, sda_next;
    reg sda_oen_reg, sda_oen_next;
    reg tx_done_reg, tx_done_next;

    assign scl = scl_reg;
    assign sda = sda_oen_reg ? sda_reg : 1'bz;
    assign tx_done = tx_done_reg;
    assign tx_ready = (state == IDLE) ? 1 : 0;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            clk_cnt_reg  <= 0;
            tx_data_reg  <= 0;
            bit_cnt_reg  <= 0;
            scl_reg      <= 1;
            sda_reg      <= 1;
            sda_oen_reg  <= 0;
            tx_done_reg  <= 0;
        end else begin
            state        <= state_next;
            clk_cnt_reg  <= clk_cnt_next;
            tx_data_reg  <= tx_data_next;
            bit_cnt_reg  <= bit_cnt_next;
            scl_reg      <= scl_next;
            sda_reg      <= sda_next;
            sda_oen_reg  <= sda_oen_next;
            tx_done_reg  <= tx_done_next;
        end
    end

    always @(*) begin
        state_next    = state;
        clk_cnt_next  = clk_cnt_reg;
        tx_data_next  = tx_data_reg;
        bit_cnt_next  = bit_cnt_reg;
        sda_next      = sda_reg;
        sda_oen_next  = sda_oen_reg;
        scl_next      = scl_reg;
        tx_done_next  = 0;
        case (state)
            IDLE: begin
                sda_oen_next = 0;
                if (sccb_en) begin
                    case ({sccb_start, sccb_stop})
                        2'b00: begin
                            state_next   = WRITE;
                            tx_data_next = tx_data;
                        end
                        2'b01: begin
                            state_next = STOP;
                        end
                        2'b10: begin
                            state_next = START;
                        end
                        default: ;
                    endcase
                end
            end
            START: begin
                tx_data_next = tx_data;
                sda_next     = 1;
                sda_oen_next = 1;
                scl_next     = 1;
                clk_cnt_next = clk_cnt_reg + 1;
                if (clk_cnt_reg > 249) begin
                    sda_next = 0;
                    scl_next = 1;
                    if (clk_cnt_reg > 499) begin
                        sda_next = 0;
                        scl_next = 0;
                        if (clk_cnt_reg == 999) begin
                            state_next   = IDLE;
                            clk_cnt_next = 0;
                        end
                    end
                end
            end
            STOP: begin
                sda_next     = 0;
                sda_oen_next = 1;
                scl_next     = 0;
                clk_cnt_next = clk_cnt_reg + 1;
                if (clk_cnt_reg > 249) begin
                    sda_next = 0;
                    scl_next = 1;
                    if (clk_cnt_reg > 499) begin
                        sda_next = 1;
                        scl_next = 1;
                        if (clk_cnt_reg == 999) begin
                            state_next   = IDLE;
                            clk_cnt_next = 0;
                        end
                    end
                end
            end
            WRITE: begin
                sda_next     = tx_data_reg[7];
                sda_oen_next = 1;
                scl_next     = 0;
                clk_cnt_next = clk_cnt_reg + 1;
                if (clk_cnt_reg > 249) begin
                    scl_next = 1;
                    if (clk_cnt_reg > 749) begin
                        scl_next = 0;
                        if (clk_cnt_reg == 999) begin
                            bit_cnt_next = bit_cnt_reg + 1;
                            tx_data_next = {tx_data_reg[6:0], 1'b0};
                            clk_cnt_next = 0;
                            if (bit_cnt_reg == 7) begin
                                state_next   = ACK_WRITE;
                                bit_cnt_next = 0;
                            end
                        end
                    end
                end
            end
            ACK_WRITE: begin
                sda_oen_next = 0;
                scl_next     = 0;
                clk_cnt_next = clk_cnt_reg + 1;
                if (clk_cnt_reg > 249) begin
                    scl_next = 1;
                    if (clk_cnt_reg > 749) begin
                        scl_next = 0;
                        if (clk_cnt_reg == 999) begin
                            clk_cnt_next = 0;
                            state_next   = IDLE;
                            tx_done_next = 1'b1;
                        end
                    end
                end
            end
        endcase
    end

endmodule
