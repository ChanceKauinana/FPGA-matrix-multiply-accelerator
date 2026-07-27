`timescale 1ns/1ps
`default_nettype none

module uart_rx #(
    parameter int CLKS_PER_BIT = 10417
)(
    input  wire logic       clk,
    input  wire logic       rst,

    input  wire logic       rx,

    output      logic [7:0] rx_data,
    output      logic       rx_busy,
    output      logic       rx_done
);

    typedef enum logic [2:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT,
        CLEANUP
    } state_t;

    state_t state;

    localparam int CLK_COUNT_WIDTH = $clog2(CLKS_PER_BIT + 1);

    logic [CLK_COUNT_WIDTH-1:0] clk_count;
    logic [2:0]                 bit_index;
    logic [7:0]                 rx_shift;

    logic rx_meta;
    logic rx_sync;

    always_ff @(posedge clk) begin
        if (rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            clk_count <= '0;
            bit_index <= '0;
            rx_shift  <= '0;
            rx_data   <= '0;
            rx_busy   <= 1'b0;
            rx_done   <= 1'b0;
        end else begin
            rx_done <= 1'b0;

            case (state)

                IDLE: begin
                    rx_busy   <= 1'b0;
                    clk_count <= '0;
                    bit_index <= '0;

                    if (rx_sync == 1'b0) begin
                        rx_busy <= 1'b1;
                        state   <= START_BIT;
                    end
                end

                START_BIT: begin
                    if (clk_count == (CLKS_PER_BIT / 2) - 1) begin
                        if (rx_sync == 1'b0) begin
                            clk_count <= '0;
                            state     <= DATA_BITS;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DATA_BITS: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;

                        rx_shift[bit_index] <= rx_sync;

                        if (bit_index == 3'd7) begin
                            bit_index <= '0;
                            state     <= STOP_BIT;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP_BIT: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;
                        state     <= CLEANUP;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                CLEANUP: begin
                    rx_data <= rx_shift;
                    rx_done <= 1'b1;
                    rx_busy <= 1'b0;
                    state   <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule

`default_nettype wire