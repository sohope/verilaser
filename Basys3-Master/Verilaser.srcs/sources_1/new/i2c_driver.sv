`timescale 1ns / 1ps

module i2c_driver (
    input  logic       clk,
    input  logic       reset,
    // Command input (valid/ready handshake)
    input  logic       cmd_valid,
    input  logic       cmd_is_start,
    input  logic       cmd_is_stop,
    input  logic [7:0] cmd_data,
    output logic       cmd_ready,
    // I2C master interface
    output logic       i2c_en,
    output logic       i2c_start,
    output logic       i2c_stop,
    output logic [7:0] tx_data,
    input  logic       tx_done,
    input  logic       tx_ready
);

    typedef enum logic [2:0] {
        S_IDLE,
        S_SEND,
        S_LATCH,
        S_WAIT_BUSY,
        S_WAIT_DONE
    } state_e;

    state_e state, state_next;

    logic i2c_en_next, i2c_start_next, i2c_stop_next;
    logic [7:0] tx_data_next;
    logic cmd_ready_next;

    // Latch command type for LATCH/WAIT states
    logic is_start_r, is_stop_r;
    logic is_start_r_next, is_stop_r_next;

    // Done signal for current command
    logic cmd_done;
    assign cmd_done = (is_start_r || is_stop_r) ? tx_ready : tx_done;

    // Next-state & output logic
    always_comb begin
        state_next     = state;
        i2c_en_next    = 1'b0;
        i2c_start_next = 1'b0;
        i2c_stop_next  = 1'b0;
        tx_data_next   = tx_data;
        cmd_ready_next = 1'b0;
        is_start_r_next = is_start_r;
        is_stop_r_next  = is_stop_r;

        case (state)
            S_IDLE: begin
                if (cmd_valid) begin
                    i2c_en_next     = 1'b1;
                    i2c_start_next  = cmd_is_start;
                    i2c_stop_next   = cmd_is_stop;
                    tx_data_next    = cmd_data;
                    is_start_r_next = cmd_is_start;
                    is_stop_r_next  = cmd_is_stop;
                    state_next      = S_LATCH;
                end
            end

            // 마스터가 데이터를 가져간 직후 상태
            // i2c_en 펄스를 1클럭만 주고 내리면 tx_data, i2c_start, i2c_stop을 랫칭함
            S_LATCH: begin
                if (is_start_r || is_stop_r) state_next = S_WAIT_BUSY;
                else state_next = S_WAIT_DONE;
            end

            // 마스터가 실제로 일을 시작했는지를 확인하는 상태
            S_WAIT_BUSY: begin
                if (!tx_ready) state_next = S_WAIT_DONE;
            end

            // 마스터가 일을 끝냈는지를 확인하는 상태
            S_WAIT_DONE: begin
                if (cmd_done) begin
                    cmd_ready_next = 1'b1;
                    state_next     = S_IDLE;
                end
            end

            default: state_next = S_IDLE;
        endcase
    end

    // State register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= S_IDLE;
            i2c_en    <= 1'b0;
            i2c_start <= 1'b0;
            i2c_stop  <= 1'b0;
            tx_data   <= 8'd0;
            cmd_ready <= 1'b0;
            is_start_r <= 1'b0;
            is_stop_r  <= 1'b0;
        end else begin
            state     <= state_next;
            i2c_en    <= i2c_en_next;
            i2c_start <= i2c_start_next;
            i2c_stop  <= i2c_stop_next;
            tx_data   <= tx_data_next;
            cmd_ready <= cmd_ready_next;
            is_start_r <= is_start_r_next;
            is_stop_r  <= is_stop_r_next;
        end
    end

endmodule
