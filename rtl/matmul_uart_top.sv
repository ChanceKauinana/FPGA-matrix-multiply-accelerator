`timescale 1ns/1ps
`default_nettype none

module matmul_uart_top #(
    parameter int CLKS_PER_BIT = 10417
)(
    input  wire logic       clk,
    input  wire logic       rst,

    input  wire logic       uart_rx,
    output      logic       uart_tx,
    output      logic [15:0] led
);

//UART RX Signals

    logic [7:0] rx_data;
    logic       rx_busy;
    logic       rx_done;

    //UART TX Signals
    logic [7:0] tx_data;
    logic       tx_start;
    logic       tx_busy;
    logic       tx_done;

    //ASCII hex helper signals
    logic       rx_is_hex;
    logic [3:0] rx_nibble;

    logic [3:0] tx_hex_nibble;
    logic [7:0] tx_hex_ascii;
    logic [7:0] tx_char_next;

    //Matrix input registers
    logic signed [7:0] a00, a01, a10, a11;
    logic signed [7:0] b00, b01, b10, b11;

    //Matrix output wires

    logic signed [31:0] c00, c01, c10, c11;
    logic              matmul_start;
    logic             matmul_done;
    logic            matmul_busy;

    //Latched Results 
    logic [31:0] r00, r01, r10, r11;

    // State machine for UART 

    logic [3:0] byte_count;
    logic       nibble_phase;
    logic [3:0] high_nibble;

    //Output message state 

    localparam int SEND_LEN = 39;
    logic [5:0] send_index;
    logic [5:0] send_pos;

    typedef enum logic [2:0] {
        RX_INPUT,
        START_MATMUL,
        WAIT_MATMUL_DONE,
        SEND_LOAD,
        SEND_WAIT
    } state_t;

    state_t state;


    //UART modules

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


    //ASCII hex helper module

    ascii_hex_helper ascii_hex_inst (
        .ascii_char(rx_data),
        .is_hex(rx_is_hex),
        .ascii_nibble(rx_nibble),

        .hex_nibble(tx_hex_nibble),
        .hex_ascii(tx_hex_ascii)
    );

    malmult_2x2_engine #(
        .DATA_WIDTH(8),
        .ACC_WIDTH(32)
    ) matmul_inst (
        .clk(clk),
        .rst(rst),
        .start(matmul_start),

        .a00(a00),
        .a01(a01),
        .a10(a10),
        .a11(a11),

        .b00(b00),
        .b01(b01),
        .b10(b10),
        .b11(b11),

        .busy(matmul_busy),
        .done(matmul_done),

        .c00(c00),
        .c01(c01),
        .c10(c10),
        .c11(c11)
    );

    function automatic logic [3:0] word_nibble(
        input logic [31:0] word,
        input int          nibble_index
    );

        begin
            case (nibble_index)
                3'd0: word_nibble = word[31:28];
                3'd1: word_nibble = word[27:24];
                3'd2: word_nibble = word[23:20];
                3'd3: word_nibble = word[19:16];
                3'd4: word_nibble = word[15:12];
                3'd5: word_nibble = word[11:8];
                3'd6: word_nibble = word[7:4];
                3'd7: word_nibble = word[3:0];
                default: word_nibble = 4'b0;
            endcase
        end
    endfunction

    //Generate the UART output characters next

    always_comb begin
        tx_char_next = 8'h20;
        tx_hex_nibble = 4'b0;
        send_pos      = 6'b0;

        if (send_index == 6'd0) begin
            tx_char_next = "C";

        end else if (send_index == 6'd1) begin
            tx_char_next = "=";

        end else if ((send_index >= 6'd2) && (send_index <= 6'd9)) begin
            send_pos      = send_index - 6'd2;
            tx_hex_nibble = word_nibble(r00, send_pos[2:0]);
            tx_char_next  = tx_hex_ascii;

        end else if (send_index == 6'd10) begin
            tx_char_next = " ";

        end else if ((send_index >= 6'd11) && (send_index <= 6'd18)) begin
            send_pos      = send_index - 6'd11;
            tx_hex_nibble = word_nibble(r01, send_pos[2:0]);
            tx_char_next  = tx_hex_ascii;

        end else if (send_index == 6'd19) begin
            tx_char_next = " ";

        end else if ((send_index >= 6'd20) && (send_index <= 6'd27)) begin
            send_pos      = send_index - 6'd20;
            tx_hex_nibble = word_nibble(r10, send_pos[2:0]);
            tx_char_next  = tx_hex_ascii;

        end else if (send_index == 6'd28) begin
            tx_char_next = " ";

        end else if ((send_index >= 6'd29) && (send_index <= 6'd36)) begin
            send_pos      = send_index - 6'd29;
            tx_hex_nibble = word_nibble(r11, send_pos[2:0]);
            tx_char_next  = tx_hex_ascii;

        end else if (send_index == 6'd37) begin
            tx_char_next = 8'h0D; // carriage return

        end else if (send_index == 6'd38) begin
            tx_char_next = 8'h0A; // newline
        end
    end




     always_ff @(posedge clk) begin
        if (rst) begin
            state <= RX_INPUT;

            a00 <= '0;
            a01 <= '0;
            a10 <= '0;
            a11 <= '0;

            b00 <= '0;
            b01 <= '0;
            b10 <= '0;
            b11 <= '0;

            r00 <= '0;
            r01 <= '0;
            r10 <= '0;
            r11 <= '0;

            byte_count   <= '0;
            nibble_phase <= 1'b0;
            high_nibble  <= '0;

            matmul_start <= 1'b0;

            tx_data    <= '0;
            tx_start   <= 1'b0;
            send_index <= '0;

        end else begin
            tx_start     <= 1'b0;
            matmul_start <= 1'b0;

            case (state)

                // ------------------------------------------------
                // Receive 16 ASCII hex characters.
                //
                // Example:
                // 0102030405060708
                //
                // Becomes:
                // a00 = 01
                // a01 = 02
                // a10 = 03
                // a11 = 04
                // b00 = 05
                // b01 = 06
                // b10 = 07
                // b11 = 08
                // ------------------------------------------------
                RX_INPUT: begin
                    if (rx_done && rx_is_hex) begin

                        if (nibble_phase == 1'b0) begin
                            high_nibble  <= rx_nibble;
                            nibble_phase <= 1'b1;

                        end else begin
                            nibble_phase <= 1'b0;

                            case (byte_count)
                                4'd0: a00 <= $signed({high_nibble, rx_nibble});
                                4'd1: a01 <= $signed({high_nibble, rx_nibble});
                                4'd2: a10 <= $signed({high_nibble, rx_nibble});
                                4'd3: a11 <= $signed({high_nibble, rx_nibble});
                                4'd4: b00 <= $signed({high_nibble, rx_nibble});
                                4'd5: b01 <= $signed({high_nibble, rx_nibble});
                                4'd6: b10 <= $signed({high_nibble, rx_nibble});
                                4'd7: b11 <= $signed({high_nibble, rx_nibble});
                                default: begin
                                end
                            endcase

                            if (byte_count == 4'd7) begin
                                byte_count <= '0;
                                state      <= START_MATMUL;
                            end else begin
                                byte_count <= byte_count + 1'b1;
                            end
                        end
                    end
                end

                // ------------------------------------------------
                // Pulse start into matrix multiply engine
                // ------------------------------------------------
                START_MATMUL: begin
                    matmul_start <= 1'b1;
                    state        <= WAIT_MATMUL_DONE;
                end

                // ------------------------------------------------
                // Wait for matrix engine to finish
                // ------------------------------------------------
                WAIT_MATMUL_DONE: begin
                    if (matmul_done) begin
                        r00 <= c00;
                        r01 <= c01;
                        r10 <= c10;
                        r11 <= c11;

                        send_index <= '0;
                        state      <= SEND_LOAD;
                    end
                end

                // ------------------------------------------------
                // Load next character into UART transmitter
                // ------------------------------------------------
                SEND_LOAD: begin
                    if (!tx_busy) begin
                        tx_data  <= tx_char_next;
                        tx_start <= 1'b1;
                        state    <= SEND_WAIT;
                    end
                end

                // ------------------------------------------------
                // Wait until current character is done transmitting
                // ------------------------------------------------
                SEND_WAIT: begin
                    if (tx_done) begin
                        if (send_index == SEND_LEN - 1) begin
                            send_index   <= '0;
                            byte_count   <= '0;
                            nibble_phase <= 1'b0;
                            state        <= RX_INPUT;
                        end else begin
                            send_index <= send_index + 1'b1;
                            state      <= SEND_LOAD;
                        end
                    end
                end

                default: begin
                    state <= RX_INPUT;
                end

            endcase
        end
    end

    // ------------------------------------------------------------
    // Debug LEDs
    // ------------------------------------------------------------
    assign led[7:0]   = rx_data;       // last received UART byte
    assign led[8]     = rx_done;       // pulses when byte received
    assign led[9]     = tx_busy;       // UART TX active
    assign led[10]    = matmul_busy;   // matrix engine busy
    assign led[11]    = matmul_done;   // matrix engine done
    assign led[15:12] = byte_count;    // which matrix byte is being loaded

endmodule

`default_nettype wire