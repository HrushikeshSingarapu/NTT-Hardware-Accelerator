`timescale 1ns/1ps

module tb_addr_gen;

    logic       clk, rst, start;
    logic [7:0] addr_a, addr_b;
    logic [6:0] twiddle_addr;
    logic       valid, done;

    addr_gen dut (.*);

    always #5 clk = ~clk;

    integer errors = 0;
    integer count  = 0;

    initial begin
        clk = 0; rst = 1; start = 0;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        start = 1;
        @(posedge clk); #1;
        start = 0;

        $display("addr_a | addr_b | twiddle");
        $display("-------+--------+--------");

        begin : monitor_loop
            forever begin
                @(posedge clk); #1;
                if (valid) begin
                    $display(" %4d  |  %4d  |  %4d",
                              addr_a, addr_b, twiddle_addr);

                    if (addr_b <= addr_a) begin
                        $display("ERROR: addr_b <= addr_a");
                        errors++;
                    end
                    if (addr_b > 255) begin
                        $display("ERROR: addr_b %0d out of range", addr_b);
                        errors++;
                    end
                    if (twiddle_addr > 127) begin
                        $display("ERROR: twiddle_addr %0d out of range", twiddle_addr);
                        errors++;
                    end
                    count++;
                end
                if (done) begin
                    $display("--- DONE --- total butterflies: %0d", count);
                    disable monitor_loop;
                end
            end
        end

        if (errors == 0)
            $display("PASS");
        else
            $display("FAIL — %0d errors", errors);

        $finish;
    end

endmodule