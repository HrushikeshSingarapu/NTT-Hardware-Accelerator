`timescale 1ns/1ps

module addr_gen (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic        en,
    output logic [7:0]  addr_a,
    output logic [7:0]  addr_b,
    output logic [6:0]  twiddle_addr,
    output logic        valid,
    output logic        done
);

    logic [2:0] stage;
    logic [6:0] butterfly;
    logic       running;

    logic [7:0] step;
    assign step = 8'd128 >> stage;

    logic [6:0] group;
    logic [6:0] offset;
    assign group  = butterfly / step;
    assign offset = butterfly % step;

    assign addr_a       = (group * (step << 1)) + offset;
    assign addr_b       = addr_a + step;
    assign twiddle_addr = (7'd1 << stage) + group;
    assign valid        = running;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            stage     <= 3'd0;
            butterfly <= 7'd0;
            running   <= 1'b0;
            done      <= 1'b0;
        end
        else begin
            done <= 1'b0;
            if (start) begin
                stage     <= 3'd0;
                butterfly <= 7'd0;
                running   <= 1'b1;
            end
            else if (running && en) begin
                if (butterfly == 7'd127) begin
                    butterfly <= 7'd0;
                    if (stage == 3'd6) begin
                        running <= 1'b0;
                        done    <= 1'b1;
                    end
                    else begin
                        stage <= stage + 3'd1;
                    end
                end
                else begin
                    butterfly <= butterfly + 7'd1;
                end
            end
        end
    end

endmodule