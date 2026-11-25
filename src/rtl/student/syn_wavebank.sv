module syn_wavebank (
  input logic clk_i,
  input logic rst_ni,

  output tlul_pkg::tl_d2h_t tl_o,
  input  tlul_pkg::tl_h2d_t tl_i,

  // dpram read: oscillator
  input  logic        req_b,
  input  logic [11:0] addr_b,
  output logic [31:0] rdata_b,
  output logic        rvalid_b
);

  localparam int AddrWidth = 12;

  // port a: CPU
  logic                 req_a;
  logic                 we_a;
  logic [AddrWidth-1:0] addr_a;
  logic [31:0]          wdata_a;
  logic [31:0]          wmask_a;
  logic [31:0]          rdata_a;
  logic                 rvalid_a;

  tlul_adapter_sram #(
    .SramAw     (AddrWidth),
    .SramDw     (32),
    .Outstanding(1)
  ) adapter_cpu_i (
    .clk_i,
    .rst_ni,

    .tl_i,
    .tl_o,

    .req_o   (req_a),
    .gnt_i   (1'b1),
    .we_o    (we_a),
    .addr_o  (addr_a),
    .wdata_o (wdata_a),
    .wmask_o (wmask_a),
    .rdata_i (rdata_a),
    .rvalid_i(rvalid_a),
    .rerror_i(2'b00)
  );

  // map 32bit tlul mask to 2bit ram byte-mask
  wire [1:0] write_mask_a;
  assign write_mask_a[0] = we_a & (|wmask_a[15:0]);
  assign write_mask_a[1] = we_a & (|wmask_a[31:16]);

  syn_tdpram #(
    .Aw(AddrWidth)
  ) syn_tdpram_i (
    .clk_i (clk_i),
    // port a: cpu
    .ena   (req_a),
    .wea   (write_mask_a),
    .addra (addr_a),
    .dia   (wdata_a),
    .doa   (rdata_a),
    // port b: oscillator
    .enb   (req_b),
    .web   ('0), // only read
    .addrb (addr_b),
    .dib   ('0), // only read
    .dob   (rdata_b)
  );
   
  // set valid on next pulse after read-request
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      rvalid_a <= '0;
      rvalid_b <= '0;
    end else begin
      rvalid_a <= (req_a && !we_a);
      rvalid_b <= (req_b);
    end
  end

endmodule
