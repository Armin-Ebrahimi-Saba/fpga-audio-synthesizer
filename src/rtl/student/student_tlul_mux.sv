module student_tlul_mux #(
    parameter int NUM = 32
) (
    input logic clk_i,
    input logic rst_ni,

    output tlul_pkg::tl_d2h_t tl_host_o,
    input  tlul_pkg::tl_h2d_t tl_host_i,

    input  tlul_pkg::tl_d2h_t  tl_device_o [NUM-1:0],
    output tlul_pkg::tl_h2d_t  tl_device_i [NUM-1:0]
);
  import tlul_pkg::*;

  localparam int SEL_WIDTH = $clog2(NUM);
  localparam int ADDR_SPACE = 32'h0100_0000;
  localparam int ADDR_SHIFT = $clog2(ADDR_SPACE / NUM);

  logic [SEL_WIDTH-1:0] device_sending;
  always_comb begin
    device_sending = 0;
    for (int i = 0; i < NUM; i++) begin
      device_sending = tl_device_o[i].d_valid ? i : device_sending;
    end
  end

  logic [SEL_WIDTH-1:0] device_sel;
  assign device_sel = tl_host_i.a_valid ? (tl_host_i.a_address) >> ADDR_SHIFT : device_sending;

  logic device_sel_valid;
  assign device_sel_valid = (device_sel < NUM);

  tl_d2h_t error_response;
  assign error_response = '{
    d_valid: 1'b1,
    d_opcode: AccessAck,
    d_param: '0,
    d_size: '0,
    d_source: '0,
    d_sink: '0,
    d_data: '0,
    d_user: '0,
    d_error: 1'b1,
    a_ready: '0
  };

  assign tl_host_o = device_sel_valid ? tl_device_o[device_sel] : error_response;

  genvar i;
  generate
    for (i = 0; i < NUM; i++) begin : gen_dev_sel
      assign tl_device_i[i] = (device_sel_valid && (device_sel == i)) ? tl_host_i : '0;
    end
  endgenerate

endmodule
