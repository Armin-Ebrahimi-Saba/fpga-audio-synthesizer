
// Dual-Port Block RAM with Two Write Ports
// File: rams_tdp_rf_rf.v
// see https://docs.amd.com/r/en-US/ug901-vivado-synthesis/Dual-Port-Block-RAM-with-Two-Write-Ports-in-Read-First-Mode-Verilog-Example

module syn_ringbuffer_ram #(
  parameter int SIZE = 65536,
  parameter int Aw = $clog2(SIZE)
) (

  input logic clk_i,
  input logic ena,
  input logic enb,
  input logic [1:0] wea,
  input logic [1:0] web,
  input logic [Aw-1:0] addra,
  input logic [Aw-1:0] addrb,
  input logic [15:0] dia,
  input logic [15:0] dib,
  output logic [15:0] doa,
  output logic [15:0] dob
);
  (* ram_style = "block" *) logic [15:0] ram [SIZE-1:0];

  // initialize with 0 for simulation
  integer i;
  initial begin 
    for (i=0; i<SIZE; i=i+1) ram[i] = 0;
  end

  always @(posedge clk_i) begin
    if (ena) begin
      if (wea[0]) ram[addra][15:0]  <= dia[15:0];
      doa <= ram[addra];
    end
  end

  always @(posedge clk_i) begin
    if (enb) begin
      if (web[0]) ram[addrb][15:0]  <= dib[15:0];
      dob <= ram[addrb];
    end
  end

endmodule
