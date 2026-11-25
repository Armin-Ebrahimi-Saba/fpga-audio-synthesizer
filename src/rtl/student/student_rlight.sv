module student_rlight (
  input logic clk_i,
  input logic rst_ni,

  output tlul_pkg::tl_d2h_t tl_o,
  input  tlul_pkg::tl_h2d_t tl_i,

  output logic [7:0] led_o
);
  assign led_o = 8'b10110100;
  assign tl_o = '{
    a_ready:  '0,
    d_valid:  '0,
    d_opcode: tlul_pkg::AccessAck,
    d_param:  '0,
    d_size:   '0,
    d_source: '0,
    d_sink:   '0,
    d_data:   '0,
    d_user:  '0,
    d_error: '0
  };
endmodule
