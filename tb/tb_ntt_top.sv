`timescale 1ns / 1ps

module tb_ntt_top;
    reg clk, rst, start, load_we;
    reg [7:0] load_addr, rd_addr;
    reg [11:0] load_data;
    wire done;
    wire [11:0] rd_data;

    ntt_top uut (
        .clk(clk), .rst(rst), .start(start), .done(done),
        .load_we(load_we), .load_addr(load_addr), .load_data(load_data),
        .rd_addr(rd_addr), .rd_data(rd_data)
    );

    always #5 clk = ~clk;

    reg [11:0] input_poly [0:255];
    integer i, fd, status, cycle_count;

    initial begin
        $dumpfile("sim_output/ntt_waveform.vcd");
        $dumpvars(0, tb_ntt_top);

        clk = 0; rst = 1; start = 0; load_we = 0;
        load_addr = 0; load_data = 0; rd_addr = 0;
        cycle_count = 0;

        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        // 1. Load input from file
        fd = $fopen("sim_output/input.txt", "r");
        if (fd == 0) begin
            $display("Error: input.txt not found");
            $finish;
        end
        for (i = 0; i < 256; i = i + 1)
            status = $fscanf(fd, "%d", input_poly[i]);
        $fclose(fd);
        $display("Input loaded from file.");

        // 2. Load into RAM
        load_we = 1;
        for (i = 0; i < 256; i = i + 1) begin
            load_addr = i[7:0];
            load_data = input_poly[i];
            @(posedge clk); #1;
        end
        load_we = 0;
        @(posedge clk); #1;
        $display("Polynomial loaded into hardware memory.");

        // 3. Start NTT
        start = 1;
        @(posedge clk); #1;
        start = 0;
        $display("NTT calculation started...");

        // 4. Wait for done
        begin : wait_done
            forever begin
                @(posedge clk); #1;
                cycle_count = cycle_count + 1;
                if (done) begin
                    $display("NTT COMPLETED after %0d cycles", cycle_count);
                    disable wait_done;
                end
                if (cycle_count > 10000) begin
                    $display("TIMEOUT");
                    $finish;
                end
            end
        end

        // 5. Wait a few cycles for pipeline to settle
        repeat(5) @(posedge clk);

        // 6. Readback: addr stable BEFORE posedge, read AFTER posedge (1 cycle latency)
        fd = $fopen("sim_output/ntt_out.txt", "w");
        if (fd == 0) begin
            $display("Error: cannot open ntt_out.txt");
            $finish;
        end

        for (i = 0; i < 256; i = i + 1) begin
            rd_addr = i[7:0];   // drive addr
            @(posedge clk); #1; // clock edge — RAM reads this addr
            @(posedge clk); #1; // one more cycle — dout_a now has mem[i]
            $fdisplay(fd, "%0d", rd_data);
        end
        $fclose(fd);
        $display("Output results read from memory.");
        $display("Output written to sim_output/ntt_out.txt");
        $display("PASS - Hardware simulation finished successfully.");
        $finish;
    end
endmodule