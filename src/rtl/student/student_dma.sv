module student_dma (
  input logic clk_i,
  input logic rst_ni,

  input  tlul_pkg::tl_h2d_t tl_i,
  output tlul_pkg::tl_d2h_t tl_o,

  input  tlul_pkg::tl_d2h_t tl_host_i,
  output tlul_pkg::tl_h2d_t tl_host_o
);
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
  assign tl_host_o = '{
    a_opcode: tlul_pkg::PutFullData,
    a_mask: '1,
    a_source: '0,
    a_valid: '0,
    default: '0
  };
endmodule

