module syn_audio_out #(TEST_MODE = 0) (
  input logic clk_i,    // 48MHz
  input logic rst_ni,

  output tlul_pkg::tl_d2h_t tl_o,
  input  tlul_pkg::tl_h2d_t tl_i,

  // audio in
  input logic [15:0] audio_in,
  output logic ready_strobe,

  // i2s output
  output logic dac_sdata,
  output logic bclk,
  output logic lrclk,
  output logic mclk,
  output logic [7:0] pmod_out
);
  import syn_audio_out_reg_pkg::*;

  syn_audio_out_hw2reg_t hw2reg;
  syn_audio_out_reg2hw_t reg2hw;

  syn_audio_out_reg_top reg_top_i (
      .clk_i,
      .rst_ni,
      .tl_i,
      .tl_o,
      .reg2hw,
      .hw2reg,
      .devmode_i('1)
  );

  logic ready;
  logic [15:0] audio_in_reg;

  // communication with software tb if TEST_MODE active
  assign hw2reg.test_ready_strobe.d = ready;
  assign audio_in_reg = TEST_MODE ? reg2hw.test_audio_in.q : audio_in;


  // generate mclk: clk_i / 2 = 24MHz
  logic mclk_reg;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)
      mclk_reg <= 1'b0;
    else
      mclk_reg <= ~mclk_reg;
  end

  assign mclk = mclk_reg;


  // generate bclk: clk_i/22 ~ 2.182MHz
  // generate lrclk: clk_i/1000 = 48kHz sample rate
  logic [8:0] bit_cnt;
  logic lrclk_reg;
  logic [3:0] bclk_cnt;
  logic bclk_reg;
  logic negedge_bclk;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      bit_cnt <= 9'd0;
      lrclk_reg <= 1'b0;
      bclk_cnt <= 4'd0;
      bclk_reg <= 1'b0;
    end else if (bit_cnt == 9'd499) begin
      bit_cnt <= 9'd0;
      lrclk_reg <= ~lrclk_reg;
      bclk_cnt <= 4'd0;
      bclk_reg <= 1'b0;
    end else if (bclk_cnt == 4'd10) begin
      bclk_cnt <= 4'd0;
      bclk_reg <= ~bclk_reg;
      bit_cnt <= bit_cnt +1;
    end else begin
      bclk_cnt <= bclk_cnt + 1;
      bit_cnt <= bit_cnt + 1;
    end
  end

  assign bclk = bclk_reg;
  assign lrclk = lrclk_reg;


  // bclk edge detection
  logic bclk_prev;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)
      bclk_prev <= 1'b0;
    else
      bclk_prev <= bclk_reg;
  end

  assign negedge_bclk = bclk_prev && !bclk_reg;


  //shift data out
  logic [23:0] shift_reg;
  logic [23:0] audio_in_copy_reg;
  logic switch_channel;

  assign switch_channel = (bit_cnt == 8'b0);

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      shift_reg <= 24'd0;
      audio_in_copy_reg <= 24'd0;
    end else if (negedge_bclk) begin
      if (switch_channel) begin
        if (lrclk_reg == 1'b0) begin
          shift_reg <= {1'b0, audio_in_reg, 7'd0}; // zero padding
          audio_in_copy_reg <= {1'b0, audio_in_reg, 7'd0};
        end else begin
          shift_reg <= audio_in_copy_reg;
        end
      end else begin
        shift_reg <= {shift_reg[22:0], 1'b0};
      end
    end
  end

  assign dac_sdata = shift_reg[23];


  // send ready_strobe
  assign ready = (bit_cnt == 9'd40 && lrclk_reg == 1'b1);
  assign ready_strobe = TEST_MODE ? 1'b0 : ready;


  // status output to pmod
  assign pmod_out = {4'b0, mclk, lrclk, bclk, dac_sdata};


  // status output to software
  assign hw2reg.lrclk.d = lrclk;
  assign hw2reg.bclk.d = bclk;
  assign hw2reg.sdata.d = dac_sdata;
  assign hw2reg.shift_reg.d = shift_reg;

endmodule
