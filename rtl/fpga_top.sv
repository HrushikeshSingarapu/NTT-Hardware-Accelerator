`timescale 1ns/1ps
module fpga_top (
    input  wire        clk,      // 100 MHz Basys 3 clock
    input  wire        btnC,     // center button = reset
    input  wire        RsRx,     // USB UART RX (from PC)
    output wire        RsTx,     // USB UART TX (to PC)
    output wire [15:0] led       // status
);

    // ── Reset ─────────────────────────────────────
    wire rst = btnC;

    // ── UART (100MHz, 115200 baud → 868 clks/bit) ─
    wire       rx_valid;
    wire [7:0] rx_byte;

    uart_rx #(.CLKS_PER_BIT(868)) urx (
        .clk(clk), .rst(rst),
        .rx(RsRx),
        .data_valid(rx_valid),
        .data(rx_byte)
    );

    reg        tx_start;
    reg  [7:0] tx_byte_reg;
    wire       tx_busy;

    uart_tx #(.CLKS_PER_BIT(868)) utx (
        .clk(clk), .rst(rst),
        .start(tx_start),
        .data(tx_byte_reg),
        .tx(RsTx),
        .busy(tx_busy)
    );

    // ── NTT ───────────────────────────────────────
    reg        ntt_start;
    wire       ntt_done;
    reg        load_we;
    reg  [7:0] load_addr;
    reg  [11:0] load_data_reg;
    reg  [7:0]  rd_addr;
    wire [11:0] rd_data;

    ntt_top ntt_inst (
        .clk(clk), .rst(rst),
        .start(ntt_start), .done(ntt_done),
        .load_we(load_we),
        .load_addr(load_addr),
        .load_data(load_data_reg),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

    // ── Cycle Counter (measures NTT hardware time) ─
    reg [31:0] cycle_counter;
    reg [31:0] ntt_cycles;     // captured when done
    reg        counting;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle_counter <= 0;
            ntt_cycles    <= 0;
            counting      <= 0;
        end
        else begin
            if (ntt_start) begin
                cycle_counter <= 0;
                counting      <= 1;
            end
             if (counting) begin
                if (ntt_done) begin
                    ntt_cycles <= cycle_counter;
                    counting   <= 0;
                end
                else
                    cycle_counter <= cycle_counter + 1;
            end
        end
    end

    // ── Receive Buffer ─────────────────────────────
    // 256 coefficients x 12 bits each
    // Protocol: send 2 bytes per coefficient
    //   byte 0 = bits [7:0]
    //   byte 1 = bits [11:8] in lower nibble
    reg [11:0] coeff_buf [0:255];
    reg [8:0]  rx_count;   // 0..511

    // ── FSM ───────────────────────────────────────
    localparam ST_IDLE      = 4'd0;
    localparam ST_RECV      = 4'd1;
    localparam ST_LOAD      = 4'd2;
    localparam ST_START_NTT = 4'd3;
    localparam ST_WAIT_DONE = 4'd4;
    localparam ST_READBACK  = 4'd5;
    localparam ST_SEND_LO   = 4'd6;
    localparam ST_SEND_HI   = 4'd7;
    localparam ST_SEND_CYC  = 4'd8;  // send 4-byte cycle count
    localparam ST_DONE      = 4'd9;

    reg [3:0]  state;
    reg [7:0]  coeff_idx;
    reg [1:0]  cyc_byte;     // which byte of cycle count sending
    reg [11:0] rd_data_latch;
    reg        rd_wait;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= ST_IDLE;
            rx_count   <= 0;
            coeff_idx  <= 0;
            load_we    <= 0;
            ntt_start  <= 0;
            tx_start   <= 0;
            rd_addr    <= 0;
            rd_wait    <= 0;
            cyc_byte   <= 0;
        end
        else begin
            ntt_start <= 0;
            load_we   <= 0;
            tx_start  <= 0;

            case (state)

                ST_IDLE: begin
                    rx_count  <= 0;
                    coeff_idx <= 0;
                    if (rx_valid) begin
                        // first byte arrived
                        coeff_buf[0][7:0] <= rx_byte;
                        rx_count          <= 1;
                        state             <= ST_RECV;
                    end
                end

                ST_RECV: begin
                    if (rx_valid) begin
                        if (rx_count[0] == 1'b0)
                            coeff_buf[rx_count[8:1]][7:0]  <= rx_byte;
                        else
                            coeff_buf[rx_count[8:1]][11:8] <= rx_byte[3:0];

                        if (rx_count == 511) begin
                            coeff_idx <= 0;
                            state     <= ST_LOAD;
                        end
                        else
                            rx_count <= rx_count + 1;
                    end
                end

                ST_LOAD: begin
                    load_we        <= 1;
                    load_addr      <= coeff_idx;
                    load_data_reg  <= coeff_buf[coeff_idx];
                    if (coeff_idx == 255)
                        state <= ST_START_NTT;
                    else
                        coeff_idx <= coeff_idx + 1;
                end

                ST_START_NTT: begin
                    ntt_start <= 1;
                    state     <= ST_WAIT_DONE;
                end

                ST_WAIT_DONE: begin
                    if (ntt_done) begin
                        coeff_idx <= 0;
                        rd_addr   <= 0;
                        rd_wait   <= 0;
                        state     <= ST_READBACK;
                    end
                end

                // read one coefficient: drive addr, wait 2 cycles, latch
                ST_READBACK: begin
                    rd_addr <= coeff_idx;
                    if (rd_wait) begin
                        rd_data_latch <= rd_data;
                        rd_wait       <= 0;
                        state         <= ST_SEND_LO;
                    end
                    else
                        rd_wait <= 1;
                end

                ST_SEND_LO: begin
                    if (!tx_busy) begin
                        tx_byte_reg <= rd_data_latch[7:0];
                        tx_start    <= 1;
                        state       <= ST_SEND_HI;
                    end
                end

                ST_SEND_HI: begin
                    if (!tx_busy) begin
                        tx_byte_reg <= {4'd0, rd_data_latch[11:8]};
                        tx_start    <= 1;
                        if (coeff_idx == 255) begin
                            cyc_byte <= 0;
                            state    <= ST_SEND_CYC;
                        end
                        else begin
                            coeff_idx <= coeff_idx + 1;
                            rd_addr   <= coeff_idx + 1;
                            rd_wait   <= 0;
                            state     <= ST_READBACK;
                        end
                    end
                end

                // Send 4 bytes of cycle count (LSB first)
                ST_SEND_CYC: begin
                    if (!tx_busy) begin
                        case (cyc_byte)
                            2'd0: tx_byte_reg <= ntt_cycles[7:0];
                            2'd1: tx_byte_reg <= ntt_cycles[15:8];
                            2'd2: tx_byte_reg <= ntt_cycles[23:16];
                            2'd3: tx_byte_reg <= ntt_cycles[31:24];
                        endcase
                        tx_start <= 1;
                        if (cyc_byte == 2'd3)
                            state <= ST_DONE;
                        else
                            cyc_byte <= cyc_byte + 1;
                    end
                end

                ST_DONE: begin
                    state <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

    // ── LEDs (status indicator) ────────────────────
    assign led[0]    = (state == ST_RECV);
    assign led[1]    = (state == ST_LOAD);
    assign led[2]    = (state == ST_WAIT_DONE);
    assign led[3]    = ntt_done;
    assign led[4]    = (state == ST_SEND_LO) | (state == ST_SEND_HI) | (state == ST_SEND_CYC);
    assign led[15]   = 1;  // always on = power indicator
    assign led[14:5] = 0;

endmodule