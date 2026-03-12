`timescale 1ns / 1ps

// ============================================================
// tb_serializer_uart
// 병렬 입력 → Serializer_UART → uart_tx_fifo → TX 직렬 출력
// ============================================================
module tb_serializer_uart;

    // ── 클럭 / 리셋 ───────────────────────────────────
    logic       clk;
    logic       reset;
    // ── DUT 입력 (병렬) ───────────────────────────────
    logic [9:0] r_target_x;
    logic [9:0] r_target_y;
    logic       r_status;
    logic [9:0] g_target_x;
    logic [9:0] g_target_y;
    logic       g_status;
    logic [9:0] b_target_x;
    logic [9:0] b_target_y;
    logic       b_status;
    logic       done;
    // ── Serializer ↔ uart_tx_fifo 연결 와이어 ─────────
    logic [7:0] w_fifo_wdata;
    logic       w_fifo_wr;
    logic       w_fifo_full;

    // ── TX 출력 ───────────────────────────────────────
    logic       tx;

    // ── Serializer_UART 인스턴스 ──────────────────────
    Serializer_UART u_Serializer_UART (
        .clk       (clk),
        .reset     (reset),
        .done      (done),
        .r_target_x(r_target_x),
        .r_target_y(r_target_y),
        .r_status  (r_status),
        .g_target_x(g_target_x),
        .g_target_y(g_target_y),
        .g_status  (g_status),
        .b_target_x(b_target_x),
        .b_target_y(b_target_y),
        .b_status  (b_status),
        .fifo_full (w_fifo_full),
        .fifo_wdata(w_fifo_wdata),
        .fifo_wr   (w_fifo_wr)
    );

    // ── uart_tx_fifo 인스턴스 ─────────────────────────
    uart_tx_fifo #(
        .BPS(115200)
    ) u_uart_tx_fifo (
        .clk  (clk),
        .reset(reset),
        .wdata(w_fifo_wdata),
        .wr   (w_fifo_wr),
        .full (w_fifo_full),
        .tx   (tx)
    );
    // 100MHz 클럭 (10ns 주기)
    always #5 clk = ~clk;
    // ── 시뮬레이션 메인 ───────────────────────────────
    initial begin
        // 초기화
        clk        = 0;
        reset      = 1;
        done       = 0;
        r_target_x = 0;
        r_target_y = 0;
        r_status   = 0;
        g_target_x = 0;
        g_target_y = 0;
        g_status   = 0;
        b_target_x = 0;
        b_target_y = 0;
        b_status   = 0;

        // 리셋 해제
        repeat (10) @(posedge clk);
        reset = 0;
        repeat (5) @(posedge clk);

        // ── 병렬 입력값 설정 ──────────────────────────
        // R: (100, 80),  status=1
        // G: (160, 120), status=1
        // B: (200, 150), status=0
        r_target_x = 10'd100;
        r_target_y = 10'd80;
        r_status   = 1'b1;
        g_target_x = 10'd160;
        g_target_y = 10'd120;
        g_status   = 1'b1;
        b_target_x = 10'd200;
        b_target_y = 10'd150;
        b_status   = 1'b0;

        repeat (5) @(posedge clk);
        // ── done 펄스 1사이클 발생 ────────────────────
        @(posedge clk);
        #1 done = 1'b1;
        @(posedge clk);
        #1 done = 1'b0;

        $display("=== done pulse sent ===");
        $display("R: x=%0d, y=%0d, status=%0b", r_target_x, r_target_y,
                 r_status);
        $display("G: x=%0d, y=%0d, status=%0b", g_target_x, g_target_y,
                 g_status);
        $display("B: x=%0d, y=%0d, status=%0b", b_target_x, b_target_y,
                 b_status);

        // ── 16바이트 전송 완료까지 대기 ──────────────
        // 115200bps 기준 1바이트 = 10bit / 115200 = 86.8us = 8680 사이클
        // 16바이트 = 약 138880 사이클 + 여유
        repeat (200000) @(posedge clk);

        $display("=== TX 전송 완료 ===");
        $finish;
    end

    // ── fifo_wr 카운터 (16번 발생 확인) ──────────────
    integer wr_cnt;
    initial wr_cnt = 0;
    always @(posedge clk) begin
        if (w_fifo_wr) begin
            wr_cnt = wr_cnt + 1;
            $display("[%0t ns] fifo_wr pulse #%0d  wdata=0x%02X", $time,
                     wr_cnt, w_fifo_wdata);
        end
    end

    // ── TX 핀 변화 모니터 ─────────────────────────────
    always @(tx) begin
        $display("[%0t ns] TX = %b", $time, tx);
    end

endmodule
