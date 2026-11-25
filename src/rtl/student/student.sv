module student (
  input logic clk_i,
  input logic rst_ni,

  input  top_pkg::userio_board2fpga_t userio_i,
  output top_pkg::userio_fpga2board_t userio_o,

  output logic irq_o,

  input  tlul_pkg::tl_h2d_t tl_device_peri_i,
  output tlul_pkg::tl_d2h_t tl_device_peri_o,
  input  tlul_pkg::tl_h2d_t tl_device_fast_i,
  output tlul_pkg::tl_d2h_t tl_device_fast_o,

  input  tlul_pkg::tl_d2h_t tl_host_i,
  output tlul_pkg::tl_h2d_t tl_host_o
);
  // io output routing
  logic [7:0] led;
  logic ac_dac_sdata;
  logic ac_bclk;
  logic ac_lrclk;
  logic ac_mclk;
  logic scl_oe;
  logic sda_oe;
  logic [7:0] pmod_b_out;
  assign userio_o = '{
    led: led,
    ac_dac_sdata: ac_dac_sdata,
    ac_bclk: ac_bclk,
    ac_lrclk: ac_lrclk,
    ac_mclk: ac_mclk,
    scl_oe: scl_oe,
    sda_oe: sda_oe,
    pmod_a_oe: '0,
    pmod_b_oe: 8'b00001111,
    pmod_b_out: pmod_b_out,
    default: '0
  };

  localparam int NO_VOICES = 4; // min 4, max 32 - also change in rvlab.h
  localparam int NO_DEVICES = NO_VOICES << 2; // x2 for osc+wave, x2 for other devices
  tlul_pkg::tl_d2h_t tl_o [NO_DEVICES-1:0];
  tlul_pkg::tl_h2d_t tl_i [NO_DEVICES-1:0];
  student_tlul_mux #(
    .NUM(NO_DEVICES)
  ) tlul_mux_i (
    .clk_i,
    .rst_ni,
    .tl_host_o (tl_device_peri_o),
    .tl_host_i (tl_device_peri_i),
    .tl_device_o (tl_o),
    .tl_device_i (tl_i)
  );

  // IRQ configuration
  logic irq_midi_pending;
  localparam int N_IRQ_LINES = 1;
  logic [N_IRQ_LINES-1:0] irq_i;
  assign irq_i = irq_midi_pending;

  // MEMORY MAP:
  // 0 to NO_DEVICES/2 - 1: OSCILLATORS AND WAVEBANKS
  // NO_DEVICES/2 ... max: OTHER MODULES + DUMMY DEVICES

  student_irq_ctrl #(.IRQ_MAX(N_IRQ_LINES)) student_irq_ctrl_i (
    .clk_i,
    .rst_ni,
    .tl_o (tl_o[(NO_DEVICES / 2) + 0]),
    .tl_i (tl_i[(NO_DEVICES / 2) + 0]),
    .irq_o,
    .irq_i
  );

  // synthesizer modules

  syn_midi_parser syn_midi_parser_i (
    .clk_i,
    .rst_ni,
    .tl_o (tl_o[(NO_DEVICES / 2) + 1]),
    .tl_i (tl_i[(NO_DEVICES / 2) + 1]),
    .pmod_a (userio_i.pmod_a),
    .irq_midi_pending
  );

  logic output_ready_strobe;
  logic test_ready_strobe [NO_VOICES-1:0];

  logic               req    [NO_VOICES-1:0];
  logic [11:0]        addr   [NO_VOICES-1:0];
  logic [31:0]        rdata  [NO_VOICES-1:0];
  logic               rvalid [NO_VOICES-1:0]; 
  logic signed [15:0] oscillator_out [NO_VOICES-1:0];

  genvar x;
  generate
    for (x = 0; x < NO_VOICES; x++) begin : gen_wavebanks
      syn_wavebank syn_wavebank_i (
        .clk_i,
        .rst_ni,
        .tl_o (tl_o[x]),
        .tl_i (tl_i[x]),
        .req_b    (req[x]),
        .addr_b   (addr[x]),
        .rdata_b  (rdata[x]),
        .rvalid_b (rvalid[x])
      );   
    end
  endgenerate

  genvar y;
  generate
    for (y = 0; y < NO_VOICES; y++) begin : gen_oscillators
      syn_oscillator syn_oscillator_i (
        .clk_i,
        .rst_ni,
        .tl_o (tl_o[y + NO_VOICES]),
        .tl_i (tl_i[y + NO_VOICES]),
        .next_sample_burst_i (output_ready_strobe),
        .next_sample_burst_o (test_ready_strobe[y]),
        .audio_out (oscillator_out[y]),
        .req    (req[y]),
        .addr   (addr[y]),
        .rdata  (rdata[y]),
        .rvalid (rvalid[y])
      );
    end
  endgenerate

  logic signed [20:0] summed_output; // worst case amplitude for 32 voices
  logic signed [15:0] saturated_output;
  always_comb begin
    summed_output = 0;
    for (int i = 0; i < NO_VOICES; i++) begin
        summed_output = summed_output + oscillator_out[i];
    end
    summed_output = summed_output >>> 3; // scale down - far enough for expected peak but worst case will clip
    if (summed_output > 32767) begin
      saturated_output = 32767;
    end else if (summed_output < -32767) begin
      saturated_output = -32767;
    end else begin
      saturated_output = summed_output[15:0];
    end
  end

  // delay next_sample_burst from audio_out
  logic [7:0] next_sample_delay;
  logic       next_sample;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      next_sample_delay <= 7'd231;
      next_sample <= 1'b0;
    end else if (output_ready_strobe) begin
      next_sample_delay <= '0;
      next_sample <= 1'b0;
    end else if (next_sample_delay == 7'd230) begin //time for oscillators to produce next sample
      next_sample_delay <= next_sample_delay + 1;
      next_sample <= 1'b1;
    end else if (next_sample_delay < 7'd230) begin
      next_sample_delay <= next_sample_delay + 1;
      next_sample <= 1'b0;
    end else begin
      next_sample <= 1'b0;
    end
  end

  logic signed [15:0] echo_output;
  syn_echo #(
    .BUFFER_SIZE(32768) // BUFFER_SIZE = minimum 48000 * desired max delay time (s)
  ) syn_echo_i (
    .clk_i,
    .rst_ni,
    .tl_i  (tl_i[(NO_DEVICES / 2) + 4]),
    .tl_o  (tl_o[(NO_DEVICES / 2) + 4]),
    .in_sample  (saturated_output),
    .next_sample,
    .out_sample (echo_output)
  );

  // RTL SIM ONLY: write output to file
  `ifdef WRITE_AUDIO_OUT
  initial begin
    integer fd;
    fd = $fopen("../../../util/tmp/samples_out", "w");
    $display("Writing audio out of mixer to file");

    forever begin
      @(posedge clk_i);
      if (test_ready_strobe[0]) begin
        $fwrite(fd, $signed(saturated_output));
        $fwrite(fd, ",");
      end
    end
  end
  `endif

  localparam int TEST_MODE = 0;
  syn_audio_out #(
    .TEST_MODE(TEST_MODE))
  syn_audio_out_i(
    .clk_i,
    .rst_ni,
    .tl_o (tl_o[(NO_DEVICES / 2) + 2]),
    .tl_i (tl_i[(NO_DEVICES / 2) + 2]),
    .audio_in     (echo_output),
    .ready_strobe (output_ready_strobe),
    .dac_sdata (ac_dac_sdata),
    .bclk      (ac_bclk),
    .lrclk     (ac_lrclk),
    .mclk      (ac_mclk),
    .pmod_out  (pmod_b_out)
  );

  syn_i2c_ctrl syn_i2c_ctrl_i (
    .clk_i,
    .rst_ni,
    .tl_o (tl_o[(NO_DEVICES / 2) + 3]),
    .tl_i (tl_i[(NO_DEVICES / 2) + 3]),
    .scl    (userio_i.scl),
    .sda    (userio_i.sda),
    .scl_oe (scl_oe),
    .sda_oe (sda_oe)
  );


  // ex 1-5 rlight module
  student_rlight rlight_i (
    .clk_i,
    .rst_ni,
    .tl_o (tl_o[(NO_DEVICES / 2) + 5]),
    .tl_i (tl_i[(NO_DEVICES / 2) + 5]),
    .led_o(led)
  );

  // generate dummy devices to prevent x cascades through the system
  genvar i;
  generate
    for (i = (NO_DEVICES / 2) + 6; i < NO_DEVICES; i++) begin : gen_dummy_devices
      assign tl_o[i] = '{
        a_ready:  '0,
        d_valid:  '0,
        d_opcode: tlul_pkg::AccessAck,
        d_param:  '0,
        d_size:   '0,
        d_source: '0,
        d_sink:   '0,
        d_data:   '0,
        d_user:   '0,
        d_error:  '0
      };
    end
  endgenerate

  // ex 4 dma module
  student_dma dma_i (
    .clk_i,
    .rst_ni,
    .tl_o (tl_device_fast_o),
    .tl_i (tl_device_fast_i),
    .tl_host_o,
    .tl_host_i
  );

endmodule
