module uart_controller (
    input logic clk,    // clk_100m
    input logic reset,
    input logic done,   // rclk 도메인 (Centroid)

    input logic [9:0] r_target_x,
    input logic [9:0] r_target_y,
    input logic       r_status,
    input logic [9:0] g_target_x,
    input logic [9:0] g_target_y,
    input logic       g_status,
    input logic [9:0] b_target_x,
    input logic [9:0] b_target_y,
    input logic       b_status,

    // uart_tx_fifo 연결
    input  logic       fifo_full,
    output logic [7:0] fifo_wdata,
    output logic       fifo_wr_en
);

    logic w_done_sync;
    logic w_done_rise;

    // CDC: done (rclk → clk_100m)
    sync_2ff #(
        .INIT(1'b0)
    ) u_done_sync (
        .clk  (clk),
        .reset(reset),
        .d    (done),
        .q    (w_done_sync)
    );

    edge_detector u_done_edge (
        .clk         (clk),
        .reset       (reset),
        .i_sig       (w_done_sync),
        .rising_edge (w_done_rise),
        .falling_edge(),
        .both_edge   ()
    );

    Serializer_UART u_Serializer_UART (
        .clk       (clk),
        .reset     (reset),
        .done      (w_done_rise),
        .r_target_x(r_target_x),
        .r_target_y(r_target_y),
        .r_status  (r_status),
        .g_target_x(g_target_x),
        .g_target_y(g_target_y),
        .g_status  (g_status),
        .b_target_x(b_target_x),
        .b_target_y(b_target_y),
        .b_status  (b_status),
        .fifo_full (fifo_full),
        .fifo_wdata(fifo_wdata),
        .fifo_wr_en(fifo_wr_en)
    );

endmodule
