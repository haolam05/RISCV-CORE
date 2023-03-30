module display_control #(parameter NUM_SEGMENTS, parameter ASCII_LEN) (clk, bytes_4, HEX0, HEX1, HEX2, HEX3);
    input  logic                    clk;
    input  logic [ 4*ASCII_LEN-1:0] bytes_4;
    output logic [NUM_SEGMENTS-1:0] HEX0, HEX1, HEX2, HEX3;

    logic [ASCII_LEN-1:0] ascii_0, ascii_1, ascii_2, ascii_3, ascii_0_temp, ascii_1_temp, ascii_2_temp, ascii_3_temp;

    display #(.NUM_SEGMENTS(NUM_SEGMENTS), .ASCII_LEN(ASCII_LEN)) display3 (
        .ascii( ascii_3 ),
        .HEX  ( HEX3    )
    );
    display #(.NUM_SEGMENTS(NUM_SEGMENTS), .ASCII_LEN(ASCII_LEN)) display2 (
        .ascii( ascii_2 ),
        .HEX  ( HEX2    )
    );
    display #(.NUM_SEGMENTS(NUM_SEGMENTS), .ASCII_LEN(ASCII_LEN)) display1 (
        .ascii( ascii_1 ),
        .HEX  ( HEX1    )
    );
    display #(.NUM_SEGMENTS(NUM_SEGMENTS), .ASCII_LEN(ASCII_LEN)) display0 (
        .ascii( ascii_0 ),
        .HEX  ( HEX0    )
    );

    initial begin
        ascii_3_temp = 8'h20;    // space
        ascii_2_temp = 8'h20;    // space
        ascii_1_temp = 8'h20;    // space
        ascii_0_temp = 8'h20;    // space
    end

    assign ascii_3 = ascii_3_temp;
    assign ascii_2 = ascii_2_temp;
    assign ascii_1 = ascii_1_temp;
    assign ascii_0 = ascii_0_temp;

    always_ff @(posedge clk) begin
        if (bytes_4 == 32'h48692120 ||  // Hi!
            bytes_4 == 32'h57652020 ||  // "We"
            bytes_4 == 32'h61726520 ||  // "Are"
            bytes_4 == 32'h48616F20 ||  // "Hao"
            bytes_4 == 32'h616E6420 ||  // "and"
            bytes_4 == 32'h43617420 ||  // "Cat"
            bytes_4 == 32'h596F210A ||  // "Yo!"
            bytes_4 == 32'h31323334     // "1234"
        )
            begin
                ascii_3_temp <= bytes_4[4*ASCII_LEN-1:3*ASCII_LEN];
                ascii_2_temp <= bytes_4[3*ASCII_LEN-1:2*ASCII_LEN];
                ascii_1_temp <= bytes_4[2*ASCII_LEN-1:  ASCII_LEN];
                ascii_0_temp <= bytes_4[  ASCII_LEN-1:  0        ];
            end
    end
endmodule
