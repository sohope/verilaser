`timescale 1ns / 1ps

module i2c_hw_top (
    input  wire clk,        // 100MHz
    input  wire btn_reset,  // btnC, active HIGH
    output wire scl,        // JA[0] - 로직 애널라이저 프로브
    output wire sda,        // JA[1] - 로직 애널라이저 프로브
    output wire [7:0] led   // rx_data 표시
);

    wire reset_n = ~btn_reset;

    // I2C master interface
    wire        i2c_en;
    wire        i2c_start;
    wire        i2c_stop;
    wire        i2c_nack;
    wire  [7:0] tx_data;
    wire        tx_done;
    wire        tx_ready;
    wire  [7:0] rx_data;
    wire        rx_done;

    // SDA 버스 해결: 명시적 mux (합성 호환)
    wire scl_w;
    wire m_sda_o, m_sda_oen;
    wire s_sda_o, s_sda_oen;
    wire sda_resolved = m_sda_oen ? m_sda_o :
                        s_sda_oen ? s_sda_o : 1'b1;

    assign scl = scl_w;
    assign sda = sda_resolved;

    // LED에 마지막 수신 데이터 표시
    reg [7:0] led_reg;
    assign led = led_reg;

    always @(posedge clk, negedge reset_n) begin
        if (!reset_n) led_reg <= 0;
        else if (rx_done) led_reg <= rx_data;
    end

    // 시퀀서
    i2c_sequencer U_SEQ (
        .clk(clk), .reset_n(reset_n),
        .i2c_en(i2c_en), .i2c_start(i2c_start),
        .i2c_stop(i2c_stop), .i2c_nack(i2c_nack),
        .tx_data(tx_data), .tx_done(tx_done),
        .tx_ready(tx_ready), .rx_data(rx_data),
        .rx_done(rx_done)
    );

    // Master
    i2c_master_core U_MASTER (
        .clk(clk), .reset_n(reset_n),
        .i2c_en(i2c_en), .i2c_start(i2c_start),
        .i2c_stop(i2c_stop), .i2c_nack(i2c_nack),
        .tx_data(tx_data), .tx_done(tx_done),
        .tx_ready(tx_ready), .rx_data(rx_data),
        .rx_done(rx_done),
        .scl(scl_w),
        .sda_o(m_sda_o), .sda_oen(m_sda_oen), .sda_i(sda_resolved)
    );

    // Slave
    i2c_slave #(
        .SLAVE_ADDR(7'h50), .N_REG(4)
    ) U_SLAVE (
        .clk(clk), .reset_n(reset_n),
        .scl(scl_w),
        .sda_o(s_sda_o), .sda_oen(s_sda_oen), .sda_i(sda_resolved)
    );

endmodule
