`timescale 1ns/1ps
`default_nettype none

module tb_uart_tx;

    localparam int CLKS_PER_BIT = 4;

    logic clk;
    logic rst;

    logic tx_start;
    logic [7:0] tx_data;

    logic tx;
    logic tx_busy;
    logic tx_done;

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    always #5 clk = ~clk;

    task automatic reset_dut();
        begin
            rst      = 1'b1;
            tx_start = 1'b0;
            tx_data  = 8'h00;

            repeat (3) @(posedge clk);
            rst = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    task automatic send_byte(input logic [7:0] data);
        begin
            @(negedge clk);
            tx_data  = data;
            tx_start = 1'b1;

            @(negedge clk);
            tx_start = 1'b0;

            wait(tx_done);
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        clk = 1'b0;

        $display("Starting UART TX testbench...");

        reset_dut();

        send_byte(8'h41); // ASCII 'A'
        $display("Sent byte: 0x%02h", tx_data);

        send_byte(8'h55); // 01010101
        $display("Sent byte: 0x%02h", tx_data);

        send_byte(8'h0A); // newline
        $display("Sent byte: 0x%02h", tx_data);

        $display("UART TX test completed.");
        $finish;
    end

endmodule

`default_nettype wire