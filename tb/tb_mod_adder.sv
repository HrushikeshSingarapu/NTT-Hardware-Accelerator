module tb_mod_adder;
reg [11:0]a;
reg [11:0]b;
wire [11:0]result;

mod_adder dut(.a(a),.b(b),.result(result));

initial begin
    $dumpfile("tb_mod_adder.vcd");
    $dumpvars(0, tb_mod_adder);

    // just below Q — no wrap should happen
    a = 3328; b = 0; #10;
    if (result == 3328) $display("PASS | no wrap");
    else $display("FAIL | no wrap | got=%0d", result);

    // exactly Q — should wrap to 0
    a = 3000; b = 329; #10;
    if (result == 0) $display("PASS | exact wrap to 0");
    else $display("FAIL | exact wrap to 0 | got=%0d", result);

    // just above Q — should wrap
    a = 3000; b = 330; #10;
    if (result == 1) $display("PASS | wrap above Q");
    else $display("FAIL | wrap above Q | got=%0d", result);

    // max + max
    a = 3328; b = 3328; #10;
    if (result == 3327) $display("PASS | max + max");
    else $display("FAIL | max + max | got=%0d", result);

    // both zero
    a = 0; b = 0; #10;
    if (result == 0) $display("PASS | zero + zero");
    else $display("FAIL | zero + zero | got=%0d", result);

    #50 $finish;
end
endmodule