module syn_i2c_ctrl (
  input logic clk_i,
  input logic rst_ni,

  output tlul_pkg::tl_d2h_t tl_o,
  input  tlul_pkg::tl_h2d_t tl_i,

  // i2c sda & scl
  input logic scl,
  input logic sda,

  output logic scl_oe,
  output logic sda_oe
);
  import syn_i2c_ctrl_reg_pkg::*;

  syn_i2c_ctrl_hw2reg_t hw2reg;
  syn_i2c_ctrl_reg2hw_t reg2hw;

  syn_i2c_ctrl_reg_top reg_top_i (
      .clk_i,
      .rst_ni,
      .tl_i,
      .tl_o,
      .reg2hw,
      .hw2reg,
      .devmode_i('1)
  );

  assign hw2reg.scl_hw2reg.d = scl;
  assign hw2reg.sda_hw2reg.d = sda;
  assign scl_oe = reg2hw.scl_reg2hw.q;
  assign sda_oe = reg2hw.sda_reg2hw.q;

endmodule
