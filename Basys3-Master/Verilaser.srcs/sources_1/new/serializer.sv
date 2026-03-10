`timescale 1ns / 1ps

module serializer #(
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
    // Command output (valid/ready handshake)
    output logic       cmd_valid,
    output logic       cmd_is_start,
    output logic       cmd_is_stop,
    output logic [7:0] cmd_data,
    input  logic       cmd_ready
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

    typedef enum logic [1:0] {
        S_IDLE,
        S_ACTIVE,
        S_WAIT_READY
    } state_e;

    state_e state, state_next;
    logic [1:0] slave_cnt, slave_cnt_next;
    logic [2:0] cmd_cnt, cmd_cnt_next;

    logic [9:0] red_x, red_y, red_x_next, red_y_next;
    logic [9:0] green_x, green_y, green_x_next, green_y_next;
    logic [9:0] blue_x, blue_y, blue_x_next, blue_y_next;
    logic red_st, green_st, blue_st;
    logic red_st_next, green_st_next, blue_st_next;

    // Coordinate / address / status mux
    logic [7:0] curr_addr;
    logic [9:0] curr_x, curr_y;
    logic       curr_st;

    // Command data mux
    logic [7:0] data_mux;

    // State register
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
        end
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
                curr_x = 10'd0;
                curr_y = 10'd0;
                curr_st = 1'b0;
            end
        endcase
    end

    always_comb begin
        case (cmd_cnt)
            3'd1:    data_mux = curr_addr;
            3'd2:    data_mux = {7'b0, curr_st};
            3'd3:    data_mux = {6'b0, curr_x[9:8]};
            3'd4:    data_mux = curr_x[7:0];
            3'd5:    data_mux = {6'b0, curr_y[9:8]};
            3'd6:    data_mux = curr_y[7:0];
            default: data_mux = 8'h00;
        endcase
    end

    // Output assignments (combinational from registered state)
    assign cmd_is_start = (cmd_cnt == 3'd0);
    assign cmd_is_stop  = (cmd_cnt == 3'd7);
    assign cmd_data     = data_mux;
    assign cmd_valid    = (state == S_ACTIVE);

    // Next-state logic
    always_comb begin
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
                    state_next     = S_ACTIVE;
                end
            end

            S_ACTIVE: begin
                state_next = S_WAIT_READY;
            end

            S_WAIT_READY: begin
                if (cmd_ready) begin
                    if (cmd_cnt == 3'd7) begin
                        if (slave_cnt == 2'd2) begin
                            state_next = S_IDLE;
                        end else begin
                            slave_cnt_next = slave_cnt + 1;
                            cmd_cnt_next   = 3'd0;
                            state_next     = S_ACTIVE;
                        end
                    end else begin
                        cmd_cnt_next = cmd_cnt + 1;
                        state_next   = S_ACTIVE;
                    end
                end
            end

            default: state_next = S_IDLE;
        endcase
    end
endmodule
