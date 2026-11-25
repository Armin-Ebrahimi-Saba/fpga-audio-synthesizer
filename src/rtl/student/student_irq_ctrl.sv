module student_irq_ctrl #(
    parameter int IRQ_MAX = 32
) (
    input logic clk_i,
    input logic rst_ni,

    output tlul_pkg::tl_d2h_t tl_o,  //slave output (this module's response)
    input  tlul_pkg::tl_h2d_t tl_i,  //master input (incoming request)

    output logic irq_o,

    input logic [IRQ_MAX-1:0] irq_i 
);
import student_irq_ctrl_reg_pkg::*;

// Signals & types
// ---------------

typedef enum logic [0:0] {
    PROD = 1'b0,
    TEST = 1'b1
} irq_mode_t;

student_irq_ctrl_reg2hw_t reg2hw;
student_irq_ctrl_hw2reg_t hw2reg;

logic [IRQ_MAX-1:0] status;
logic [IRQ_MAX-1:0] status_next;
logic [IRQ_MAX-1:0] irq_no;
logic [IRQ_MAX-1:0] mask_write;

irq_mode_t          mode;
logic               all_en;

logic [IRQ_MAX-1:0] mask;
logic               mask_strobe;
logic [IRQ_MAX-1:0] mask_set;
logic               mask_set_strobe;
logic [IRQ_MAX-1:0] mask_clr;
logic               mask_clr_strobe;

logic               test;
logic [IRQ_MAX-1:0] test_irq;
logic [IRQ_MAX-1:0] irq_m;
logic [IRQ_MAX-1:0] irq_no_next;

// Register interface
// ------------------

student_irq_ctrl_reg_top reg_top_i (
    .clk_i,
    .rst_ni,
    .tl_i,
    .tl_o,
    .reg2hw,
    .hw2reg,
    .devmode_i('1)
);

assign hw2reg.status.d = status;
assign hw2reg.irq_no.d = irq_no;

assign hw2reg.mask.d   = mask_write;
assign hw2reg.mask.de  = '1;

assign all_en          = reg2hw.all_en.q;      
assign mask            = reg2hw.mask.q; 
assign mask_strobe     = reg2hw.mask.qe;
assign mask_set        = reg2hw.mask_set.q;
assign mask_set_strobe = reg2hw.mask_set.qe;
assign mask_clr        = reg2hw.mask_clr.q;
assign mask_clr_strobe = reg2hw.mask_clr.qe;

assign test            = reg2hw.test.q;
assign test_irq        = reg2hw.test_irq.q;

assign mode            = irq_mode_t'(test);
assign irq_m           = (mode == PROD) ? (irq_i & mask) : (test_irq & mask);
assign status_next     = (mode == PROD) ? irq_i : test_irq;


// One hot to binary - find index of highest prio interrupt line
// -------------------------------------------------------------

always_comb begin
  irq_no_next = IRQ_MAX;
  for (int i = IRQ_MAX-1; i >= 0; i--) begin
    if (irq_m[i])
      irq_no_next = i;
  end
end

// IRQ_CTRL update mask, status, output procedure
// -----------------------------

always_ff @(posedge clk_i or negedge rst_ni) begin
  if (~rst_ni) begin
    status <= '0;
    irq_no <= 32'(IRQ_MAX);
    irq_o  <= '0;
    mask_write <= '1;
  end else begin
    if (mask_set_strobe) mask_write <= (mask_write | mask_set);
    else if (mask_clr_strobe) mask_write <= (mask_write & ~mask_clr);
    else if (mask_strobe) mask_write <= mask;
        
    status       <= status_next;
    irq_no       <= irq_no_next;
    irq_o        <= (|irq_m) & all_en; // |irq_m == 1 if at least one bit is asserted
  end
end

endmodule
