`timescale 1ns/1ps
`default_nettype none

module tb_dot_product_engine;

    logic        clk;
    logic        rst;
    logic        start;
    logic        valid_in;

    logic signed [7:0] a;
    logic signed [7:0] b;

    logic        busy;
    logic        done;
    logic signed [31:0] result;
    logic signed [31:0] expected_result;

    int pass_count;
    int fail_count;


    dot_product_engine #(
    .DATA_WIDTH (8),
    .ACC_WIDTH  (32),
    .VECTOR_SIZE (4)
    )dut(
        .clk(clk),
        .rst(rst),
        .start(start),
        .valid_in(valid_in),
        .a(a),
        .b(b),
        .busy(busy),
        .done(done),
        .result(result)
    );

    always #10 clk = ~clk;

    task reset_dut();
        begin
            rst = 1'b1;
            start = 1'b0;
            valid_in = 1'b0;
            a = '0;
            b = '0;
            expected_result = '0;

            repeat(2) @(posedge clk);
            rst = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    task pulse_start();
        begin
            @(negedge clk);
            start = 1'b1;

            @(posedge clk);
            #1;

            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task send_pair(
        input logic signed [7:0] a_val,
        input logic signed [7:0] b_val
    );
        begin
            @(negedge clk);
            a = a_val;
            b = b_val;
            valid_in = 1'b1;
            expected_result = expected_result + (a_val * b_val);

            @(posedge clk);
            #1;

            $display ("Sent pair: a = %0d, b = %0d, expected_result = %0d, actual result = %0d", 
                       a_val, b_val, expected_result, result);

            @(negedge clk);
            valid_in = 1'b0;
        end
    endtask

    task check_result(input logic signed [31:0] expected_value);
        begin
            if (result == expected_value) begin
                $display("Test Passed: result = %0d", result);
                pass_count++;
            end else begin
                $display("Test Failed: expected = %0d, got = %0d", expected_value, result);
                fail_count++;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        pass_count = 0;
        fail_count = 0;

        $display("Starting dot product engine testbench...");

        reset_dut();

        pulse_start();
        send_pair(8'sd1, 8'sd5);
        send_pair(8'sd2, 8'sd6);
        send_pair(8'sd3, 8'sd7);
        send_pair(8'sd4, 8'sd8);

        wait(done);
        #1;

        check_result(32'sd70);
        
        reset_dut();
        pulse_start();
        send_pair(-8'sd1,  8'sd5);   // -5
        send_pair( 8'sd2, -8'sd6);   // -12
        send_pair(-8'sd3,  8'sd7);   // -21
        send_pair( 8'sd4, -8'sd8);   // -32
        
        wait(done);
        #1;

        $finish;
    end





endmodule
