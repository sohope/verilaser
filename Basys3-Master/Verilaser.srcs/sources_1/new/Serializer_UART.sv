module Serializer_UART (
    input logic clk,
    input logic reset,
    input logic done,   // 외부에서 이미 동기화된 1사이클 펄스

    input logic [9:0] r_target_x,
    input logic [9:0] r_target_y,
    input logic [9:0] g_target_x,
    input logic [9:0] g_target_y,
    input logic [9:0] b_target_x,
    input logic [9:0] b_target_y,
    input logic       r_status,
    input logic       g_status,
    input logic       b_status,

    input  logic       fifo_full,
    output logic [7:0] fifo_wdata,
    output logic       fifo_wr_en   // fifo_wr_enite_enable
);

    logic [7:0] packet[0:17];
    logic [4:0] idx;
    logic [8:0] w_checksum;  // 합산 오버플로우 대비 9bit

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        PUSH = 2'b01,
        WAIT = 2'b10
    } state_t;

    state_t state;

    always_comb begin
        w_checksum = {6'b0, r_target_x[9:8]} +
                 r_target_x[7:0] +
                 {6'b0, r_target_y[9:8]} +
                 r_target_y[7:0] +
                 {7'b0, r_status} +
                 {6'b0, g_target_x[9:8]} +
                 g_target_x[7:0] +
                 {6'b0, g_target_y[9:8]} +
                 g_target_y[7:0] +
                 {7'b0, g_status} +
                 {6'b0, b_target_x[9:8]} +
                 b_target_x[7:0] +
                 {6'b0, b_target_y[9:8]} +
                 b_target_y[7:0] +
                 {7'b0, b_status};
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state      <= IDLE;
            idx        <= 0;
            fifo_wr_en <= 0;
            fifo_wdata <= 0;
            for (int i = 0; i < 18; i++) begin
                packet[i] <= 8'h00;
            end
        end else begin
            fifo_wr_en <= 0;
            case (state)
                IDLE: begin
                    if (done && !fifo_full) begin  // done_pulse → done
                        packet[0]  <= 8'hFF;
                        packet[1]  <= {6'b0, r_target_x[9:8]};
                        packet[2]  <= r_target_x[7:0];
                        packet[3]  <= {6'b0, r_target_y[9:8]};
                        packet[4]  <= r_target_y[7:0];
                        packet[5]  <= {7'b0, r_status};
                        packet[6]  <= {6'b0, g_target_x[9:8]};
                        packet[7]  <= g_target_x[7:0];
                        packet[8]  <= {6'b0, g_target_y[9:8]};
                        packet[9]  <= g_target_y[7:0];
                        packet[10] <= {7'b0, g_status};
                        packet[11] <= {6'b0, b_target_x[9:8]};
                        packet[12] <= b_target_x[7:0];
                        packet[13] <= {6'b0, b_target_y[9:8]};
                        packet[14] <= b_target_y[7:0];
                        packet[15] <= {7'b0, b_status};
                        packet[16] <= w_checksum[7:0];  // 하위 8bit만
                        packet[17] <= 8'hFE;
                        idx        <= 0;
                        state      <= PUSH;
                    end
                end

                PUSH: begin
                    // if (!fifo_full) begin
                    fifo_wdata <= packet[idx];
                    fifo_wr_en    <= 1'b1;
                    state   <= WAIT;
                    // end
                end

                WAIT: begin
                    if (idx == 5'd17) begin
                        state <= IDLE;
                        idx   <= 0;
                    end else begin
                        idx   <= idx + 1;
                        state <= PUSH;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
