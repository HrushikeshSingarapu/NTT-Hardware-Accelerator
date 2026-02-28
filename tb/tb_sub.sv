module tb_sub;
reg [11:0]a;
reg [11:0]b;
wire [11:0]result;

mod_subtractor dut(.a(a),.b(b),.result(result));

initial begin
    $dumpfile("tb_sub.vcd");
    $dumpvars(0, tb_sub);

    // just below Q — no wrap should happen
    a = 3320; b = 5; #10;
    if (result == 3315) $display("PASS | no wrap");
    else $display("FAIL | no wrap | got=%0d", result);

    // exactly Q — should wrap to 0
    a = 3320; b = 3320; #10;
    if (result == 0) $display("PASS | exact wrap to 0");
    else $display("FAIL | exact wrap to 0 | got=%0d", result);

    // just above Q — should wrap
    a = 3; b = 35; #10;
    if (result == 3297) $display("PASS | wrap above Q");
    else $display("FAIL | wrap above Q | got=%0d", result);

    // max + max
    a = 4090; b = 10; #10;
    if (result == 4080) $display("PASS | max + max");
    else $display("FAIL | max + max | got=%0d", result);

    // both zero
    a = 0; b = 0; #10;
    if (result == 0) $display("PASS | zero + zero");
    else $display("FAIL | zero + zero | got=%0d", result);

    #50 $finish;
end
endmodule