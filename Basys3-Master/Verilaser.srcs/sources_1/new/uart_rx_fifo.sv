module uart_rx_fifo #(
    parameter BPS = 115200
) (
    input logic rclk,
    input logic clk,
    input logic reset,

    // RX 핀
    input logic rx,

    // 외부 연결 포트 (나중에 사용)
    input  logic       rd,     // 외부에서 pop 신호
    output logic [7:0] rdata,  // 수신 데이터 출력
    output logic       empty,  // FIFO empty 상태
    output logic       full    // FIFO full 상태
);

    // ── 내부 와이어 ───────────────────────────────────
    logic [7:0] w_rx_data;
    logic       w_rx_done;

    // ── uart_rx 인스턴스 ──────────────────────────────
    uart_rx #(
        .BPS(BPS)
    ) u_uart_rx (
        .clk    (clk),
        .reset  (reset),
        .rx     (rx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );

    // ── FIFO 인스턴스 ─────────────────────────────────
    FIFO u_FIFO (
        .clk  (rclk),
        .reset(reset),
        .wr   (w_rx_done),  // rx_done → push
        .rd   (rd),         // 외부 pop 신호
        .wdata(w_rx_data),
        .rdata(rdata),
        .full (full),
        .empty(empty)
    );

endmodule
