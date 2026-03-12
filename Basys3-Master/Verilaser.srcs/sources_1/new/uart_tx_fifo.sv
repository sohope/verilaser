module uart_tx_fifo #(
    parameter BPS = 115200
) (
    input logic clk,
    input logic reset,

    // Serializer_UART 연결 포트
    input  logic [7:0] wdata,  // Serializer → FIFO push 데이터
    input  logic       wr,     // Serializer → FIFO push 신호
    output logic       full,   // FIFO full → Serializer에 알림

    // TX 핀
    output logic tx
);

    // ── 내부 와이어 ───────────────────────────────────
    logic [7:0] w_rdata;
    logic       w_empty;
    logic       w_tx_busy;
    logic       w_tx_done;
    logic       w_n_tx_busy;
    logic       w_n_empty;

    assign w_n_tx_busy = ~w_tx_busy;
    assign w_n_empty   = ~w_empty;

    // ── FIFO 인스턴스 ─────────────────────────────────
    FIFO u_FIFO (
        .clk  (clk),
        .reset(reset),
        .wr   (wr),
        .rd   (w_n_tx_busy),  // ~tx_busy
        .wdata(wdata),
        .rdata(w_rdata),
        .full (full),
        .empty(w_empty)
    );

    // ── uart_tx 인스턴스 ──────────────────────────────
    uart_tx #(
        .BPS(BPS)
    ) u_uart_tx (
        .clk     (clk),
        .reset   (reset),
        .tx_data (w_rdata),
        .tx_start(w_n_empty),  // ~empty
        .tx      (tx),
        .tx_done (w_tx_done),
        .tx_busy (w_tx_busy)
    );

endmodule
