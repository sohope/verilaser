`timescale 1ns / 1ps

module serializer_fsm #(
    parameter [6:0] SLAVE_ADDR_1 = 7'h10,
    parameter [6:0] SLAVE_ADDR_2 = 7'h11,
    parameter [6:0] SLAVE_ADDR_3 = 7'h12
) (
    input  logic       clk,
    input  logic       reset,
    // Trigger
    input  logic       start,
    // Coordinate input
    input  logic [9:0] r_target_x,
    input  logic [9:0] r_target_y,
    input  logic [9:0] g_target_x,
    input  logic [9:0] g_target_y,
    input  logic [9:0] b_target_x,
    input  logic [9:0] b_target_y,
    input  logic       r_status,
    input  logic       g_status,
    input  logic       b_status,
    // I2C master interface
    output logic       i2c_en,
    output logic       i2c_start,
    output logic       i2c_stop,
    output logic [7:0] tx_data,
    input  logic       tx_done,
    input  logic       tx_ready
);

    // Command sequence per slave:
    //   0: START
    //   1: WRITE slave_addr
    //   2: WRITE status
    //   3: WRITE x[9:8]
    //   4: WRITE x[7:0]
    //   5: WRITE y[9:8]
    //   6: WRITE y[7:0]
    //   7: STOP

    // FSM states
    typedef enum logic [2:0] {
        S_IDLE,
        S_SEND,
        S_LATCH,
        S_WAIT_BUSY,
        S_WAIT_DONE
    } state_e;

    state_e state, state_next;
    logic [1:0] slave_cnt, slave_cnt_next;
    logic [2:0] cmd_cnt, cmd_cnt_next;

    logic [9:0] red_x, red_y, red_x_next, red_y_next;
    logic [9:0] green_x, green_y, green_x_next, green_y_next;
    logic [9:0] blue_x, blue_y, blue_x_next, blue_y_next;
    logic red_st, green_st, blue_st;
    logic red_st_next, green_st_next, blue_st_next;

    logic i2c_en_next, i2c_start_next, i2c_stop_next;
    logic [7:0] tx_data_next;

    logic cmd_is_start, cmd_is_stop;
    assign cmd_is_start = (cmd_cnt == 3'd0);
    assign cmd_is_stop  = (cmd_cnt == 3'd7);

    // Coordinate / address / status mux
    logic [7:0] curr_addr;
    logic [9:0] curr_x, curr_y;
    logic curr_st;

    // tx_data mux
    logic [7:0] cmd_data;

    // Done signal for current command
    logic cmd_done;
    assign cmd_done = (cmd_is_start || cmd_is_stop) ? tx_ready : tx_done;

    // State register (sequential)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= S_IDLE;
            slave_cnt <= 2'd0;
            cmd_cnt   <= 3'd0;
            red_x     <= 10'd0;
            red_y     <= 10'd0;
            green_x   <= 10'd0;
            green_y   <= 10'd0;
            blue_x    <= 10'd0;
            blue_y    <= 10'd0;
            red_st    <= 1'b0;
            green_st  <= 1'b0;
            blue_st   <= 1'b0;
            i2c_en    <= 1'b0;
            i2c_start <= 1'b0;
            i2c_stop  <= 1'b0;
            tx_data   <= 8'd0;
        end else begin
            state     <= state_next;
            slave_cnt <= slave_cnt_next;
            cmd_cnt   <= cmd_cnt_next;
            red_x     <= red_x_next;
            red_y     <= red_y_next;
            green_x   <= green_x_next;
            green_y   <= green_y_next;
            blue_x    <= blue_x_next;
            blue_y    <= blue_y_next;
            red_st    <= red_st_next;
            green_st  <= green_st_next;
            blue_st   <= blue_st_next;
            i2c_en    <= i2c_en_next;
            i2c_start <= i2c_start_next;
            i2c_stop  <= i2c_stop_next;
            tx_data   <= tx_data_next;
        end
    end

    // Next-state & output logic (combinational)
    always_comb begin
        // Default: hold current values
        state_next     = state;
        slave_cnt_next = slave_cnt;
        cmd_cnt_next   = cmd_cnt;
        red_x_next     = red_x;
        red_y_next     = red_y;
        green_x_next   = green_x;
        green_y_next   = green_y;
        blue_x_next    = blue_x;
        blue_y_next    = blue_y;
        red_st_next    = red_st;
        green_st_next  = green_st;
        blue_st_next   = blue_st;
        i2c_en_next    = 1'b0;
        i2c_start_next = 1'b0;
        i2c_stop_next  = 1'b0;
        tx_data_next   = tx_data;

        case (state)
            S_IDLE: begin
                if (start) begin
                    red_x_next     = r_target_x;
                    red_y_next     = r_target_y;
                    green_x_next   = g_target_x;
                    green_y_next   = g_target_y;
                    blue_x_next    = b_target_x;
                    blue_y_next    = b_target_y;
                    red_st_next    = r_status;
                    green_st_next  = g_status;
                    blue_st_next   = b_status;
                    slave_cnt_next = 2'd0;
                    cmd_cnt_next   = 3'd0;
                    state_next     = S_SEND;
                end
            end

            S_SEND: begin
                i2c_en_next    = 1'b1;
                i2c_start_next = cmd_is_start;
                i2c_stop_next  = cmd_is_stop;
                tx_data_next   = cmd_data;
                state_next     = S_LATCH;
            end

            S_LATCH: begin
                if (cmd_is_start || cmd_is_stop) state_next = S_WAIT_BUSY;
                else state_next = S_WAIT_DONE;
            end

            S_WAIT_BUSY: begin
                if (!tx_ready) state_next = S_WAIT_DONE;
            end

            S_WAIT_DONE: begin
                if (cmd_done) begin
                    if (cmd_cnt == 3'd7) begin
                        if (slave_cnt == 2'd2) begin
                            state_next = S_IDLE;
                        end else begin
                            slave_cnt_next = slave_cnt + 1;
                            cmd_cnt_next   = 3'd0;
                            state_next     = S_SEND;
                        end
                    end else begin
                        cmd_cnt_next = cmd_cnt + 1;
                        state_next   = S_SEND;
                    end
                end
            end

            default: state_next = S_IDLE;
        endcase
    end

    always_comb begin
        case (slave_cnt)
            2'd0: begin
                curr_addr = {SLAVE_ADDR_1, 1'b0};
                curr_x = red_x;
                curr_y = red_y;
                curr_st = red_st;
            end
            2'd1: begin
                curr_addr = {SLAVE_ADDR_2, 1'b0};
                curr_x = green_x;
                curr_y = green_y;
                curr_st = green_st;
            end
            2'd2: begin
                curr_addr = {SLAVE_ADDR_3, 1'b0};
                curr_x = blue_x;
                curr_y = blue_y;
                curr_st = blue_st;
            end
            default: begin
                curr_addr = 8'h00;
                curr_x = 0;
                curr_y = 0;
                curr_st = 0;
            end
        endcase
    end

    always_comb begin
        case (cmd_cnt)
            3'd1:    cmd_data = curr_addr;
            3'd2:    cmd_data = {7'b0, curr_st};
            3'd3:    cmd_data = {6'b0, curr_x[9:8]};
            3'd4:    cmd_data = curr_x[7:0];
            3'd5:    cmd_data = {6'b0, curr_y[9:8]};
            3'd6:    cmd_data = curr_y[7:0];
            default: cmd_data = 8'h00;
        endcase
    end
endmodule
