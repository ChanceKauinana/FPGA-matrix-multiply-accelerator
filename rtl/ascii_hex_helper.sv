`timescale 1ns/1ps
`default_nettype none

module ascii_hex_helper (
    input wire logic [7:0] ascii_char,

    output logic       is_hex,
    output logic [3:0] ascii_nibble,
    input wire logic [3:0] hex_nibble,

    output logic [7:0] hex_ascii
);

//ASCII character to 4-bit hex nibble conversion
    // "0" -> 4'h0
    // "1" -> 4'h1
    // ...
    // "9" -> 4'h9
    // "A" -> 4'hA
    // ...
    // "F" -> 4'hF
    // "a" -> 4'hA
    // ...
    // "f" -> 4'hF

    always_comb begin
        is_hex = 1'b0;
        ascii_nibble = 4'b0;

        if ((ascii_char >= 8'h30) && (ascii_char <= 8'h39)) begin
            is_hex = 1'b1;
            ascii_nibble = ascii_char[3:0];
        end else if ((ascii_char >= 8'h41) && (ascii_char <= 8'h46)) begin
            is_hex = 1'b1;
            ascii_nibble = ascii_char - 8'h41 + 4'd10;
        end else if ((ascii_char >= 8'h61) && (ascii_char <= 8'h66)) begin
            is_hex = 1'b1;
            ascii_nibble = ascii_char - 8'h61 + 4'd10;
        end
    end

    // 4-bit hex nibble to ASCII character
    //
    // 4'h0 -> "0"
    // 4'h1 -> "1"
    // ...
    // 4'h9 -> "9"
    // 4'hA -> "A"
    // ...
    // 4'hF -> "F"

    always_comb begin
        if (hex_nibble < 4'd10) begin
            hex_ascii = 8'h30 + hex_nibble;
        end else begin
            hex_ascii = 8'h41 + (hex_nibble - 4'd10);
        end
    end
endmodule

`default_nettype wire