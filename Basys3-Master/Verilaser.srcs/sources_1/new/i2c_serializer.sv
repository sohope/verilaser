`timescale 1ns / 1ps

module i2c_serializer #(
    parameter [6:0] SLAVE_ADDR_1 = 7'h10,
    parameter [6:0] SLAVE_ADDR_2 = 7'h11,
    parameter [6:0] SLAVE_ADDR_3 = 7'h12
) (
    input  logic       clk,
    input  logic       reset,
    // Centroid interface
    input  logic       done,
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
    output logic       i2c_nack,
    output logic [7:0] tx_data,
    input  logic       tx_done,
    input  logic       tx_ready
);

    assign i2c_nack = 1'b0;

    // CDC: done pulse (rclk -> clk)
    logic done_sync;
    logic done_rise;

    sync_2ff #(
        .INIT(1'b0)
    ) u_done_sync (
        .clk(clk),
        .reset(reset),
        .d(done),
        .q(done_sync)
    );

    edge_detector u_done_edge (
        .clk(clk),
        .reset(reset),
        .i_sig(done_sync),
        .rising_edge(done_rise),
        .falling_edge(),
        .both_edge()
    );

    // Internal handshake
    logic cmd_valid, cmd_ready;
    logic cmd_is_start, cmd_is_stop;
    logic [7:0] cmd_data;

    // Command generator: decides what to send
    cmd_generator #(
        .SLAVE_ADDR_1(SLAVE_ADDR_1),
        .SLAVE_ADDR_2(SLAVE_ADDR_2),
        .SLAVE_ADDR_3(SLAVE_ADDR_3)
    ) u_cmd_gen (
        .clk        (clk),
        .reset      (reset),
        .start      (done_rise),
        .r_target_x (r_target_x),
        .r_target_y (r_target_y),
        .g_target_x (g_target_x),
        .g_target_y (g_target_y),
        .b_target_x (b_target_x),
        .b_target_y (b_target_y),
        .r_status   (r_status),
        .g_status   (g_status),
        .b_status   (b_status),
        .cmd_valid   (cmd_valid),
        .cmd_is_start(cmd_is_start),
        .cmd_is_stop (cmd_is_stop),
        .cmd_data    (cmd_data),
        .cmd_ready   (cmd_ready)
    );

    // Serializer FSM: handles I2C handshake
    serializer_fsm u_fsm (
        .clk         (clk),
        .reset       (reset),
        .cmd_valid   (cmd_valid),
        .cmd_is_start(cmd_is_start),
        .cmd_is_stop (cmd_is_stop),
        .cmd_data    (cmd_data),
        .cmd_ready   (cmd_ready),
        .i2c_en      (i2c_en),
        .i2c_start   (i2c_start),
        .i2c_stop    (i2c_stop),
        .tx_data     (tx_data),
        .tx_done     (tx_done),
        .tx_ready    (tx_ready)
    );

endmodule
