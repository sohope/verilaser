`timescale 1ns / 1ps

module tb_OV7670_Init_Controller();

    logic clk;
    logic reset;
    wire  sda;
    wire  scl;

    // SDA pullup (OV7670 slave가 없으므로 항상 ACK=0 응답 시뮬레이션)
    pullup(sda);

    OV7670_Init_Controller #(
        .N_REGS(60)
    ) DUT (
        .clk  (clk),
        .reset(reset),
        .sda  (sda),
        .scl  (scl)
    );

    // 100MHz clock
    initial clk = 0;
    always #5 clk = ~clk;

    // 내부 신호 모니터링
    wire [3:0]  seq_state  = DUT.U_SCCB_SEQUENCER.state;
    wire [7:0]  seq_regIdx = DUT.U_SCCB_SEQUENCER.regIdx;
    wire [21:0] seq_delay  = DUT.U_SCCB_SEQUENCER.delay_cnt;
    wire [7:0]  rom_addr   = DUT.rom_addr;
    wire [15:0] rom_data   = DUT.rom_data;
    wire        tx_done    = DUT.tx_done;
    wire        tx_ready   = DUT.tx_ready;

    initial begin
        reset = 1;
        #100;
        reset = 0;

        wait(seq_state == 4'd13);

        #1000;
        $finish;
    end
endmodule
