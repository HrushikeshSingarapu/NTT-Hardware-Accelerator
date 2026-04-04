`timescale 1ns/1ps

module tb_ntt_top;

    logic        clk, rst, start, done;
    logic        load_we;
    logic [7:0]  load_addr;
    logic [11:0] load_data;
    logic [7:0]  rd_addr;
    logic [11:0] rd_data;

    ntt_top dut (.*);

    always #5 clk = ~clk;

    logic [11:0] input_poly  [0:255];
    logic [11:0] output_poly [0:255];

    integer i, fd, errors;
    initial errors = 0;

    initial begin
        clk = 0; rst = 1;
        start = 0; load_we = 0;
        load_addr = 0; load_data = 0;
        rd_addr = 0;

        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        fd = $fopen("sim_output/input.txt", "r");
        if (fd == 0) begin
            $display("ERROR: cannot open input.txt");
            $finish;
        end
        for (i = 0; i < 256; i++)
            $fscanf(fd, "%d\n", input_poly[i]);
        $fclose(fd);
        $display("Input loaded.");

        load_we = 1;
        for (i = 0; i < 256; i++) begin
            load_addr = i[7:0];
            load_data = input_poly[i];
            @(posedge clk); #1;
        end
        load_we = 0;
        $display("Polynomial loaded into memory.");

        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;
        $display("NTT running...");

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
                repeat(20000) @(posedge clk);
                $display("TIMEOUT");
                errors++;
                disable wait_done;
            end
        join

        repeat(3) @(posedge clk);

        for (i = 0; i < 256; i++) begin
            rd_addr = i[7:0];
            @(posedge clk); #1;
            output_poly[i] = rd_data;
        end
        $display("Output read from memory.");

        fd = $fopen("sim_output/ntt_out.txt", "w");
        if (fd == 0) begin
            $display("ERROR: cannot open ntt_out.txt");
            $finish;
        end
        for (i = 0; i < 256; i++)
            $fdisplay(fd, "%0d", output_poly[i]);
        $fclose(fd);
        $display("Output written to sim_output/ntt_out.txt");

        if (errors == 0)
            $display("PASS — simulation complete");
        else
            $display("FAIL — %0d errors", errors);

        $finish;
    end

endmodule