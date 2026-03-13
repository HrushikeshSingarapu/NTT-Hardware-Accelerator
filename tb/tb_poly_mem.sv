`timescale 1ns/1ps

module tb_poly_mem;

    reg         clk;
    reg         we;
    reg  [7:0]  addr_a, addr_b;
    reg  [11:0] data_in_a, data_in_b;
    wire [11:0] data_out_a, data_out_b;

    poly_mem dut (
        .clk(clk),
        .we(we),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .data_in_a(data_in_a),
        .data_in_b(data_in_b),
        .data_out_a(data_out_a),
        .data_out_b(data_out_b)
    );

    // clock generator
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_poly_mem.vcd");
        $dumpvars(0, tb_poly_mem);

        clk = 0; we = 0;
        addr_a = 0; addr_b = 0;
        data_in_a = 0; data_in_b = 0;

        // test 1: write two values
        we = 1;
        addr_a = 8'd0;  data_in_a = 12'd100;
        addr_b = 8'd1;  data_in_b = 12'd200;
        @(posedge clk); #1;

        // test 2: read them back
        we = 0;
        addr_a = 8'd0;
        addr_b = 8'd1;
        @(posedge clk); #1;

        if (data_out_a == 12'd100 && data_out_b == 12'd200)
            $display("PASS | test1 | read back correct | a=%0d b=%0d", data_out_a, data_out_b);
        else
            $display("FAIL | test1 | a=%0d b=%0d", data_out_a, data_out_b);

        // test 3: write to high addresses
        we = 1;
        addr_a = 8'd254; data_in_a = 12'd3328;
        addr_b = 8'd255; data_in_b = 12'd1729;
        @(posedge clk); #1;

        // read back high addresses
        we = 0;
        addr_a = 8'd254;
        addr_b = 8'd255;
        @(posedge clk); #1;

        if (data_out_a == 12'd3328 && data_out_b == 12'd1729)
            $display("PASS | test2 | high addr correct | a=%0d b=%0d", data_out_a, data_out_b);
        else
            $display("FAIL | test2 | a=%0d b=%0d", data_out_a, data_out_b);

        // test 4: overwrite and check
        we = 1;
        addr_a = 8'd0; data_in_a = 12'd999;
        addr_b = 8'd1; data_in_b = 12'd888;
        @(posedge clk); #1;

        we = 0;
        addr_a = 8'd0;
        addr_b = 8'd1;
        @(posedge clk); #1;

        if (data_out_a == 12'd999 && data_out_b == 12'd888)
            $display("PASS | test3 | overwrite correct | a=%0d b=%0d", data_out_a, data_out_b);
        else
            $display("FAIL | test3 | a=%0d b=%0d", data_out_a, data_out_b);

        #50 $finish;
    end

endmodule