`timescale 1ns/1ps

module tb_ntt_top;

    logic        clk, rst, start, done;
    logic        load_we;
    logic [7:0]  load_addr;
    logic [11:0] load_data;

    ntt_top dut (.*);

    always #5 clk = ~clk;

    task load_poly;
        integer i;
        begin
            load_we = 1'b1;
            for (i = 0; i < 256; i++) begin
                load_addr = i[7:0];
                load_data = 12'd1;
                @(posedge clk); #1;
            end
            load_we = 1'b0;
        end
    endtask

    integer errors = 0;

    initial begin
        clk = 0; rst = 1;
        start = 0; load_we = 0;
        load_addr = 0; load_data = 0;

        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        $display("Loading polynomial...");
        load_poly();
        $display("Load done.");

        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        $display("NTT running...");

        // timeout after 2000 cycles
        fork
            begin : wait_done
                forever begin
                    @(posedge clk); #1;
                    if (done) begin
                        $display("NTT DONE.");
                        disable wait_done;
                    end
                end
            end
            begin : timeout
                repeat(2000) @(posedge clk);
                $display("TIMEOUT — done never asserted");
                errors++;
                disable wait_done;
            end
        join

        if (dut.data_out_a === 12'bx) begin
            $display("ERROR: output is x");
            errors++;
        end

        if (errors == 0)
            $display("PASS — NTT completed");
        else
            $display("FAIL — %0d errors", errors);

        $finish;
    end

endmodule