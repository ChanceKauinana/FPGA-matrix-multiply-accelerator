`timescale 1ns/1ps
`default_nettype none

module uart_tx_test_top #(
    parameter int CLKS_PER_BIT = 10417,
    parameter int WAIT_CYCLES  = 100_000_000
)(
    input  wire logic clk,
    input  wire logic rst,

    output      logic uart_tx,
    output      logic [15:0] led
);

    logic       tx_start;
    logic [7:0] tx_data;
    logic       tx_busy;
    logic       tx_done;

    logic [31:0] wait_count;

    assign tx_data = 8'h41; // ASCII 'A'

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) tx_inst (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(uart_tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            wait_count <= '0;
            tx_start   <= 1'b0;
        end else begin
            tx_start <= 1'b0;

            if (!tx_busy) begin
                if (wait_count == WAIT_CYCLES - 1) begin
                    wait_count <= '0;
                    tx_start   <= 1'b1;
                end else begin
                    wait_count <= wait_count + 1'b1;
                end
            end
        end
    end

    assign led[0]    = tx_busy;
    assign led[1]    = tx_done;
    assign led[7:2]  = 6'b0;
    assign led[15:8] = tx_data;

endmodule

`default_nettype wire