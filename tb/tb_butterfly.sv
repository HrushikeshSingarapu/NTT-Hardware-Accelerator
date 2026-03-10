`timescale 1ns/1ps

module tb_butterfly;

    reg  [11:0] a, b, zeta;
    wire [11:0] a_out, b_out;

    butterfly dut (
        .a(a),
        .b(b),
        .zeta(zeta),
        .a_out(a_out),
        .b_out(b_out)
    );

    initial begin
        $dumpfile("tb_butterfly.vcd");
        $dumpvars(0, tb_butterfly);

        // both outputs must be in range 0 to 3328
        // a_out = a + (zeta*b) mod q
        // b_out = a - (zeta*b) mod q

        // test 1: zeros
        a = 0; b = 0; zeta = 0; #10;
        if (a_out >= 3329 || b_out >= 3329)
            $display("FAIL | test1 | a_out=%0d b_out=%0d", a_out, b_out);
        else
            $display("PASS | test1 zeros | a_out=%0d b_out=%0d", a_out, b_out);

        // test 2: simple values
        a = 100; b = 200; zeta = 17; #10;
        if (a_out >= 3329 || b_out >= 3329)
            $display("FAIL | test2 | a_out=%0d b_out=%0d", a_out, b_out);
        else
            $display("PASS | test2 zeta=17 | a_out=%0d b_out=%0d", a_out, b_out);

        // test 3: max values
        a = 3328; b = 3328; zeta = 3328; #10;
        if (a_out >= 3329 || b_out >= 3329)
            $display("FAIL | test3 | a_out=%0d b_out=%0d", a_out, b_out);
        else
            $display("PASS | test3 max | a_out=%0d b_out=%0d", a_out, b_out);

        // test 4: zeta = 1 (t = b, so a_out = a+b, b_out = a-b)
        a = 500; b = 300; zeta = 1; #10;
        if (a_out >= 3329 || b_out >= 3329)
            $display("FAIL | test4 | a_out=%0d b_out=%0d", a_out, b_out);
        else
            $display("PASS | test4 zeta=1 | a_out=%0d b_out=%0d", a_out, b_out);

        // test 5: a=0 b=0 zeta=max
        a = 0; b = 0; zeta = 3328; #10;
        if (a_out >= 3329 || b_out >= 3329)
            $display("FAIL | test5 | a_out=%0d b_out=%0d", a_out, b_out);
        else
            $display("PASS | test5 | a_out=%0d b_out=%0d", a_out, b_out);

        #50 $finish;
    end

endmodule