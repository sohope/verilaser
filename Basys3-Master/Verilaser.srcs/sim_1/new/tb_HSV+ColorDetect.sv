`timescale 1ns / 1ps


module tb_HSV_ColorDetect ();

    logic       clk;
    logic       reset;
    logic       DE_in;
    logic [9:0] x_in;
    logic [9:0] y_in;
    logic [3:0] R_in;
    logic [3:0] G_in;
    logic [3:0] B_in;
    logic       w_DE_out;
    logic [9:0] w_x_out;
    logic [9:0] w_y_out;
    logic [7:0] w_H_out;
    logic [7:0] w_S_out;
    logic [7:0] w_V_out;
    logic       w_DE_CD;
    logic [9:0] w_x_CD, w_y_CD;
    logic red_detect, green_detect, blue_detect;

    HSV_Converter u_HSV_Converter (
        .clk   (clk),
        .reset (reset),
        .DE_in (DE_in),
        .x_in  (x_in),
        .y_in  (y_in),
        .R_in  (R_in),
        .G_in  (G_in),
        .B_in  (B_in),
        .DE_out(w_DE_out),
        .x_out (w_x_out),
        .y_out (w_y_out),
        .H_out (w_H_out),
        .S_out (w_S_out),
        .V_out (w_V_out)
    );

    Color_Detect u_Color_Detect (
        .clk         (clk),
        .reset       (reset),
        .DE_in       (w_DE_out),
        .x_in        (w_x_out),
        .y_in        (w_y_out),
        .H_in        (w_H_out),
        .S_in        (w_S_out),
        .V_in        (w_V_out),
        .DE_out      (w_DE_CD),
        .x_out       (w_x_CD),
        .y_out       (w_y_CD),
        .red_detect  (red_detect),
        .green_detect(green_detect),
        .blue_detect (blue_detect)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; 
        reset = 1; 
        DE_in = 0; x_in = 0; y_in = 0;
        R_in = 0; G_in = 0; B_in = 0;
        #20 
        reset = 0;
        #10 
        DE_in = 1;
        x_in = 11;
        R_in = 4'b1111; G_in = 4'b0000; B_in = 4'b0001;
        #100
        $finish;
    end


endmodule
