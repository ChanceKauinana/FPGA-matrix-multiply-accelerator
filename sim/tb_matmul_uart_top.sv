`timescale 1ns/1ps
`default_nettype none

module tb_matmul_uart_top;

    localparam int CLKS_PER_BIT = 32;
    localparam int SEND_LEN = 39;

    logic clk;
    logic rst;

    logic uart_rx_line;
    logic uart_tx_line;

    logic [15:0] led;

    int pass_count;
    int fail_count;

    //DUT

    matmul_uart_top #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .uart_rx(uart_rx_line),
        .uart_tx(uart_tx_line),
        .led(led)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    //Drive 1 UART byte into DUT RX

    task automatic drive_uart_byte(input logic [7:0] data);
        int i;

         begin
             // idle
             uart_rx_line = 1'b1;
             repeat (4) @(negedge clk);

             // start bit
             uart_rx_line = 1'b0;
             repeat (CLKS_PER_BIT) @(negedge clk);

              // data bits, LSB first
              for (i = 0; i < 8; i++) begin
                 uart_rx_line = data[i];
                repeat (CLKS_PER_BIT) @(negedge clk);
              end

            // stop bit
            uart_rx_line = 1'b1;
            repeat (CLKS_PER_BIT) @(negedge clk);

            // gap between bytes
            repeat (4) @(negedge clk);
        end
    endtask

    //Read 1 UART byte fromDUT TX
     
    task automatic read_uart_byte(output logic [7:0] data);
    int i;

    begin
        data = 8'h00;

        // Wait for the design to start transmitting a byte
        @(posedge dut.tx_start);

        // From tx_start, wait until the middle of data bit 0
        repeat (2 + CLKS_PER_BIT + (CLKS_PER_BIT / 2)) @(posedge clk);
        #1;

        // Sample 8 data bits, LSB first
        for (i = 0; i < 8; i++) begin
            data[i] = uart_tx_line;
            repeat (CLKS_PER_BIT) @(posedge clk);
            #1;
        end
    end
endtask


     // ------------------------------------------------------------
    // Expected output:
    // C=00000013 00000016 0000002B 00000032\r\n
    // ------------------------------------------------------------
    function automatic logic [7:0] expected_char(input int index);
        begin
            case (index)
                0:  expected_char = "C";
                1:  expected_char = "=";

                2:  expected_char = "0";
                3:  expected_char = "0";
                4:  expected_char = "0";
                5:  expected_char = "0";
                6:  expected_char = "0";
                7:  expected_char = "0";
                8:  expected_char = "1";
                9:  expected_char = "3";

                10: expected_char = " ";

                11: expected_char = "0";
                12: expected_char = "0";
                13: expected_char = "0";
                14: expected_char = "0";
                15: expected_char = "0";
                16: expected_char = "0";
                17: expected_char = "1";
                18: expected_char = "6";

                19: expected_char = " ";

                20: expected_char = "0";
                21: expected_char = "0";
                22: expected_char = "0";
                23: expected_char = "0";
                24: expected_char = "0";
                25: expected_char = "0";
                26: expected_char = "2";
                27: expected_char = "B";

                28: expected_char = " ";

                29: expected_char = "0";
                30: expected_char = "0";
                31: expected_char = "0";
                32: expected_char = "0";
                33: expected_char = "0";
                34: expected_char = "0";
                35: expected_char = "3";
                36: expected_char = "2";

                37: expected_char = 8'h0D; // carriage return
                38: expected_char = 8'h0A; // newline

                default: expected_char = 8'h00;
            endcase
        end
    endfunction

    //Main Test]
    

    initial begin
    logic [7:0] got;
    logic [7:0] expected;
    int i;

    pass_count = 0;
    fail_count = 0;

    uart_rx_line = 1'b1;
    rst = 1'b1;

    repeat (10) @(posedge clk);
    rst = 1'b0;
    repeat (10) @(posedge clk);

    $display("Starting testbench...");

    fork
        begin
            repeat (500000) @(posedge clk);
            $fatal(1, "TIMEOUT: DUT did not finish UART output");
        end

        begin
            fork
                begin
                    $display("Reading UART output...");

                    for (i = 0; i < SEND_LEN; i++) begin
                        read_uart_byte(got);
                        expected = expected_char(i);

                        if (got === expected) begin
                            $display("PASS: index %0d got %h expected %h",
                                     i, got, expected);
                            pass_count++;
                        end else begin
                            $display("FAIL: index %0d got %h expected %h",
                                     i, got, expected);
                            fail_count++;
                        end
                    end
                end

                begin
                    // Give the reader a few cycles to arm itself first
                    repeat (5) @(posedge clk);

                    $display("Sending matrix input over UART...");

                    drive_uart_byte("0");
                    drive_uart_byte("1");
                    drive_uart_byte("0");
                    drive_uart_byte("2");
                    drive_uart_byte("0");
                    drive_uart_byte("3");
                    drive_uart_byte("0");
                    drive_uart_byte("4");
                    drive_uart_byte("0");
                    drive_uart_byte("5");
                    drive_uart_byte("0");
                    drive_uart_byte("6");
                    drive_uart_byte("0");
                    drive_uart_byte("7");
                    drive_uart_byte("0");
                    drive_uart_byte("8");
                end
            join

            $display("----------------------------------------");
            $display("Pass count: %0d, Fail count: %0d", pass_count, fail_count);
            $display("----------------------------------------");

            if (fail_count == 0) begin
                $display("ALL MATMUL UART TESTS PASSED");
            end else begin
                $fatal(1, "MATMUL UART TEST FAILED");
            end

            $finish;
        end
    join
end
endmodule

`default_nettype wire
