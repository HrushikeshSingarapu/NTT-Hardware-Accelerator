`timescale 1ns/1ps

module tb_twiddle_rom;

    reg  [6:0]  addr;
    wire [11:0] data;
    integer i;          // ← integer for loop counter, not reg

    twiddle_rom dut (
        .addr(addr),
        .data(data)
    );

    initial begin
        $dumpfile("tb_twiddle_rom.vcd");
        $dumpvars(0, tb_twiddle_rom);

        // check all 128 values are in range
        for (i = 0; i < 128; i = i + 1) begin
            addr = i; #10;
            if (data >= 3329)
                $display("FAIL | addr=%0d | data=%0d out of range", addr, data);
        end

        // check addr=0 → 1
        addr = 0; #10;
        if (data == 1)
            $display("PASS | addr=0 | data=%0d", data);
        else
            $display("FAIL | addr=0 | expected=1 got=%0d", data);

        // check addr=64 → 17
        addr = 64; #10;
        if (data == 17)
            $display("PASS | addr=64 | data=%0d", data);
        else
            $display("FAIL | addr=64 | expected=17 got=%0d", data);

        $display("PASS | all range checks done");
        #50 $finish;
    end

endmodule