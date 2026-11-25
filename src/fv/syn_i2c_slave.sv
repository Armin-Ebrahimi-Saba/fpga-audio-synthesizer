module syn_i2c_slave #(parameter DEVICE_ADDR = 7'b0111011) (
    input logic clk,

    input  logic scl_i,
    input  logic sda_i,
    output logic sda_o
);

    // sda_o = 0 -> dont drive SDA; sda_o = 1 -> drive SDA LOW
    logic sda_out = 1;
    assign sda_o = sda_out ? 1'b0 : 1'b1;


    typedef enum logic [2:0] {
        IDLE,
        ACK,
        ADDR,
        REG_ADDR_HIGH,
        REG_ADDR_LOW,
        WRITE_DATA,
        READ_DATA,
        WAIT_ACK
    } state_t;

    state_t state = IDLE;
    state_t next_state = IDLE;


    // dummy codec registers
    logic[7:0] regs[0:2];
    initial begin
        regs[0] = 0;
        regs[1] = 0;
        regs[2] = 0;
    end


    logic initialized = 0;
    logic[2:0] init_cnt = 0;

    logic[3:0] bit_cnt = 0;
    logic[7:0] shift_reg = 0;
    logic[15:0] reg_addr = 0;

    // previous SDA/SCL values for edge detection
    logic sda_prev = 1, scl_prev = 1;


    //oversample SDA/SCL to filter out false start/stop peaks
    logic scl_sync_1, scl_sync_2;
    logic sda_sync_1, sda_sync_2;

    always @(posedge clk) begin
        scl_sync_1 <= scl_i;
        scl_sync_2 <= scl_sync_1;

        sda_sync_1 <= sda_i;
        sda_sync_2 <= sda_sync_1;
    end

    logic scl_stable, sda_rising, sda_falling;
    logic start_cond, stop_cond;

    assign scl_stable     = (scl_sync_1 & scl_sync_2);
    assign sda_rising     = (sda_sync_1 & ~sda_sync_2);
    assign sda_falling     = ~sda_sync_1 & sda_sync_2;

    assign start_cond = scl_stable & sda_falling;
    assign stop_cond = scl_stable & sda_rising;


    always @(posedge start_cond) begin
        if (state == IDLE || state == WRITE_DATA) begin
            state <= ADDR;
            bit_cnt <= 0;
            sda_out <= 1;
        end
    end
    always @(posedge stop_cond) begin
        if (state != IDLE) begin
            state <= IDLE;
            bit_cnt <= 0;
            sda_out <= 1;
        end
    end


    always @(posedge scl_i, negedge scl_i) begin
        if (!scl_i) begin
            sda_out <= 1'b1;
        end else begin

            //reset signals until SDA and SCL are stable
            if (!initialized) begin
                state     <= IDLE;
                bit_cnt   <= 0;
                shift_reg <= 0;
                reg_addr  <= 0;
                sda_out   <= 1;

                if (sda_i && scl_i) begin
                    init_cnt <= init_cnt + 1;
                    if (init_cnt == 4'd3) begin
                        initialized <= 1;
                    end
                end else begin
                    init_cnt <= 0; // reset counter if any line goes low
                end

            end else begin
                case (state)
                    IDLE: begin
                        sda_out <= 1;
                        bit_cnt <= 0;
                    end

                    ACK: begin
                        sda_out <= 0;
                        state <= next_state;
                    end

                    ADDR: begin
                        shift_reg <= {shift_reg[6:0], sda_i};
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 7) begin
                            if (shift_reg[6:0] == DEVICE_ADDR) begin
                                if (sda_i == 0) begin
                                    next_state <= REG_ADDR_HIGH;
                                    state <= ACK;
                                    bit_cnt <= 0;
                                end else begin
                                    next_state <= READ_DATA;
                                    state <= ACK;
                                    bit_cnt <= 0;
                                end
                            end else begin
                                state <= IDLE;
                            end
                            bit_cnt <= 0;
                        end
                    end

                    REG_ADDR_HIGH: begin
                        shift_reg <= {shift_reg[6:0], sda_i};
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 7) begin
                            reg_addr[15:8] <= {shift_reg[6:0], sda_i};
                            next_state <= REG_ADDR_LOW;
                            state <= ACK;
                            bit_cnt <= 0;
                        end
                    end

                    REG_ADDR_LOW: begin
                        shift_reg <= {shift_reg[6:0], sda_i};
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 7) begin
                            reg_addr[7:0] <= {shift_reg[6:0], sda_i};
                            next_state <= WRITE_DATA;
                            state <= ACK;
                            bit_cnt <= 0;
                        end
                    end

                    WRITE_DATA: begin
                        shift_reg <= {shift_reg[6:0], sda_i};
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 7) begin
                            regs[reg_addr[1:0]] <= {shift_reg[6:0], sda_i};
                            next_state <= IDLE;
                            state <= ACK;
                            bit_cnt <= 0;
                        end
                    end

                    READ_DATA: begin
                        if (bit_cnt < 8) begin
                            sda_out <= regs[reg_addr[1:0]][7 - bit_cnt];
                            bit_cnt <= bit_cnt + 1;
                        end else begin
                            state <= WAIT_ACK;
                            bit_cnt <= 0;
                        end
                    end

                    //part of I2C, but not relevant for this implementation
                    WAIT_ACK: begin
                        if (sda_i == 1) begin
                            state <= IDLE;  // NACK
                        end else begin
                            state <= IDLE;  // ACK
                        end
                        sda_out <= 1;
                    end
                endcase
            end

            // Update previous SDA/SCL for edge detection
            sda_prev <= sda_i;
            scl_prev <= scl_i;
        end
    end

endmodule
