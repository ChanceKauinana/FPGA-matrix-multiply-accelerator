`timescale 1ns/1ps
`default_nettype none

module uart_echo_top #(
    parameter int CLKS_PER_BIT = 10417
)(
    input  wire logic       clk,
    input  wire logic       rst,

    input  wire logic       uart_rx,
    output      logic       uart_tx,

    output      logic [15:0] led
);

    logic [7:0] rx_data;
    logic       rx_busy;
    logic       rx_done;

    logic [7:0] tx_data;
    logic       tx_start;
    logic       tx_busy;
    logic       tx_done;

    logic [7:0] pending_data;
    logic       pending_valid;

    typedef enum logic [1:0] {
        WAIT_RX,
        LOAD_TX,
        START_TX,
        WAIT_TX_DONE
    } echo_state_t;

    echo_state_t echo_state;

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) rx_inst (
        .clk(clk),
        .rst(rst),
        .rx(uart_rx),
        .rx_data(rx_data),
        .rx_busy(rx_busy),
        .rx_done(rx_done)
    );

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
            echo_state    <= WAIT_RX;
            pending_data  <= '0;
            pending_valid <= 1'b0;
            tx_data       <= '0;
            tx_start      <= 1'b0;
        end else begin
            tx_start <= 1'b0;

            case (echo_state)

                WAIT_RX: begin
                    pending_valid <= 1'b0;

                    if (rx_done) begin
                        pending_data  <= rx_data;
                        pending_valid <= 1'b1;
                        echo_state    <= LOAD_TX;
                    end
                end

                LOAD_TX: begin
                    tx_data    <= pending_data;
                    echo_state <= START_TX;
                end

                START_TX: begin
                    if (!tx_busy) begin
                        tx_start      <= 1'b1;
                        pending_valid <= 1'b0;
                        echo_state    <= WAIT_TX_DONE;
                    end
                end

                WAIT_TX_DONE: begin
                    if (tx_done) begin
                        echo_state <= WAIT_RX;
                    end
                end

                default: begin
                    echo_state <= WAIT_RX;
                end

            endcase
        end
    end

    assign led[7:0]   = rx_data;
    assign led[8]     = rx_done;
    assign led[9]     = rx_busy;
    assign led[10]    = tx_busy;
    assign led[11]    = pending_valid;
    assign led[15:12] = 4'b0000;

endmodule

`default_nettype wire