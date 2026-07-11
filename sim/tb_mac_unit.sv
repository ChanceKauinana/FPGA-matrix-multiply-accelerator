`timescale 1ns/1ps
`default_nettype none

module tb_mac_unit;

    logic        clk;
    logic        rst;
    logic        clear;
    logic       enable;
    logic signed [7:0] a;
    logic signed [7:0] b;

    logic signed [31:0] result;

    mac_unit #(
    .A_WIDTH (8),
    .B_WIDTH  (8),
    .ACC_WIDTH (32)
    )dut(
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .enable(enable),
        .a(a),
        .b(b),
        .result(result)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        clear = 1'b0;
        enable = 1'b0;
        a = '0;
        b = '0;

        repeat(2) @(posedge clk);
        rst = 1'b0;
        clear = 1'b1;
        @(posedge clk);
        clear = 1'b0;
        enable = 1'b1;

        a = 8'sd2;
        b = 8'sd3;
        @(posedge clk);
    
        a = -8'sd4;
        b = 8'sd5;
        @(posedge clk);
        #1;

        enable = 1'b0;
        @(posedge clk);
        
        enable = 1'b0;
        a = 8'sd10;
        b = 8'sd10;
        @(posedge clk);
        #1;

        if (result == -32'sd14) begin
            $display("Test Passed: result = %0d", result);
        end else begin
            $display("Test Failed: result = %0d", result);
        end
        if (result != -32'sd14) begin
            $display ("Test Failed: enable hold fail");
        end
        
        clear = 1'b1;
        @(posedge clk);
        #1;
        
        clear = 1'b0;
        if (result != 32'sd0) begin
        $display ("Clear enable failed");
        end
        
        enable = 1'b1;
        a = -8'sd10;
        b = -8'sd10;
        
        @(posedge clk);
        #1;
        
        if (result != 100) begin
            $display ("Negative multiplication failed");
            end
        $finish;
    end
endmodule

`default_nettype wire
