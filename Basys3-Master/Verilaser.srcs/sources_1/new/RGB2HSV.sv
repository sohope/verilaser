`timescale 1ns / 1ps

module RGB2HSV (
    input  logic [15:0] pixel_data,
    output logic        mask_red,
    output logic        mask_green,
    output logic        mask_blue
);
    logic [7:0] R8, G8, B8;
    logic [7:0] RGB_max, RGB_min, RGB_delta;
    logic sat_pass;

    // Normalization 
    assign R8 = {pixel_data[15:11], 3'b000};
    assign G8 = {pixel_data[10:5], 2'b00};
    assign B8 = {pixel_data[4:0], 3'b000};

    always_comb begin

        //Value = RGB_MAX
        RGB_max = (R8 > G8) ? ((R8 > B8) ? R8 : B8) : ((G8 > B8) ? G8 : B8);

        RGB_min = (R8 < G8) ? ((R8 < B8) ? R8 : B8) : ((G8 < B8) ? G8 : B8);

        RGB_delta = RGB_max - RGB_min;

        // Saturation = RGB_Delta/RGB_MAX
        // sat_pass = (RGB_delta > (RGB_max >> 1));  //Saturation > 50 %? pass 
         sat_pass = (RGB_delta > (RGB_max >> 2));  //Saturation > 25 %? pass 

        // mask_red = (RGB_max == R8) && sat_pass && (RGB_max > 40);
        // mask_green = (RGB_max == G8) && sat_pass && (RGB_max > 40);
        // mask_blue = (RGB_max == B8) && sat_pass && (RGB_max > 40);
        //
        mask_red = (RGB_max == R8) && sat_pass ;
        mask_green = (RGB_max == G8) && sat_pass ;
        mask_blue = (RGB_max == B8) && sat_pass ;
    end
 endmodule
