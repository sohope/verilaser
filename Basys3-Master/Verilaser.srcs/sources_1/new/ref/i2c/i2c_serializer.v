`timescale 1ns / 1ps

module i2c_serializer #(
    parameter [6:0] SLAVE_ADDR_1 = 7'h10,
    parameter [6:0] SLAVE_ADDR_2 = 7'h11,
    parameter [6:0] SLAVE_ADDR_3 = 7'h12
) (
    input  wire       clk,
    input  wire       reset,
    // Centroid interface (rclk domain -> CDC internally)
    input  wire       done,
    input  wire [9:0] r_target_x,
    input  wire [9:0] r_target_y,
    input  wire [9:0] g_target_x,
    input  wire [9:0] g_target_y,
    input  wire [9:0] b_target_x,
    input  wire [9:0] b_target_y,
    // I2C master interface
    output reg        i2c_en,
    output reg        i2c_start,
    output reg        i2c_stop,
    output wire       i2c_nack,
    output reg  [7:0] tx_data,
    input  wire       tx_done,
    input  wire       tx_ready
);

    assign i2c_nack = 1'b0;

    // CDC: done pulse (rclk -> clk)
    wire done_sync;
    reg  done_d;
    wire done_rise;

    sync_2ff #(
        .INIT(1'b0)
    ) u_done_sync (
        .clk(clk),
        .reset(reset),
        .d(done),
        .q(done_sync)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) done_d <= 0;
        else done_d <= done_sync;
    end

    assign done_rise = done_sync & ~done_d;

    // Latched coordinates
    reg [9:0] r_x, r_y, g_x, g_y, b_x, b_y;

    // FSM states
    localparam S_IDLE = 3'd0;
    localparam S_SEND = 3'd1;
    localparam S_LATCH = 3'd2;
    localparam S_WAIT_BUSY = 3'd3;
    localparam S_WAIT_DONE = 3'd4;

    reg [2:0] state;
    reg [1:0] slave_cnt;  // 0, 1, 2
    reg [2:0] cmd_cnt;  // 0~6 per slave

    // Command sequence per slave:
    //   0: START
    //   1: WRITE slave_addr
    //   2: WRITE x[9:8]
    //   3: WRITE x[7:0]
    //   4: WRITE y[9:8]
    //   5: WRITE y[7:0]
    //   6: STOP

    wire cmd_is_start = (cmd_cnt == 3'd0);
    wire cmd_is_stop = (cmd_cnt == 3'd6);

    // Coordinate / address mux
    reg [7:0] cur_addr;
    reg [9:0] cur_x, cur_y;

    always @(*) begin
        case (slave_cnt)
            2'd0: begin
                cur_addr = {SLAVE_ADDR_1, 1'b0};
                cur_x = r_x;
                cur_y = r_y;
            end
            2'd1: begin
                cur_addr = {SLAVE_ADDR_2, 1'b0};
                cur_x = g_x;
                cur_y = g_y;
            end
            2'd2: begin
                cur_addr = {SLAVE_ADDR_3, 1'b0};
                cur_x = b_x;
                cur_y = b_y;
            end
            default: begin
                cur_addr = 8'h00;
                cur_x = 0;
                cur_y = 0;
            end
        endcase
    end

    // tx_data mux
    reg [7:0] cmd_data;

    always @(*) begin
        case (cmd_cnt)
            3'd1:    cmd_data = cur_addr;
            3'd2:    cmd_data = {6'b0, cur_x[9:8]};
            3'd3:    cmd_data = cur_x[7:0];
            3'd4:    cmd_data = {6'b0, cur_y[9:8]};
            3'd5:    cmd_data = cur_y[7:0];
            default: cmd_data = 8'h00;
        endcase
    end

    // Done signal for current command
    wire cmd_done = (cmd_is_start || cmd_is_stop) ? tx_ready : tx_done;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= S_IDLE;
            slave_cnt <= 0;
            cmd_cnt   <= 0;
            r_x       <= 0;
            r_y       <= 0;
            g_x       <= 0;
            g_y       <= 0;
            b_x       <= 0;
            b_y       <= 0;
            i2c_en    <= 0;
            i2c_start <= 0;
            i2c_stop  <= 0;
            tx_data   <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    i2c_en <= 0;
                    if (done_rise) begin
                        r_x       <= r_target_x;
                        r_y       <= r_target_y;
                        g_x       <= g_target_x;
                        g_y       <= g_target_y;
                        b_x       <= b_target_x;
                        b_y       <= b_target_y;
                        slave_cnt <= 0;
                        cmd_cnt   <= 0;
                        state     <= S_SEND;
                    end
                end

                S_SEND: begin
                    i2c_en    <= 1;
                    i2c_start <= cmd_is_start;
                    i2c_stop  <= cmd_is_stop;
                    tx_data   <= cmd_data;
                    state     <= S_LATCH;
                end

                S_LATCH: begin
                    i2c_en <= 0;
                    if (cmd_is_start || cmd_is_stop) state <= S_WAIT_BUSY;
                    else state <= S_WAIT_DONE;
                end

                S_WAIT_BUSY: begin
                    if (!tx_ready) state <= S_WAIT_DONE;
                end

                S_WAIT_DONE: begin
                    if (cmd_done) begin
                        if (cmd_cnt == 3'd6) begin
                            if (slave_cnt == 2'd2) state <= S_IDLE;
                            else begin
                                slave_cnt <= slave_cnt + 1;
                                cmd_cnt   <= 0;
                                state     <= S_SEND;
                            end
                        end else begin
                            cmd_cnt <= cmd_cnt + 1;
                            state   <= S_SEND;
                        end
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
