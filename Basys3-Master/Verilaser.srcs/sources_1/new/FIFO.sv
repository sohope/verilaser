`timescale 1ns / 1ps

module FIFO (
    input clk,
    input reset,
    input wr,
    input rd,
    input [7:0] wdata,
    output [7:0] rdata,
    output full,
    output empty
);

    wire [4:0] w_wptr, w_rptr;

    register_file U_Reg_File (
        .clk(clk),
        .waddr(w_wptr),
        .wdata(wdata),
        .raddr(w_rptr),
        .wr(~full & wr),
        .rd(~empty & rd),
        .rdata(rdata)
    );

    fifo_control_unit U_FIFO_CU (
        .clk(clk),
        .reset(reset),
        .wr(wr),
        .rd(rd),
        .w_ptr(w_wptr),
        .r_ptr(w_rptr),
        .full(full),
        .empty(empty)
    );
endmodule

module register_file (
    input clk,
    input [4:0] waddr,
    input [7:0] wdata,
    input [4:0] raddr,
    input wr,
    input rd,
    output reg [7:0] rdata
);
    //  data 8bit, size 4byte
    logic [7:0] register_file[0:31];
    reg   [7:0] reg_rdata;

    always_ff @(posedge clk) begin
        // write, push
        if (wr) begin
            register_file[waddr] <= wdata;
        end
        //  순차 출력
        // if (rd) begin
        //     rdata <= register_file[raddr];
        // end
    end

    // 조합출력
    // read, pop combimational logic    
    assign rdata = register_file[raddr];

endmodule


module fifo_control_unit (
    input clk,
    input reset,
    input wr,
    input rd,
    output [4:0] w_ptr,
    output [4:0] r_ptr,
    output full,
    output empty
);

    logic c_full, n_full, c_empty, n_empty;
    logic [4:0] c_wptr, n_wptr, c_rptr, n_rptr;

    assign full  = c_full;
    assign empty = c_empty;
    assign w_ptr = c_wptr;
    assign r_ptr = c_rptr;

    //  state register logic
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            c_full  <= 1'b0;
            c_empty <= 1'b1;
            c_wptr  <= 5'b00000;
            c_rptr  <= 5'b00000;

        end else begin
            c_full  <= n_full;
            c_empty <= n_empty;
            c_wptr  <= n_wptr;
            c_rptr  <= n_rptr;
        end
    end

    always_comb begin
        n_full  = c_full;
        n_empty = c_empty;
        n_wptr  = c_wptr;
        n_rptr  = c_rptr;
        case ({
            wr, rd
        })  // state wr, rd or push, pop
            // 2'b00: begin
            //     //  idle
            // end

            2'b01: begin
                //pop
                n_full = 1'b0;
                if (!empty) begin
                    n_rptr = c_rptr + 1;
                    if (c_wptr == n_rptr) begin
                        n_empty = 1'b1;
                    end
                end
            end
            2'b10: begin
                n_empty = 1'b0;
                //  push
                if (!c_full) begin
                    n_wptr = c_wptr + 1;
                    if (c_rptr == n_wptr) begin
                        n_full = 1'b1;
                    end
                end
            end
            2'b11: begin
                //  push, pop
                if (c_empty == 1) begin
                    // only push
                    n_empty = 1'b0;
                    n_wptr  = c_wptr + 1;
                end else if (c_full == 1) begin
                    // only pop
                    n_full = 1'b0;
                    n_rptr = c_rptr + 1;
                end else begin
                    // write, read ptr inc..
                    n_wptr = c_wptr + 1;
                    n_rptr = c_rptr + 1;
                end
            end
        endcase
    end

endmodule
