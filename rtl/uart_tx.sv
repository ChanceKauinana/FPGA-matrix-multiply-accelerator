`timescale 1ns/1ps
`default_nettype none

module uart_tx #(
    parameter int CLKS_PER_BIT = 10417
)(
    input wire logic         clk,
    input wire logic         rst,

    input wire logic         tx_start,
    input wire logic [7:0]   tx_data,

    output logic             tx,
    output logic             tx_busy,
    output logic             tx_done
);

    typedef enum logic [2:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT,
        CLEANUP
    }state_t;

    state_t state;

    localparam int CLK_COUNT_WIDTH = $clog2(CLKS_PER_BIT + 1);

    logic [CLK_COUNT_WIDTH-1:0] clk_count;
    logic [2:0] bit_index;
    logic [7:0] tx_shift;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            tx <= 1'b1;
            tx_busy <= 1'b0;
            tx_done <= 1'b0;
            clk_count <= '0;
            bit_index <= '0;
            tx_shift <= '0;
        end else begin
            tx_done <= 1'b0;

            case (state)

                IDLE: begin
                    tx  <= 1'b1;
                    tx_busy <= 1'b0;
                    clk_count <= '0;
                    bit_index <= '0;

                    if (tx_start) begin
                        tx_shift <= tx_data;
                        tx_busy <= 1'b1;
                        state <= START_BIT;
                    end
                end

                START_BIT: begin
                    tx <= 1'b0;

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;
                        state <= DATA_BITS;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DATA_BITS: begin
                    tx <= tx_shift[bit_index];

                    if(clk_count == CLKS_PER_BIT -1) begin
                        clk_count <= '0;
                    
                        if (bit_index == 3'd7) begin
                            bit_index <= '0;
                            state <= STOP_BIT;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP_BIT: begin
                    tx <= 1'b1;

                    if (clk_count == CLKS_PER_BIT -1) begin
                        clk_count <= '0;
                        state <= CLEANUP;

                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                CLEANUP: begin
                    tx_done <= 1'b1;
                    tx_busy <= 1'b0;
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