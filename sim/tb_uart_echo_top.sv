`timescale 1ns/1ps
`default_nettype none

module tb_uart_echo_top;

    localparam int CLKS_PER_BIT = 32;

    logic clk;
    logic rst;

    logic uart_rx_line;
    logic uart_tx_line;

    logic [15:0] led;

    int pass_count;
    int fail_count;

    uart_echo_top #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .uart_rx(uart_rx_line),
        .uart_tx(uart_tx_line),
        .led(led)
    );

    always #5 clk = ~clk;

    task automatic reset_dut();
        begin
            rst          = 1'b1;
            uart_rx_line = 1'b1;

            repeat (5) @(posedge clk);
            rst = 1'b0;

            repeat (5) @(posedge clk);
            #1;
        end
    endtask

    task automatic drive_uart_byte(input logic [7:0] data);
        int i;

        begin
            @(negedge clk);
            uart_rx_line = 1'b1;
            repeat (CLKS_PER_BIT) @(posedge clk);

            // Start bit
            @(negedge clk);
            uart_rx_line = 1'b0;
            repeat (CLKS_PER_BIT) @(posedge clk);

            // Data bits, LSB first
            for (i = 0; i < 8; i++) begin
                @(negedge clk);
                uart_rx_line = data[i];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end

            // Stop bit
            @(negedge clk);
            uart_rx_line = 1'b1;
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    task automatic read_echoed_uart_byte(output logic [7:0] data);
    int i;

    begin
        data = 8'h00;

        // Wait for the DUT to command the transmitter to start.
        wait(dut.tx_start == 1'b1);

        // uart_tx does not drive the start bit immediately on the same edge
        // that tx_start is asserted. It sees tx_start on the next clock,
        // then drives the start bit on the clock after that.
        //
        // So from tx_start, wait:
        //   2 cycles to reach the beginning of the start bit
        // + 1 full bit period
        // + 1/2 bit period
        //
        // That lands us in the middle of data bit 0.
        repeat (2 + CLKS_PER_BIT + (CLKS_PER_BIT / 2)) @(posedge clk);
        #1;

        for (i = 0; i < 8; i++) begin
            data[i] = uart_tx_line;
            repeat (CLKS_PER_BIT) @(posedge clk);
            #1;
        end

        // Wait through stop bit
        repeat (CLKS_PER_BIT) @(posedge clk);
        #1;
    end
endtask

    task automatic send_and_check_echo(input logic [7:0] expected);
        logic [7:0] echoed;

        begin
            echoed = 8'h00;

            fork
                begin
                    read_echoed_uart_byte(echoed);
                end

                begin
                    // Give the reader a couple cycles to arm itself before
                    // the input byte is driven.
                    repeat (2) @(posedge clk);
                    drive_uart_byte(expected);
                end
            join

            if (echoed == expected) begin
                $display("PASS: sent 0x%02h, echoed 0x%02h", expected, echoed);
                pass_count++;
            end else begin
                $display("FAIL: sent 0x%02h, echoed 0x%02h", expected, echoed);
                fail_count++;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        pass_count = 0;
        fail_count = 0;

        $display("Starting UART echo testbench...");

        reset_dut();

        send_and_check_echo(8'h41); // ASCII 'A'
        send_and_check_echo(8'h55); // alternating pattern
        send_and_check_echo(8'h0A); // newline

        $display("UART echo test completed.");
        $display("Passed: %0d, Failed: %0d", pass_count, fail_count);

        if (fail_count == 0) begin
            $display("ALL UART ECHO TESTS PASSED");
        end else begin
            $display("SOME UART ECHO TESTS FAILED");
        end

        $finish;
    end

endmodule

`default_nettype wire