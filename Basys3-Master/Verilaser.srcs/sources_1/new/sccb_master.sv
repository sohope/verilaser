`timescale 1ns / 1ps

module sccb_master (
    input  wire       clk,
    input  wire       reset_n,
    input  wire       i2c_en,
    input  wire       i2c_start,
    input  wire       i2c_stop,
    input  wire [7:0] tx_data,
    output wire       tx_done,
    output wire       tx_ready,
    output wire       scl,
    inout  wire       sda
);

    sccb_master_core U_SCCB_MASTER_CORE (
        .clk(clk),
        .reset(reset),
        .sccb_en(sccb_en),
        .sccb_start(sccb_start),
        .sccb_stop(sccb_stop),
        .tx_data(tx_data),
        .tx_done(tx_done),
        .tx_ready(tx_ready),
        .scl(scl),
        .sda(sda)
    );

endmodule

module sccb_master_core (
    input  logic       clk,
    input  logic       reset,
    input  logic       sccb_en,
    input  logic       sccb_start,
    input  logic       sccb_stop,
    input  logic [7:0] tx_data,
    output logic       tx_done,
    output logic       tx_ready,
    output logic       scl,
    output wire        sda_o,
    output wire        sda_oen,     // 1 = drive, 0 = hi-z
    input  wire        sda_i
);

    localparam IDLE = 3'h0;
    localparam START = 3'h1;
    localparam STOP = 3'h2;
    localparam WRITE = 3'h3;
    // localparam READ      = 3'h4;
    localparam ACK_WRITE = 3'h5;
    // localparam ACK_READ  = 3'h6;

    reg [2:0] state, state_next;
    reg [9:0] clk_cnt_reg, clk_cnt_next;
    reg [7:0] tx_data_reg, tx_data_next;
    // reg [7:0] rx_data_reg, rx_data_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg scl_reg, scl_next;
    reg sda_reg, sda_next;
    reg sda_oen_reg, sda_oen_next;
    reg tx_done_reg, tx_done_next;
    // reg rx_done_reg, rx_done_next;
    // reg i2c_nack_reg, i2c_nack_next;

    assign scl = scl_reg;
    assign sda_o = sda_reg;
    assign sda_oen = sda_oen_reg;
    assign tx_done = tx_done_reg;
    assign tx_ready = (state == IDLE) ? 1 : 0;
    // assign rx_data = rx_data_reg;
    // assign rx_done = rx_done_reg;

    always @(posedge clk, negedge reset) begin
        if (reset) begin
            state        <= IDLE;
            clk_cnt_reg  <= 0;
            tx_data_reg  <= 0;
            // rx_data_reg  <= 0;
            bit_cnt_reg  <= 0;
            scl_reg      <= 1;
            sda_reg      <= 1;
            sda_oen_reg  <= 0;
            tx_done_reg  <= 0;
            // rx_done_reg  <= 0;
            // i2c_nack_reg <= 0;
        end else begin
            state        <= state_next;
            clk_cnt_reg  <= clk_cnt_next;
            tx_data_reg  <= tx_data_next;
            // rx_data_reg  <= rx_data_next;
            bit_cnt_reg  <= bit_cnt_next;
            scl_reg      <= scl_next;
            sda_reg      <= sda_next;
            sda_oen_reg  <= sda_oen_next;
            tx_done_reg  <= tx_done_next;
            // rx_done_reg  <= rx_done_next;
            // i2c_nack_reg <= i2c_nack_next;
        end
    end

    always @(*) begin
        state_next    = state;
        clk_cnt_next  = clk_cnt_reg;
        tx_data_next  = tx_data_reg;
        // rx_data_next  = rx_data_reg;
        bit_cnt_next  = bit_cnt_reg;
        sda_next      = sda_reg;
        sda_oen_next  = sda_oen_reg;
        scl_next      = scl_reg;
        tx_done_next  = 0;
        // rx_done_next  = 0;
        // i2c_nack_next = i2c_nack_reg;
        case (state)
            IDLE: begin
                sda_oen_next = 0;  // SDA 해제
                if (sccb_en) begin
                    case ({
                        sccb_start, sccb_stop
                    })
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
                        // 2'b11: begin
                        // state_next    = READ;
                        // sccb_nack_next = sccb_nack;
                        // end
                        default: begin

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
            // READ: begin
            //     sda_oen_next = 0;  // SDA 해제 (슬레이브가 드라이브)
            //     scl_next     = 0;
            //     clk_cnt_next = clk_cnt_reg + 1;
            //     if (clk_cnt_reg > 249) begin
            //         scl_next = 1;
            //         if (clk_cnt_reg == 499) begin
            //             rx_data_next = {rx_data_reg[6:0], sda};
            //         end
            //         if (clk_cnt_reg > 749) begin
            //             scl_next = 0;
            //             if (clk_cnt_reg == 999) begin
            //                 bit_cnt_next = bit_cnt_reg + 1;
            //                 clk_cnt_next = 0;
            //                 if (bit_cnt_reg == 7) begin
            //                     state_next   = ACK_READ;
            //                     bit_cnt_next = 0;
            //                 end
            //             end
            //         end
            //     end
            // end
            ACK_WRITE: begin
                sda_oen_next = 0;  // SDA 해제 (슬레이브 ACK 수신)
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
            // ACK_READ: begin
            //     sda_next     = i2c_nack_reg;
            //     sda_oen_next = 1;
            //     scl_next     = 0;
            //     clk_cnt_next = clk_cnt_reg + 1;
            //     if (clk_cnt_reg > 249) begin
            //         scl_next = 1;
            //         if (clk_cnt_reg > 749) begin
            //             scl_next = 0;
            //             if (clk_cnt_reg == 999) begin
            //                 clk_cnt_next = 0;
            //                 state_next   = IDLE;
            //                 rx_done_next = 1'b1;
            //             end
            //         end
            //     end
            // end
        endcase
    end

endmodule
