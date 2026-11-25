module syn_oscillator (
  input logic clk_i,
  input logic rst_ni,

  output tlul_pkg::tl_d2h_t tl_o,
  input  tlul_pkg::tl_h2d_t tl_i,

  // audio out
  output logic signed [15:0] audio_out,

  // ready burst in
  input logic next_sample_burst_i,
  output logic next_sample_burst_o,

  // read from wavetable
  output logic        req,
  output logic [11:0]  addr,
  input  logic [31:0] rdata,
  input  logic        rvalid
);
  import syn_oscillator_reg_pkg::*;
  syn_oscillator_hw2reg_t hw2reg;
  syn_oscillator_reg2hw_t reg2hw;
  syn_oscillator_reg_top reg_top_i (
    .clk_i,
    .rst_ni,
    .tl_i,
    .tl_o,
    .reg2hw,
    .hw2reg,
    .devmode_i('1)
  );
  // LUT for mapping midi note to phase increment offset - assumes 48khz sample rate
  logic [31:0] phase_inc_lut [0:127] = '{
    32'd731558,
    32'd775059,
    32'd821146,
    32'd869974,
    32'd921705,
    32'd976513,
    32'd1034579,
    32'd1096099,
    32'd1161276,
    32'd1230329,
    32'd1303488,
    32'd1380998,
    32'd1463116,
    32'd1550118,
    32'd1642292,
    32'd1739948,
    32'd1843411,
    32'd1953026,
    32'd2069159,
    32'd2192197,
    32'd2322552,
    32'd2460658,
    32'd2606977,
    32'd2761996,
    32'd2926232,
    32'd3100235,
    32'd3284585,
    32'd3479896,
    32'd3686822,
    32'd3906052,
    32'd4138318,
    32'd4384395,
    32'd4645104,
    32'd4921317,
    32'd5213953,
    32'd5523991,
    32'd5852465,
    32'd6200470,
    32'd6569170,
    32'd6959793,
    32'd7373644,
    32'd7812103,
    32'd8276635,
    32'd8768789,
    32'd9290209,
    32'd9842633,
    32'd10427907,
    32'd11047982,
    32'd11704930,
    32'd12400941,
    32'd13138339,
    32'd13919586,
    32'd14747287,
    32'd15624207,
    32'd16553270,
    32'd17537579,
    32'd18580418,
    32'd19685267,
    32'd20855814,
    32'd22095965,
    32'd23409859,
    32'd24801882,
    32'd26276679,
    32'd27839171,
    32'd29494575,
    32'd31248413,
    32'd33106541,
    32'd35075158,
    32'd37160835,
    32'd39370534,
    32'd41711627,
    32'd44191930,
    32'd46819719,
    32'd49603764,
    32'd52553357,
    32'd55678342,
    32'd58989149,
    32'd62496826,
    32'd66213081,
    32'd70150316,
    32'd74321671,
    32'd78741067,
    32'd83423255,
    32'd88383859,
    32'd93639437,
    32'd99207528,
    32'd105106715,
    32'd111356685,
    32'd117978298,
    32'd124993653,
    32'd132426162,
    32'd140300631,
    32'd148643341,
    32'd157482134,
    32'd166846509,
    32'd176767719,
    32'd187278874,
    32'd198415056,
    32'd210213429,
    32'd222713370,
    32'd235956596,
    32'd249987305,
    32'd264852324,
    32'd280601263,
    32'd297286682,
    32'd314964268,
    32'd333693018,
    32'd353535438,
    32'd374557749,
    32'd396830112,
    32'd420426858,
    32'd445426740,
    32'd471913192,
    32'd499974611,
    32'd529704648,
    32'd561202526,
    32'd594573365,
    32'd629928537,
    32'd667386037,
    32'd707070876,
    32'd749115498,
    32'd793660223,
    32'd840853716,
    32'd890853480,
    32'd943826385,
    32'd999949222,
    32'd1059409297,
    32'd1122405052
  };

  // internal signal when to output next sample - configurable by test mode
  logic next_sample_burst;

  // test mode
  logic test;
  assign test = reg2hw.test.q;
  logic [15:0] test_burst_n;
  assign test_burst_n = reg2hw.test_n_readyburst.q;

  logic [15:0] cnt;
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
      cnt <= '0;
    end else begin
      if (cnt != 0) begin
        cnt <= cnt - 1;
      end else begin
        cnt <= test_burst_n;
      end
    end
  end

  assign next_sample_burst = test == 0 ? next_sample_burst_i : (cnt == 0 ? 1 : 0);
  assign next_sample_burst_o = next_sample_burst;

  // control & status registers
  logic [6:0] note;
  assign note = reg2hw.note.q;
  logic start;
  assign start = reg2hw.note.qe;
  logic [7:0] velocity;
  assign velocity = {1'b0, reg2hw.velocity.q};
  logic stop;
  assign stop = reg2hw.stop.qe;
  logic [1:0] sample_index;
  assign sample_index = reg2hw.sample.sample_index.q;
  logic [1:0] sample_size;
  assign sample_size = reg2hw.sample.sample_size.q;

  logic osc_active;
  assign hw2reg.status_state.d = osc_active;
  assign hw2reg.status_output = audio_out;

  // adapter for byte addressing to dpram interface
  logic               offset;
  logic        [11:0]  addr_dpram;
  logic        [13:0] addr_bytes; // +2 bytes bigger than addr to dpram
  logic signed [15:0] rdata_sample;
  logic signed [15:0] rdata_sample_r;
  always_comb begin 
    addr_dpram = addr_bytes >> 2;
    offset = addr_bytes[1];
  end
  assign addr = addr_dpram;
  assign rdata_sample = ~rvalid ? '0 : offset ? rdata[31:16] : rdata[15:0];

  // synthesizer specific variables
  logic [31:0] phase_accum;
  logic [31:0] phase_inc;
  assign phase_inc = phase_inc_lut[note]; 
  logic [10:0] index;

  // envelope shaper
  logic [3:0] attack_step_config;
  assign attack_step_config = reg2hw.env_config.attack_value.q;
  logic [3:0] decay_step_config;
  assign decay_step_config = reg2hw.env_config.decay_value.q;
  logic [3:0] sustain_config;
  assign sustain_config = reg2hw.env_config.sustain_value.q;
  logic [3:0] release_step_config;
  assign release_step_config = reg2hw.env_config.release_value.q;

  logic signed [31:0] unscaled_output;
  logic signed [31:0] unscaled_output_p1;
  logic signed [38:0] scaled_output_p1;
  logic signed [15:0] scaled_output_p2;
  logic signed [15:0] scaled_output_p3; // this is not necessary can be removed and replaced with the audio_out, keeping it if later needed for pipelining
  logic [14:0] envelope;
  logic signed [15:0] envelope_r;

  syn_env_shaper syn_env_shaper_i (
    .clk_i,
    .rst_ni,
    .start,
    .stop,
    .attack_step_config,
    .decay_step_config,
    .sustain_config,
    .release_step_config,
    .test,
    .envelope,
    .adsr_active(osc_active)
  );

  // different LUT sizes:
  assign index = sample_size == 0 ? {3'b0, phase_accum[31:24]} :
                 sample_size == 1 ? {2'b0, phase_accum[31:23]} :
                 sample_size == 2 ? {1'b0, phase_accum[31:22]} :
                 /*size == 3 ? */   phase_accum[31:21];
  assign addr_bytes = {sample_index, index, 1'b0};

  // core logic
  logic dsp_init;
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      phase_accum <= '0;
      req <= '0;
      unscaled_output <= '0;
      dsp_init <= 0;
    end else begin
      req <= '0;

      // DSP regs dont have async reset, hence the manual init
      if (~dsp_init) begin
        rdata_sample_r <= '0;
        envelope_r <= '0;
        dsp_init <= 1;
      end

      if (osc_active || audio_out) begin // while audio not null, continue updating
        // request correct sample and increment phase accumulator
        if (next_sample_burst) begin
          phase_accum <= phase_accum + phase_inc;
          req <= 1;
        end
        // take response from dpram and write to registers for DSP
        if (rvalid) begin
          rdata_sample_r <= rdata_sample;
          envelope_r <= $signed({1'b0, envelope});
        end
      end
      
      unscaled_output <= unscaled_output_p1; // save pipelined DSP result (see below)
    
    end
  end

  // registered DSP mult
  always_ff @(posedge clk_i) begin
    unscaled_output_p1 <= rdata_sample_r * envelope_r;
    scaled_output_p1 <= unscaled_output * velocity;
    scaled_output_p2 <= scaled_output_p1 >>> 22; // div by max amplitude to scale correctly and divide by max velocity
    scaled_output_p3 <= scaled_output_p2; // pipelining 32 bit multiplication
  end

  // final output assignment:
  assign audio_out = scaled_output_p3;

endmodule
