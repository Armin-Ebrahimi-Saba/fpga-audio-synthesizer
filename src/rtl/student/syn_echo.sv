module syn_echo #(
    parameter int BUFFER_SIZE = 16384
)(
    input  logic clk_i,
    input  logic rst_ni,

    input  tlul_pkg::tl_h2d_t tl_i,
    output tlul_pkg::tl_d2h_t tl_o,

    input  logic signed [15:0]  in_sample,
    input  logic 		        next_sample,
    output logic signed [15:0]  out_sample
);

    import syn_echo_reg_pkg::*;
    syn_echo_reg2hw_t reg2hw;

    syn_echo_reg_top reg_top (
        .clk_i,
        .rst_ni,
        .tl_i,
        .tl_o,
        .reg2hw,
        .devmode_i(1'b1)
    );

    logic       echo_enable;
    logic [3:0] feedback_gain;
    logic [3:0] decay_gain;
    logic [15:0] delay_samples;

    assign echo_enable   = reg2hw.enable.q;
    assign feedback_gain = reg2hw.feedback.q;
    assign decay_gain    = reg2hw.decay.q;
    assign delay_samples = (reg2hw.delay.q >= BUFFER_SIZE) ? BUFFER_SIZE - 1 : reg2hw.delay.q;


    logic [$clog2(BUFFER_SIZE)-1:0] wr_ptr = 0;
    logic [$clog2(BUFFER_SIZE)-1:0] rd_ptr;
    logic [$clog2(BUFFER_SIZE)-1:0] rd_ptr_next;


    logic signed [15:0] delayed_sample;
    logic signed [15:0] write_sample;

    syn_ringbuffer_ram #(
        .SIZE(BUFFER_SIZE)
    ) delay_buffer (
        .clk_i   (clk_i),
        .ena     (1'b1),
        .enb     (1'b1),
        .wea     (2'b00),
        .web     (2'b01),
        .addra   (rd_ptr),
        .addrb   (wr_ptr),
        .dia     ('0),
        .dib     (write_sample),
        .doa     (delayed_sample),
        .dob     ()
    );

    // Fit to 16-bit signed range
    function automatic logic signed [15:0] fit16Bit(input logic signed [16:0] val);
        if (val > 32767)
            return 16'sd32767;
        else if (val < -32768)
            return -16'sd32768;
        else
            return val[15:0];
    endfunction

    // Echo logic
    logic [1:0] setup_delay;
    logic signed [20:0] wet_sample_unscaled;
    logic signed [20:0] wet_sample;
    logic signed [20:0] feedback_sample_unscaled;
    logic signed [20:0] feedback_sample;
    logic signed [16:0] mixed_out_sample;
    logic signed [16:0] mixed_write_sample;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin

            wr_ptr <= '0;
            rd_ptr <= '0;
            setup_delay <= 0;
            out_sample <= 0;
            write_sample <= 0;

        end else begin
            if (setup_delay < 3) begin

                setup_delay <= setup_delay + 1;
                write_sample <= 0;

            end else if (next_sample) begin

                rd_ptr <= (wr_ptr >= delay_samples) ? wr_ptr - delay_samples : BUFFER_SIZE + wr_ptr - delay_samples;
                wr_ptr <= (wr_ptr == BUFFER_SIZE - 1) ? 0 : wr_ptr + 1;

                wet_sample_unscaled     <= (delayed_sample * $signed({1'b0, decay_gain}));
                wet_sample              <= wet_sample_unscaled >>> 3;
                mixed_out_sample        <= ((in_sample >>> 2) + (wet_sample));
                out_sample              <= echo_enable ? fit16Bit(mixed_out_sample) : in_sample;

                feedback_sample_unscaled    <= (delayed_sample * $signed({1'b0, feedback_gain}));
                feedback_sample             <= feedback_sample_unscaled >>> 5;
                mixed_write_sample          <= (((in_sample >>> 1) + (feedback_sample * 3)) * 3) >> 3;
                write_sample                <= fit16Bit(mixed_write_sample);

            end
        end
    end

endmodule
