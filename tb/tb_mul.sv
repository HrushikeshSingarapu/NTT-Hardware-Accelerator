


module tb_mul;

    reg  [11:0] a;
    reg  [11:0] b;
    wire [11:0] result;

    mod_multiplier dut (
        .a(a),
        .b(b),
        .result(result)
    );

    initial begin
        $dumpfile("tb_mul.vcd");
        $dumpvars(0, tb_mul);

        // both zero
        a = 0; b = 0; #10;
        if (result == (a * b) % 3329) $display("PASS | a=%0d b=%0d |result=%0d", a, b,result);
        else $display("FAIL | a=%0d b=%0d | expected=%0d got=%0d", a, b, (a*b)%3329,result);

        // one zero
        a = 3328; b = 0; #10;
        if (result == (a * b) % 3329) $display("PASS | a=%0d b=%0d |result=%0d", a, b,result);
        else $display("FAIL | a=%0d b=%0d | expected=%0d got=%0d", a, b, (a*b)%3329,result);

        // max * max
        a = 3328; b = 3328; #10;
        if (result == (a * b) % 3329) $display("PASS | a=%0d b=%0d |result=%0d", a, b,result);
        else $display("FAIL | a=%0d b=%0d | expected=%0d got=%0d", a, b, (a*b)%3329,result);

        // small values
        a = 17; b = 17; #10;
        if (result == (a * b) % 3329) $display("PASS | a=%0d b=%0d |result=%0d", a, b,result);
        else $display("FAIL | a=%0d b=%0d | expected=%0d got=%0d", a, b, (a*b)%3329,result);

        // result in range check
        a = 475; b = 7; #10;
        if (result >= 3329) $display("FAIL | out of range | got=%0d",result);
        else $display("PASS | in range |result=%0d",result);

        #50 $finish;
    end
endmodule