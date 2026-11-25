// ADAPTED FROM: https://community.element14.com/technologies/fpga-group/b/blog/posts/systemverilog-study-notes-adsr-envelope-generator-for-sound-synthesis
// - changed sustain behaviour from timing based to hold until note-off
// - changed output format of envelope
// - ADSR configurable instead of having to precompute and hardcode values for a/d/r steps
// - loosely adapted to be configurable in a similar way to https://github.com/gundy/tinysynth/blob/develop/hdl/envelope_generator.vh

// parts of the code were written with help from ChatGPT

module syn_env_shaper (
  input logic clk_i,
  input logic rst_ni,

  input logic start, // generate a pulse to start the envelope generation 
  input logic stop,  // pulse to trigger release phase
  input logic [3:0] attack_step_config,
  input logic [3:0] decay_step_config,
  input logic [3:0] sustain_config,
  input logic [3:0] release_step_config,

  input logic test,

  output logic [14:0] envelope,
  output logic adsr_active
);
  // final env output is 15bit -> max envelope can't have MSB be 1
  localparam int MAX = 32'h8000_0000;

  // 4-bit to 32-bit linear LUT mapping up to 0x7FFFFFFF - used for sustain amplitude
  localparam logic [31:0] linear_4bit_to_max_lut [0:15] = '{
    32'h00000000, // 0
    32'h08888888, // 1
    32'h11111110, // 2
    32'h19999999, // 3
    32'h22222221, // 4
    32'h2AAAAAAA, // 5
    32'h33333332, // 6
    32'h3BBBBBBB, // 7
    32'h44444443, // 8
    32'h4CCCCCCC, // 9
    32'h55555554, // 10
    32'h5DDDDDDD, // 11
    32'h66666665, // 12
    32'h6EEEEEEE, // 13
    32'h77777776, // 14
    32'h7FFFFFFF  // 15
  };

  // LUT holding inverse time duration for a sys-clock of 48000000 hz
  localparam logic [31:0] inv_duration_lut [0:15] = '{
    32'd11185, // 2 ms -> inv=1.041666667e-05
    32'd2796, // 8 ms -> inv=2.604166667e-06
    32'd1398, // 16 ms -> inv=1.302083333e-06
    32'd932, // 24 ms -> inv=8.680555556e-07
    32'd589, // 38 ms -> inv=5.482456140e-07
    32'd399, // 56 ms -> inv=3.720238095e-07
    32'd329, // 68 ms -> inv=3.063725490e-07
    32'd280, // 80 ms -> inv=2.604166667e-07
    32'd224, // 100 ms -> inv=2.083333333e-07
    32'd89, // 250 ms -> inv=8.333333333e-08
    32'd45, // 500 ms -> inv=4.166666667e-08
    32'd28, // 800 ms -> inv=2.604166667e-08
    32'd22, // 1000 ms -> inv=2.083333333e-08
    32'd7, // 3000 ms -> inv=6.944444444e-09
    32'd4, // 5000 ms -> inv=4.166666667e-09
    32'd3 // 8000 ms -> inv=2.604166667e-09
  };
  
  typedef enum logic [2:0] {idle, launch, attack, decay, sustain, rel} state_t;
  state_t state_reg;
  state_t state_next;

  logic [31:0] amplitude_counter_reg;
  logic [31:0] amplitude_counter_next;
  logic [31:0] n_tmp;

  logic [31:0] sustain_level;
  logic [63:0] attack_step;
  logic [31:0] attack_step_reg;
  logic [63:0] decay_step_r;
  logic [63:0] decay_step_r_p1;
  logic [63:0] decay_step_r_p2;
  logic [31:0] decay_step_reg;
  logic [63:0] release_step_r;
  logic [63:0] release_step_r_p1;
  logic [63:0] release_step_r_p2;
  logic [31:0] release_step_reg;

  logic [31:0] decay_a_r;
  logic [31:0] decay_b_r;
  logic [31:0] release_a_r;
  logic [31:0] release_b_r;

  logic stop_latch;
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(~rst_ni) begin
      stop_latch <= 0;
    end else begin
      if (stop) begin
        stop_latch <= 1;
      end else if (start) begin
        stop_latch <= 0;
      end
    end
  end

  // this is optimized away and does not use a DSP block
  assign attack_step = ((MAX) * inv_duration_lut[attack_step_config]);
  
  // 1st pipelined step: get operand values
  always_ff @(posedge clk_i) begin
    decay_a_r <= MAX - sustain_level;
    decay_b_r <= inv_duration_lut[decay_step_config];
    release_a_r <= sustain_level;
    release_b_r <= inv_duration_lut[release_step_config];
    sustain_level <= linear_4bit_to_max_lut[sustain_config];
  end

  // 2nd pipelined step: do multiplication and register output
  always_ff @(posedge clk_i) begin
    decay_step_r_p1 <= decay_a_r * decay_b_r;
    decay_step_r_p2 <= decay_step_r_p1;
    decay_step_r <= decay_step_r_p2;
    // if no sustain step, release = decay:
    release_step_r_p1 <= release_a_r * release_b_r;
    release_step_r_p2 <= release_step_r_p1;
    release_step_r <= sustain_level ? release_step_r_p2 : decay_step_r_p2;
  end
  
  // 3rd: window/bitshift
  always_ff @(posedge clk_i) begin
    attack_step_reg <= !test ? attack_step[61:30] : attack_step[54:23]; // >> 30
    decay_step_reg <= !test ? decay_step_r[61:30] : decay_step_r[54:23]; // >> 30
    release_step_reg <= !test ? release_step_r[61:30] : release_step_r[54:23]; // >> 30
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(~rst_ni) begin
      state_reg <= idle;
      amplitude_counter_reg <= 32'h0;
    end else begin
      state_reg <= state_next;
      amplitude_counter_reg <= amplitude_counter_next;
    end
  end
  

  always_comb begin
    state_next = state_reg;
    amplitude_counter_next = amplitude_counter_reg;
    adsr_active = '1;
    n_tmp = '0;
    case (state_reg)         
      idle: begin
        adsr_active = '0;
        if (start) begin
          state_next = launch;
        end
      end
      launch: begin
        state_next = attack;
        if (stop_latch) begin
          state_next = idle;
        end
      end  
      attack: begin
        if (start) begin
          state_next = launch;
        end else if (stop_latch) begin
	  // if amplitude already higher than sustain, decay first!
	  if (amplitude_counter_reg > sustain_level) begin
            state_next = decay;
	  end else begin
            state_next = rel;
	  end
        end else begin
          n_tmp = amplitude_counter_reg + attack_step_reg;
          if (n_tmp < MAX) begin
            amplitude_counter_next = n_tmp;
          end else begin
            state_next = decay;
          end
        end
      end
      decay: begin
        if (start) begin
          state_next = launch;
        // if decay is shorter than release, finish decay phase first before
        // stopping
        end else if (stop_latch && (decay_step_config > release_step_config)) begin
          state_next = rel;
        end else begin
          n_tmp = amplitude_counter_reg - decay_step_reg;
	  if (n_tmp > amplitude_counter_reg) begin // underflow occurred
            amplitude_counter_next = sustain_level;
            state_next = (sustain_level != 0) ? sustain : idle;
          end else if (n_tmp > sustain_level) begin
            amplitude_counter_next = n_tmp;
          end else begin
            amplitude_counter_next = sustain_level;
            state_next = (sustain_level != 0) ? sustain : idle;
          end
        end
      end              
      sustain: begin
        if (start) begin
          state_next = launch;
        end else if(stop_latch) begin
          state_next = rel;
        end
      end              
      default: begin
        if (start) begin
          state_next = launch;
        end else begin
          if(amplitude_counter_reg > release_step_reg) begin
            amplitude_counter_next = amplitude_counter_reg - release_step_reg;
          end else begin
            state_next = idle;
            amplitude_counter_next = '0;
          end
        end
      end    
    endcase
  end
  
  assign envelope = {amplitude_counter_reg[30:16]};

endmodule
