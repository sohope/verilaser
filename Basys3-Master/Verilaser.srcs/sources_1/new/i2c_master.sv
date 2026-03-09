`timescale 1ns / 1ps

module i2c_master (
    input  logic       clk,
    input  logic       reset,
    input  logic       i2c_en,
    input  logic       i2c_start,
    input  logic       i2c_stop,
    input  logic       i2c_nack,
    input  logic [7:0] tx_data,
    output logic       tx_done,
    output logic       tx_ready,
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       scl,
    inout  wire        sda
);

    // 2-stage synchronizer for CDC (cross-board)
    logic sda_sync;

    sync_2ff #(.INIT(1'b1)) u_sda_sync (
        .clk(clk), .reset(reset), .d(sda), .q(sda_sync)
    );

    logic sda_reg, sda_next;
    logic sda_oen_reg, sda_oen_next;

    assign sda = sda_oen_reg ? sda_reg : 1'bz;

    typedef enum logic [2:0] {
        IDLE,
        START,
        STOP,
        WRITE,
        READ,
        ACK_WRITE,
        ACK_READ
    } state_e;

    state_e state, state_next;
    logic [9:0] clk_cnt_reg, clk_cnt_next;
    logic [7:0] tx_data_reg, tx_data_next;
    logic [7:0] rx_data_reg, rx_data_next;
    logic [2:0] bit_cnt_reg, bit_cnt_next;
    logic scl_reg, scl_next;
    logic tx_done_reg, tx_done_next;
    logic rx_done_reg, rx_done_next;
    logic i2c_nack_reg, i2c_nack_next;

    assign scl = scl_reg;
    assign tx_done = tx_done_reg;
    assign tx_ready = (state == IDLE) ? 1 : 0;
    assign rx_data = rx_data_reg;
    assign rx_done = rx_done_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            clk_cnt_reg  <= 0;
            tx_data_reg  <= 0;
            rx_data_reg  <= 0;
            bit_cnt_reg  <= 0;
            scl_reg      <= 1;
            sda_reg      <= 1;
            sda_oen_reg  <= 0;
            tx_done_reg  <= 0;
            rx_done_reg  <= 0;
            i2c_nack_reg <= 0;
        end else begin
            state        <= state_next;
            clk_cnt_reg  <= clk_cnt_next;
            tx_data_reg  <= tx_data_next;
            rx_data_reg  <= rx_data_next;
            bit_cnt_reg  <= bit_cnt_next;
            scl_reg      <= scl_next;
            sda_reg      <= sda_next;
            sda_oen_reg  <= sda_oen_next;
            tx_done_reg  <= tx_done_next;
            rx_done_reg  <= rx_done_next;
            i2c_nack_reg <= i2c_nack_next;
        end
    end

    always_comb begin
        state_next    = state;
        clk_cnt_next  = clk_cnt_reg;
        tx_data_next  = tx_data_reg;
        rx_data_next  = rx_data_reg;
        bit_cnt_next  = bit_cnt_reg;
        sda_next      = sda_reg;
        sda_oen_next  = sda_oen_reg;
        scl_next      = scl_reg;
        tx_done_next  = 0;
        rx_done_next  = 0;
        i2c_nack_next = i2c_nack_reg;
        case (state)
            IDLE: begin
                sda_oen_next = 0;
                if (i2c_en) begin
                    case ({i2c_start, i2c_stop})
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
                        2'b11: begin
                            state_next    = READ;
                            i2c_nack_next = i2c_nack;
                        end
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
            READ: begin
                sda_oen_next = 0;
                scl_next     = 0;
                clk_cnt_next = clk_cnt_reg + 1;
                if (clk_cnt_reg > 249) begin
                    scl_next = 1;
                    if (clk_cnt_reg == 499) begin
                        rx_data_next = {rx_data_reg[6:0], sda_sync};
                    end
                    if (clk_cnt_reg > 749) begin
                        scl_next = 0;
                        if (clk_cnt_reg == 999) begin
                            bit_cnt_next = bit_cnt_reg + 1;
                            clk_cnt_next = 0;
                            if (bit_cnt_reg == 7) begin
                                state_next   = ACK_READ;
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
            ACK_READ: begin
                sda_next     = i2c_nack_reg;
                sda_oen_next = 1;
                scl_next     = 0;
                clk_cnt_next = clk_cnt_reg + 1;
                if (clk_cnt_reg > 249) begin
                    scl_next = 1;
                    if (clk_cnt_reg > 749) begin
                        scl_next = 0;
                        if (clk_cnt_reg == 999) begin
                            clk_cnt_next = 0;
                            state_next   = IDLE;
                            rx_done_next = 1'b1;
                        end
                    end
                end
            end
            default: begin
                state_next = IDLE;
            end
        endcase
    end

endmodule
