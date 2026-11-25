module syn_echo_tb;

  logic clk;
  logic rst_n;

  import tlul_pkg::*;
  tl_h2d_t tl_i;
  tl_d2h_t tl_o;

  logic signed [15:0] in_sample;
  logic signed [15:0] out_sample;

  tlul_test_host bus (
    .clk_i (clk),
    .rst_no(rst_n),
    .tl_i  (tl_o),
    .tl_o  (tl_i)
  );

  syn_echo #(.BUFFER_SIZE(16384)) dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .tl_i(tl_i),
    .tl_o(tl_o),
    .in_sample(in_sample),
    .next_sample(clk),        //samples generated at clk speed to make simulation faster
    .out_sample(out_sample)
  );

  // ca. 48 MHz clock
  always begin
    clk = 1;
    #10417;
    clk = 0;
    #10417;
  end

  localparam int SR = 48000;

  localparam int Tc = SR / 262;
  localparam int Td = SR / 294;
  localparam int Te = SR / 330;
  localparam int Tf = SR / 349;
  localparam int Tg = SR / 392;
  localparam int Ta = SR / 440;
  localparam int Tb = SR / 494;

  logic signed [15:0] sine_c [0:Tc-1];
  logic signed [15:0] sine_d [0:Td-1];
  logic signed [15:0] sine_e [0:Te-1];
  logic signed [15:0] sine_f [0:Tf-1];
  logic signed [15:0] sine_g [0:Tg-1];
  logic signed [15:0] sine_a [0:Ta-1];
  logic signed [15:0] sine_b [0:Tb-1];


  bit bypass_echo = 1'b0;  // set to 1 to bypass the echo module


  integer fd;

  // define tasks to play specific tone
    task be_quiet (input real duration);
        for (int i = 0; i < duration*SR; i++) begin
            @(posedge clk);
            in_sample = 16'd0;
            @(negedge clk);
            $fwrite(fd, "%0d", bypass_echo ? in_sample : out_sample);
            $fwrite(fd, ",");
        end
    endtask

    task play_c (input real duration);
        for (int i = 0; i < duration*SR; i++) begin
            @(posedge clk);
            in_sample = sine_c[i % Tc];
            @(negedge clk);
            $fwrite(fd, "%0d", bypass_echo ? in_sample : out_sample);
            $fwrite(fd, ",");
        end
    endtask

    task play_d (input real duration);
        for (int i = 0; i < duration*SR; i++) begin
            @(posedge clk);
            in_sample = sine_d[i % Td];
            @(negedge clk);
            $fwrite(fd, "%0d", bypass_echo ? in_sample : out_sample);
            $fwrite(fd, ",");
        end
    endtask

    task play_e (input real duration);
        for (int i = 0; i < duration*SR; i++) begin
            @(posedge clk);
            in_sample = sine_e[i % Te];
            @(negedge clk);
            $fwrite(fd, "%0d", bypass_echo ? in_sample : out_sample);
            $fwrite(fd, ",");
        end
    endtask

    task play_f (input real duration);
        for (int i = 0; i < duration*SR; i++) begin
            @(posedge clk);
            in_sample = sine_f[i % Tf];
            @(negedge clk);
            $fwrite(fd, "%0d", bypass_echo ? in_sample : out_sample);
            $fwrite(fd, ",");
        end
    endtask

    task play_g (input real duration);
        for (int i = 0; i < duration*SR; i++) begin
            @(posedge clk);
            in_sample = sine_g[i % Tg];
            @(negedge clk);
            $fwrite(fd, "%0d", bypass_echo ? in_sample : out_sample);
            $fwrite(fd, ",");
        end
    endtask

    task play_a (input real duration);
        for (int i = 0; i < duration*SR; i++) begin
            @(posedge clk);
            in_sample = sine_a[i % Ta];
            @(negedge clk);
            $fwrite(fd, "%0d", bypass_echo ? in_sample : out_sample);
            $fwrite(fd, ",");
        end
    endtask

    task play_b (input real duration);
        for (int i = 0; i < duration*SR; i++) begin
            @(posedge clk);
            in_sample = sine_b[i % Tb];
            @(negedge clk);
            $fwrite(fd, "%0d", bypass_echo ? in_sample : out_sample);
            $fwrite(fd, ",");
        end
    endtask


  initial begin : tb_main
    automatic real pi = 3.14159265;
    real angle;
    automatic real amplitude = 32768.0;

    // sine waves for all C dur tones
    for (int i = 0; i < Tc; i++) begin
      angle = 2.0 * pi * i / Tc;
      sine_c[i] = $rtoi($sin(angle) * amplitude);
    end

    for (int i = 0; i < Td; i++) begin
      angle = 2.0 * pi * i / Td;
      sine_d[i] = $rtoi($sin(angle) * amplitude);
    end

    for (int i = 0; i < Te; i++) begin
      angle = 2.0 * pi * i / Te;
      sine_e[i] = $rtoi($sin(angle) * amplitude);
    end

    for (int i = 0; i < Tf; i++) begin
      angle = 2.0 * pi * i / Tf;
      sine_f[i] = $rtoi($sin(angle) * amplitude);
    end

    for (int i = 0; i < Tg; i++) begin
      angle = 2.0 * pi * i / Tg;
      sine_g[i] = $rtoi($sin(angle) * amplitude);
    end

    for (int i = 0; i < Ta; i++) begin
      angle = 2.0 * pi * i / Ta;
      sine_a[i] = $rtoi($sin(angle) * amplitude);
    end

    for (int i = 0; i < Tb; i++) begin
      angle = 2.0 * pi * i / Tb;
      sine_b[i] = $rtoi($sin(angle) * amplitude);
    end


    $display("Starting echo test: bypass echo = %0b", bypass_echo);

    in_sample = 0;

    fd = $fopen("../../../util/tmp/echo_output", "w");

    bus.reset();


    // play "Alle meine Entchen"
    play_c(0.25);
    play_d(0.25);
    play_e(0.25);
    play_f(0.25);
    play_g(0.25);

    // set feedback to 13
    bus.put_word(32'h00000004, 32'hf);
    // set decay to 15
    bus.put_word(32'h00000008, 32'hf);
    // set delay to 3000
    bus.put_word(32'h0000000c, 32'd12000);
    // enable echo
    bus.put_word(32'h00000000, 32'h1);


    be_quiet(0.25);
    play_g(0.25);
    be_quiet(0.25);
    play_a(0.25);
    play_a(0.25);
    play_a(0.25);
    play_a(0.25);

    //set feedback to 4
    //bus.put_word(32'h00000004, 32'h4);

    play_g(0.25);
    be_quiet(0.25);
    play_a(0.25);
    play_a(0.25);
    play_a(0.25);
    play_a(0.25);
    play_g(0.25);
    be_quiet(0.25);
    play_f(0.25);
    play_f(0.25);
    play_f(0.25);
    play_f(0.25);

    //set feedback to 13
    //bus.put_word(32'h00000004, 32'hd);

    play_e(0.25);
    be_quiet(0.25);
    play_e(0.25);
    be_quiet(0.25);

    //set decay to 4
    //bus.put_word(32'h00000008, 32'h4);

    play_g(0.25);
    play_g(0.25);
    play_g(0.25);
    play_g(0.25);

    // set delay to 16000
    //bus.put_word(32'h0000000c, 32'h3e80);

    play_c(0.25);
    be_quiet(0.75);


    be_quiet(3);

    $fclose(fd);
    $display("Test finished. Output was written to ../../../util/tmp/echo_output");
    $finish;
  end

endmodule
