`timescale 1ns/1ps
`default_nettype none

module dot_product_engine #(
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32,
    parameter int VECTOR_SIZE = 4
)(
    input wire logic       clk,
    input wire logic       rst,

    input wire logic       start,
    input wire logic       valid_in,
    input wire logic signed [DATA_WIDTH-1:0] a,
    input wire logic signed [DATA_WIDTH-1:0] b,

    output logic           busy,
    output logic           done,
    output logic signed [ACC_WIDTH-1:0] result
);

localparam int COUNT_WIDTH = $clog2(VECTOR_SIZE+1);

logic signed [ACC_WIDTH-1:0] acc;
logic signed [(2*DATA_WIDTH)-1:0] product;
logic signed [ACC_WIDTH-1:0] product_ext;

logic [COUNT_WIDTH-1:0] count;
logic mac_clear;
logic mac_enable;
logic signed [ACC_WIDTH-1:0] mac_result;

assign product = a * b;
assign product_ext = {{(ACC_WIDTH-(2*DATA_WIDTH)){product[(2*DATA_WIDTH)-1]}}, product};    



typedef enum logic [0:0] {
    IDLE,
    RUN
} state_t;

state_t state;
//goal compute N multiply accumilate operations
// sum = a0*b0 + a1*b1 + a2*b2 + ... + aN*bN

mac_unit #(
    .A_WIDTH (DATA_WIDTH),
    .B_WIDTH  (DATA_WIDTH),
    .ACC_WIDTH (ACC_WIDTH)
) mac_inst (
    .clk(clk),
    .rst(rst),
    .clear(mac_clear),
    .enable(mac_enable),
    .a(a),
    .b(b),
    .result(mac_result)
);

always_ff@(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        count <= '0;
        busy <= 1'b0;
        done <= 1'b0;
        result <= '0;
        mac_clear <= 1'b0;
        mac_enable <= 1'b0;
    end else begin
        done <= 1'b0;
        mac_clear <= 1'b0;
        mac_enable <= 1'b0;

        case(state)

            IDLE: begin
                busy <= 1'b0;

                if (start) begin
                    state <= RUN;
                    busy <= 1'b1;
                    count <= '0;
                    mac_clear <= 1'b1;
                end
            end

            RUN: begin
                busy <= 1'b1;
                if (valid_in) begin
                    mac_enable <= 1'b1;
                    count <= count + 1'b1;
                    
                    if (count == VECTOR_SIZE-1) begin
                        state <= IDLE;
                        done <= 1'b1;
                        result <= mac_result + product_ext;
                        busy <= 1'b0;
                    end
                end
            end

            default: begin
                state <= IDLE;
            end
            
        endcase
    end
end

endmodule






`default_nettype wire 

