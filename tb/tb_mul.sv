


module tb_mul;

    reg  [11:0] a;
    reg  [11:0] b;
    wire [11:0] y;

    mod_multiplier dut (
        .a(a),
        .b(b),
        .y(y)
    );

    initial begin
        $dumpfile("tb_mul.vcd");
        $dumpvars(0, tb_mul);

        // both zero
        a = 0; b = 0; #10;
        if (y == (a * b) % 3329) $display("PASS | a=%0d b=%0d | y=%0d", a, b, y);
        else $display("FAIL | a=%0d b=%0d | expected=%0d got=%0d", a, b, (a*b)%3329, y);

        // one zero
        a = 3328; b = 0; #10;
        if (y == (a * b) % 3329) $display("PASS | a=%0d b=%0d | y=%0d", a, b, y);
        else $display("FAIL | a=%0d b=%0d | expected=%0d got=%0d", a, b, (a*b)%3329, y);

        // max * max
        a = 3328; b = 3328; #10;
        if (y == (a * b) % 3329) $display("PASS | a=%0d b=%0d | y=%0d", a, b, y);
        else $display("FAIL | a=%0d b=%0d | expected=%0d got=%0d", a, b, (a*b)%3329, y);

        // small values
        a = 17; b = 17; #10;
        if (y == (a * b) % 3329) $display("PASS | a=%0d b=%0d | y=%0d", a, b, y);
        else $display("FAIL | a=%0d b=%0d | expected=%0d got=%0d", a, b, (a*b)%3329, y);

        // result in range check
        a = 475; b = 7; #10;
        if (y >= 3329) $display("FAIL | out of range | got=%0d", y);
        else $display("PASS | in range | y=%0d", y);

        #50 $finish;
    end
endmodule