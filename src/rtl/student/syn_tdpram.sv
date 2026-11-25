// Dual-Port Block RAM with Two Write Ports
// File: rams_tdp_rf_rf.v
// see https://docs.amd.com/r/en-US/ug901-vivado-synthesis/Dual-Port-Block-RAM-with-Two-Write-Ports-in-Read-First-Mode-Verilog-Example

module syn_tdpram #(
  parameter int Aw = 12
) (

  input logic clk_i,
  input logic ena,
  input logic enb,
  input logic [1:0] wea,
  input logic [1:0] web,
  input logic [Aw-1:0] addra,
  input logic [Aw-1:0] addrb,
  input logic [31:0] dia,
  input logic [31:0] dib,
  output logic [31:0] doa,
  output logic [31:0] dob
);
  (* ram_style = "block" *) logic [31:0] ram [4095:0];

  // initialize with 0
  integer i;
  initial begin 
    for (i=0; i<4096; i=i+1) ram[i] = 0;
  end

  always @(posedge clk_i) begin
    if (ena) begin
      if (wea[0]) ram[addra][15:0]  <= dia[15:0];
      if (wea[1]) ram[addra][31:16] <= dia[31:16];
      doa <= ram[addra];
    end
  end

  always @(posedge clk_i) begin
    if (enb) begin
      if (web[0]) ram[addrb][15:0]  <= dib[15:0];
      if (web[1]) ram[addrb][31:16] <= dib[31:16];
      dob <= ram[addrb];
    end
  end

endmodule
