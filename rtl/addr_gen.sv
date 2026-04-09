`timescale 1ns/1ps

module addr_gen (
    input  logic        clk, rst, start, en,
    output logic [7:0]  addr_a, addr_b,
    output logic [6:0]  twiddle_addr,
    output logic        valid, done
);

    logic [9:0] counter; 
    logic       running;
    logic [2:0] stage;
    logic [6:0] bf_num;
    
    assign stage  = counter[9:7];
    assign bf_num = counter[6:0];
    
    logic [7:0] length;
    assign length = 8'd128 >> stage;
    
    // Pure bitwise math to prevent iverilog slice/division crashes
    logic [6:0] group;
    logic [6:0] offset;
    assign group  = bf_num >> (3'd7 - stage);
    assign offset = bf_num & (length - 8'd1);
    
    logic [8:0] start_pos;
    assign start_pos = group * (length << 1);
    
    assign addr_a = start_pos[7:0] + offset;
    assign addr_b = addr_a + length;
    
    logic [6:0] k_base;
    always_comb begin
        case(stage)
            3'd0: k_base = 7'd1;  3'd1: k_base = 7'd2;
            3'd2: k_base = 7'd4;  3'd3: k_base = 7'd8;
            3'd4: k_base = 7'd16; 3'd5: k_base = 7'd32;
            3'd6: k_base = 7'd64; default: k_base = 7'd0;
        endcase
    end
    assign twiddle_addr = k_base + group;
    
    assign valid = running;
    assign done  = (counter == 10'd895);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0; running <= 0;
        end else begin
            if (start) begin
                counter <= 0; running <= 1;
            end else if (running && en) begin
                if (counter == 10'd895) running <= 0;
                else counter <= counter + 1;
            end
        end
    end
endmodule