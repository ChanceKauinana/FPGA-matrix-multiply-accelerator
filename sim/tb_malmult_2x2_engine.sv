`timescale 1ns/1ps
`default_nettype none

module tb_malmult_2x2_engine;

    logic        clk;
    logic        rst;
    logic        start;

    logic signed [7:0] a00;
    logic signed [7:0] a01;
    logic signed [7:0] a10;
    logic signed [7:0] a11;

    logic signed [7:0] b00;
    logic signed [7:0] b01;
    logic signed [7:0] b10;
    logic signed [7:0] b11;

    logic        busy;
    logic        done;

    logic signed [31:0] c00;
    logic signed [31:0] c01;
    logic signed [31:0] c10;
    logic signed [31:0] c11;

    logic signed [31:0] expected_c00;
    logic signed [31:0] expected_c01;
    logic signed [31:0] expected_c10;
    logic signed [31:0] expected_c11;

    int pass_count;
    int fail_count;


    malmult_2x2_engine #(
    .DATA_WIDTH (8),
    .ACC_WIDTH  (32)
    )dut(
        .clk(clk),
        .rst(rst),
        .start(start),
        .a00(a00),
        .a01(a01),
        .a10(a10),
        .a11(a11),
        .b00(b00),
        .b01(b01),
        .b10(b10),
        .b11(b11),
        .busy(busy),
        .done(done),
        .c00(c00),
        .c01(c01),
        .c10(c10),
        .c11(c11)
    );

    always #10 clk = ~clk;

    task reset_dut();
        begin
            rst = 1'b1;
            start = 1'b0;

            a00 = '0;
            a01 = '0;
            a10 = '0;
            a11 = '0;

            b00 = '0;
            b01 = '0;
            b10 = '0;
            b11 = '0;

            repeat(2) @(posedge clk);
            rst = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    task load_matrices(
        input logic signed [7:0] a00_in,
        input logic signed [7:0] a01_in,
        input logic signed [7:0] a10_in,
        input logic signed [7:0] a11_in,
        input logic signed [7:0] b00_in,
        input logic signed [7:0] b01_in,
        input logic signed [7:0] b10_in,
        input logic signed [7:0] b11_in
    );
        begin
            @(negedge clk);
            a00 = a00_in;
            a01 = a01_in;
            a10 = a10_in;
            a11 = a11_in;

            b00 = b00_in;
            b01 = b01_in;
            b10 = b10_in;
            b11 = b11_in;

            expected_c00 = (a00_in * b00_in) + (a01_in * b10_in);
            expected_c01 = (a00_in * b01_in) + (a01_in * b11_in);
            expected_c10 = (a10_in * b00_in) + (a11_in * b10_in);
            expected_c11 = (a10_in * b01_in) + (a11_in * b11_in);
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

    task check_matrix;
        begin
            if ((c00 == expected_c00) &&
                (c01 == expected_c01) &&
                (c10 == expected_c10) &&
                (c11 == expected_c11)) begin
                $display("Test PASSED: c00 = %0d, c01 = %0d, c10 = %0d, c11 = %0d", c00, c01, c10, c11);
                pass_count++;
            end else begin
                $display("Test FAILED: Expected: c00 = %0d, c01 = %0d, c10 = %0d, c11 = %0d | Got: c00 = %0d, c01 = %0d, c10 = %0d, c11 = %0d",
                         expected_c00, expected_c01, expected_c10, expected_c11,
                         c00, c01, c10, c11);
                fail_count++;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        pass_count = 0;
        fail_count = 0;

        $display("Starting testbench for malmult_2x2_engine...");

        //Test Case 1: 
        // A = [1 2]
        //     [3 4]
        //
        // B = [5 6]
        //     [7 8]
        //
        // Expected:
        // C = [19 22]
        //     [43 50]

        reset_dut();
        load_matrices(
            8'sd1, 8'sd2, 
            8'sd3, 8'sd4,

            8'sd5, 8'sd6,
            8'sd7, 8'sd8
        );

        pulse_start();

        wait(done);
        #1;

        check_matrix();

        //Test Case 2:
        // A = [-1 -2]
        //     [-3 -4]
        //
        // B = [5 6]
        //     [7 8]
        //
        // Expected:
        // C = [-19 -22]
        //     [-43 -50]

        reset_dut();
        load_matrices(
            -8'sd1, -8'sd2, 
            -8'sd3, -8'sd4,

            8'sd5, 8'sd6,
            8'sd7, 8'sd8
        );

        pulse_start();
        wait(done);
        #1;

        check_matrix();

        $display("Testbench completed. Passed: %0d, Failed: %0d", pass_count, fail_count);
        $finish;
    end
endmodule

`default_nettype wire