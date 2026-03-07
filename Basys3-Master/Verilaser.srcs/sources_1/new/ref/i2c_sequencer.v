`timescale 1ns / 1ps

module i2c_sequencer (
    input  wire       clk,
    input  wire       reset_n,
    // Master interface
    output reg        i2c_en,
    output reg        i2c_start,
    output reg        i2c_stop,
    output reg        i2c_nack,
    output reg  [7:0] tx_data,
    input  wire       tx_done,
    input  wire       tx_ready,
    input  wire [7:0] rx_data,
    input  wire       rx_done
);

    // 커맨드 타입
    localparam CT_START     = 3'd0;
    localparam CT_WRITE     = 3'd1;
    localparam CT_READ_ACK  = 3'd2;
    localparam CT_READ_NACK = 3'd3;
    localparam CT_STOP      = 3'd4;

    // FSM 상태
    localparam S_DELAY     = 3'd0;
    localparam S_SEND      = 3'd1;
    localparam S_LATCH     = 3'd2;
    localparam S_WAIT_BUSY = 3'd3;
    localparam S_WAIT_DONE = 3'd4;
    localparam S_DONE      = 3'd5;

    localparam NUM_CMDS = 31;

    reg [2:0]  seq_state;
    reg [4:0]  cmd_idx;
    reg [19:0] delay_cnt;

    // 커맨드 디코더
    reg [2:0] cmd_type;
    reg [7:0] cmd_data;

    always @(*) begin
        cmd_type = CT_START;
        cmd_data = 8'h00;
        case (cmd_idx)
            // TEST 1: WRITE reg[1]=12, reg[2]=34, reg[3]=56, reg[0]=78
            5'd0:  cmd_type = CT_START;
            5'd1:  begin cmd_type = CT_WRITE; cmd_data = 8'hA0; end
            5'd2:  begin cmd_type = CT_WRITE; cmd_data = 8'h01; end
            5'd3:  begin cmd_type = CT_WRITE; cmd_data = 8'h12; end
            5'd4:  begin cmd_type = CT_WRITE; cmd_data = 8'h34; end
            5'd5:  begin cmd_type = CT_WRITE; cmd_data = 8'h56; end
            5'd6:  begin cmd_type = CT_WRITE; cmd_data = 8'h78; end
            5'd7:  cmd_type = CT_STOP;
            // TEST 2: WRITE reg[2]=0A, reg[3]=50
            5'd8:  cmd_type = CT_START;
            5'd9:  begin cmd_type = CT_WRITE; cmd_data = 8'hA0; end
            5'd10: begin cmd_type = CT_WRITE; cmd_data = 8'h02; end
            5'd11: begin cmd_type = CT_WRITE; cmd_data = 8'h0A; end
            5'd12: begin cmd_type = CT_WRITE; cmd_data = 8'h50; end
            5'd13: cmd_type = CT_STOP;
            // TEST 3: READ 1B from reg[1] → expect 0x12
            5'd14: cmd_type = CT_START;
            5'd15: begin cmd_type = CT_WRITE; cmd_data = 8'hA0; end
            5'd16: begin cmd_type = CT_WRITE; cmd_data = 8'h01; end
            5'd17: cmd_type = CT_START;  // Repeated START
            5'd18: begin cmd_type = CT_WRITE; cmd_data = 8'hA1; end
            5'd19: cmd_type = CT_READ_NACK;
            5'd20: cmd_type = CT_STOP;
            // TEST 4: READ 4B from reg[1] → expect 12, 0A, 50, 78
            5'd21: cmd_type = CT_START;
            5'd22: begin cmd_type = CT_WRITE; cmd_data = 8'hA0; end
            5'd23: begin cmd_type = CT_WRITE; cmd_data = 8'h01; end
            5'd24: cmd_type = CT_START;  // Repeated START
            5'd25: begin cmd_type = CT_WRITE; cmd_data = 8'hA1; end
            5'd26: cmd_type = CT_READ_ACK;
            5'd27: cmd_type = CT_READ_ACK;
            5'd28: cmd_type = CT_READ_ACK;
            5'd29: cmd_type = CT_READ_NACK;
            5'd30: cmd_type = CT_STOP;
            default: cmd_type = CT_START;
        endcase
    end

    // 완료 신호 선택
    wire cmd_done = (cmd_type == CT_START || cmd_type == CT_STOP) ? tx_ready :
                    (cmd_type == CT_WRITE) ? tx_done : rx_done;

    // 시퀀서 FSM
    always @(posedge clk, negedge reset_n) begin
        if (!reset_n) begin
            seq_state <= S_DELAY;
            cmd_idx   <= 0;
            delay_cnt <= 0;
            i2c_en    <= 0;
            i2c_start <= 0;
            i2c_stop  <= 0;
            i2c_nack  <= 0;
            tx_data   <= 0;
        end else begin
            case (seq_state)
                S_DELAY: begin
                    delay_cnt <= delay_cnt + 1;
                    if (&delay_cnt) seq_state <= S_SEND;
                end

                S_SEND: begin
                    i2c_en <= 1;
                    case (cmd_type)
                        CT_START:     begin i2c_start <= 1; i2c_stop <= 0; end
                        CT_WRITE:     begin i2c_start <= 0; i2c_stop <= 0; tx_data <= cmd_data; end
                        CT_READ_ACK:  begin i2c_start <= 1; i2c_stop <= 1; i2c_nack <= 0; end
                        CT_READ_NACK: begin i2c_start <= 1; i2c_stop <= 1; i2c_nack <= 1; end
                        CT_STOP:      begin i2c_start <= 0; i2c_stop <= 1; end
                    endcase
                    seq_state <= S_LATCH;
                end

                S_LATCH: begin
                    i2c_en <= 0;
                    if (cmd_type == CT_START || cmd_type == CT_STOP)
                        seq_state <= S_WAIT_BUSY;
                    else
                        seq_state <= S_WAIT_DONE;
                end

                S_WAIT_BUSY: begin
                    if (!tx_ready) seq_state <= S_WAIT_DONE;
                end

                S_WAIT_DONE: begin
                    if (cmd_done) begin
                        if (cmd_idx == NUM_CMDS - 1)
                            seq_state <= S_DONE;
                        else begin
                            cmd_idx   <= cmd_idx + 1;
                            seq_state <= S_SEND;
                        end
                    end
                end

                S_DONE: begin
                    cmd_idx   <= 0;
                    delay_cnt <= 0;
                    seq_state <= S_DELAY;
                end
            endcase
        end
    end
endmodule
