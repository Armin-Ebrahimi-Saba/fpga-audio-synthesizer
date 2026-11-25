module syn_midi_parser_tb;
  logic clk;
  logic rst_n;
  logic irq_midi_pending;
  tlul_pkg::tl_d2h_t tl_d2h;
  tlul_pkg::tl_h2d_t tl_h2d;

  // 50 MHz
  always begin
    clk = '1;
    #10000;
    clk = '0;
    #10000;
  end


  tri [7:0] pad_tb; 
  logic [7:0] pmod_a;
  logic [7:0] pmod_a_oe;
  logic [7:0] pmod_a_out;
  iocell_bidir #(
    .Width(8)
  ) io_pmod_a (
    .pad (pad_tb),
    .oe (pmod_a_oe),
    .out (pmod_a_out),
    .in (pmod_a)
  );

  syn_midi_parser DUT (
    .clk_i (clk),
    .rst_ni (rst_n),
    .irq_midi_pending(irq_midi_pending),
    .tl_i (tl_h2d),
    .tl_o (tl_d2h),
    .pmod_a(pmod_a)

  );

  tlul_test_host bus(
    .clk_i(clk),
    .rst_no(rst_n),
    .tl_i(tl_d2h),
    .tl_o(tl_h2d)
  );    

  localparam int BAUD_RATE = 31250; 
  localparam int CLOCK_FREQ = 48_000_000;
  localparam int BIT_TICKS = CLOCK_FREQ / BAUD_RATE; // 1600

	real clk_period_us = 10_000_000_000.0 / 31250.0;  // MIDI bit period ≈ 32 us

	logic midi_rx;
	assign pad_tb[2] = midi_rx;
	// Task to send a UART byte (LSB first, 8N1)
  task send_uart_byte(input byte data);
    int i;
    begin
      // Start bit (0)
      midi_rx = 0;
      bus.wait_cycles(BIT_TICKS);

      // 8 data bits (LSB first)
      for (i = 7; i >= 0; i--) begin
        midi_rx = data[i];
        bus.wait_cycles(BIT_TICKS);
      end

      // Stop bit (1)
      midi_rx = 1;
      bus.wait_cycles(BIT_TICKS);
      $display("Sent a byte.");
    end
  endtask

  initial begin
    bus.reset();
		// Idle line is high
    pmod_a_oe = 0;
    midi_rx = 1;
    #1000000;  

    $display("Sending MIDI Note Off (Channel 0, Note 60, Velocity 0)");

    // Send 0x80, 0x3C, 0x00
    send_uart_byte(8'h80);
    send_uart_byte(8'h3C);
    send_uart_byte(8'h00);
    #10000;  

    send_uart_byte(8'h80);
    send_uart_byte(8'hBB);
    send_uart_byte(8'h66);

    #10000;  

    // bus.put_word(32'h00000008, 32'h00000004);
    // bus.get_word(32'h00000008, rdata);
    // $display("read mode: 0x%08x", rdata);
    // bus.wait_cycles(30);   

    $finish;
  end
    
endmodule
