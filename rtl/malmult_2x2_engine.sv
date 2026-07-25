`timescale 1ns/1ps
`default_nettype none

module malmult_2x2_engine #(
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32
)(
    input wire logic       clk,
    input wire logic       rst,
    input wire logic      start,

    input wire logic signed [DATA_WIDTH-1:0] a00,
    input wire logic signed [DATA_WIDTH-1:0] a01,
    input wire logic signed [DATA_WIDTH-1:0] a10,
    input wire logic signed [DATA_WIDTH-1:0] a11,

    input wire logic signed [DATA_WIDTH-1:0] b00,
    input wire logic signed [DATA_WIDTH-1:0] b01,
    input wire logic signed [DATA_WIDTH-1:0] b10,
    input wire logic signed [DATA_WIDTH-1:0] b11,

    output logic          busy,
    output logic          done,

    output logic signed [ACC_WIDTH-1:0] c00,
    output logic signed [ACC_WIDTH-1:0] c01,
    output logic signed [ACC_WIDTH-1:0] c10,
    output logic signed [ACC_WIDTH-1:0] c11
);

typedef enum logic [0:0] {
    IDLE,
    COMPUTE
} state_t;

state_t state;

always_ff@(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        busy <= 1'b0;
        done <= 1'b0;

        c00 <= '0;
        c01 <= '0;
        c10 <= '0;
        c11 <= '0;
    end else begin
        done <= 1'b0;

        case (state)

            IDLE: begin
                busy <= 1'b0;
                if (start) begin
                    state <= COMPUTE;
                    busy <= 1'b1;
                end
            end

            COMPUTE: begin
                c00 <= (a00 * b00) + (a01 * b10);
                c01 <= (a00 * b01) + (a01 * b11);
                c10 <= (a10 * b00) + (a11 * b10);
                c11 <= (a10 * b01) + (a11 * b11);
                busy <= 1'b0;
                done <= 1'b1;
                state <= IDLE;
            end

            default: begin
                state <= IDLE;
            end
        endcase
    end
end
endmodule

`default_nettype wire