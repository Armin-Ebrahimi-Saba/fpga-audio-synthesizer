module student_rlight_tb;
  logic clk;
  logic rst_n;
  logic [7:0] led;
  tlul_pkg::tl_d2h_t tl_d2h;
  tlul_pkg::tl_h2d_t tl_h2d;

  // 50 MHz
  always begin
    clk = '1;
    #10000;
    clk = '0;
    #10000;
  end

  student_rlight DUT (
    .clk_i (clk),
    .rst_ni(rst_n),
    .tl_i  (tl_h2d),
    .tl_o  (tl_d2h),
    .led_o (led)
  );

  tlul_test_host bus(
    .clk_i(clk),
    .rst_no(rst_n),
    .tl_i(tl_d2h),
    .tl_o(tl_h2d)
  );
    
  initial begin
    logic [31:0] rdata;
    bus.reset();

    // write pattern 00010001
    bus.put_word(32'h00000000, 32'h00000011);
    bus.get_word(32'h00000000, rdata);
    $display("read pattern: 0x%08x", rdata);
    bus.wait_cycles(50);

    // change mode to right-shift
    bus.put_word(32'h00000004, 32'h00000002);
    bus.get_word(32'h00000004, rdata);
    $display("read mode: 0x%08x", rdata);
    bus.wait_cycles(30);   

    // change cycle length
    bus.put_word(32'h00000008, 32'h00000004);
    bus.get_word(32'h00000008, rdata);
    $display("read cycleLen: 0x%08x", rdata);
    bus.wait_cycles(15);  

    // change mode to pingpong & adapt pattern
    bus.put_word(32'h00000000, 32'h00000081);
    bus.put_word(32'h00000004, 32'h00000003);
    bus.get_word(32'h00000004, rdata);
    $display("read mode: 0x%08x", rdata);
    bus.wait_cycles(75);

    // change mode to stop
    bus.put_word(32'h00000004, 32'h00000000);
    bus.wait_cycles(20);

    $finish;
  end


endmodule
