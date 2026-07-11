`timescale 1ns/1ps
`default_nettype none

module mac_unit #(
    parameter int A_WIDTH   = 8,
    parameter int B_WIDTH   = 8,
    parameter int ACC_WIDTH = 32
)(
    input wire logic        clk,
    input wire logic        rst,
    input wire logic        clear,
    input wire logic       enable,
    input wire logic signed [A_WIDTH-1:0] a,
    input wire logic signed [B_WIDTH-1:0] b,

    output logic signed [ACC_WIDTH-1:0] result
);

    logic signed [15:0] product;

    assign product = a * b;

    always_ff@(posedge clk) begin
        if (rst) begin
            result <= '0;
        end else if (clear) begin
            result <= '0;
        end else if (enable) begin
            result <= result + product;
        end
    end



endmodule

`default_nettype wire