`timescale 1ns/1ps

module tb_butterfly;

logic [11:0] a;
logic [11:0] b;
logic [11:0] zeta;

logic [11:0] a_out;
logic [11:0] b_out;

int expected_a;
int expected_b;
int t;

parameter Q = 3329;

// DUT
butterfly dut(
    .a(a),
    .b(b),
    .zeta(zeta),
    .a_out(a_out),
    .b_out(b_out)
);

initial begin
    $dumpfile("tb_butterfly.vcd");
    $dumpvars(0,tb_butterfly);
end


// --------------------------------------
// Compute expected butterfly result
// --------------------------------------

task compute_expected;

    t = (int'(b) * int'(zeta)) % Q;

    expected_a = (a + t) % Q;

    expected_b = a - t;

    if(expected_b < 0)
        expected_b = expected_b + Q;

endtask


// --------------------------------------
// Check DUT outputs
// --------------------------------------

task check;

    if(a_out == expected_a && b_out == expected_b)
        $display("PASS | a=%0d b=%0d zeta=%0d | a_out=%0d b_out=%0d",
                 a,b,zeta,a_out,b_out);
    else
        $display("FAIL | a=%0d b=%0d zeta=%0d | expected (%0d,%0d) got (%0d,%0d)",
                 a,b,zeta,expected_a,expected_b,a_out,b_out);

endtask


// --------------------------------------
// Run single test
// --------------------------------------

task run_test(input int a_in,
              input int b_in,
              input int zeta_in);

    a = a_in;
    b = b_in;
    zeta = zeta_in;

    #10;

    compute_expected();
    check();

endtask


// --------------------------------------
// Test sequence
// --------------------------------------

initial begin

    run_test(10,20,17);
    run_test(100,200,17);
    run_test(3328,3328,17);
    run_test(500,123,289);
    run_test(1000,300,1584);

    #20 $finish;

end

endmodule