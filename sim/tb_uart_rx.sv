`timescale 1ns/1ps
`default_nettype none

module tb_uart_rx;

    localparam int CLKS_PER_BIT = 4;

    logic clk;
    logic rst;

    logic rx;

    logic [7:0] rx_data;
    logic       rx_busy;
    logic       rx_done;

    int pass_count;
    int fail_count;

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .rx_data(rx_data),
        .rx_busy(rx_busy),
        .rx_done(rx_done)
    );

    always #5 clk = ~clk;

    task automatic reset_dut();
        begin
            rst = 1'b1;
            rx  = 1'b1;

            repeat (3) @(posedge clk);
            rst = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    task automatic drive_uart_byte(input logic [7:0] data);
        int i;

        begin
            // Idle before frame
            @(negedge clk);
            rx = 1'b1;
            repeat (CLKS_PER_BIT) @(posedge clk);

            // Start bit
            @(negedge clk);
            rx = 1'b0;
            repeat (CLKS_PER_BIT) @(posedge clk);

            // Data bits, LSB first
            for (i = 0; i < 8; i++) begin
                @(negedge clk);
                rx = data[i];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end

            // Stop bit
            @(negedge clk);
            rx = 1'b1;
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    task automatic send_and_check(input logic [7:0] expected);
        begin
            drive_uart_byte(expected);

            wait(rx_done);
            @(posedge clk);
            #1;

            if (rx_data == expected) begin
                $display("PASS: received 0x%02h", rx_data);
                pass_count++;
            end else begin
                $display("FAIL: expected 0x%02h, got 0x%02h", expected, rx_data);
                fail_count++;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        pass_count = 0;
        fail_count = 0;

        $display("Starting UART RX testbench...");

        reset_dut();

        send_and_check(8'h41); // ASCII 'A'
        send_and_check(8'h55); // alternating pattern
        send_and_check(8'h0A); // newline

        $display("UART RX test completed.");
        $display("Passed: %0d, Failed: %0d", pass_count, fail_count);

        if (fail_count == 0) begin
            $display("ALL UART RX TESTS PASSED");
        end else begin
            $display("SOME UART RX TESTS FAILED");
        end

        $finish;
    end

endmodule

`default_nettype wire