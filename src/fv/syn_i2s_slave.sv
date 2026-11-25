module syn_i2s_slave(

  input logic dac_sdata,
  input logic bclk,
  input logic lrclk,
  input logic mclk
);

    logic[15:0] l_channel_reg;
    logic[15:0] r_channel_reg;
    logic[15:0] shift_reg;
    logic[4:0] bit_cnt;
    logic lrclk_prev;
    logic switch_channel;
    logic initialized;

    assign switch_channel = lrclk != lrclk_prev;

    always_ff @(posedge bclk) begin
        if (switch_channel) begin
        bit_cnt <= 0;
        end else if (bit_cnt < 16) begin
        shift_reg <= {shift_reg[14:0], dac_sdata};
        bit_cnt <= bit_cnt + 1;
        end

        if (bit_cnt == 15) begin
            if (lrclk == 0) begin
                l_channel_reg <= {shift_reg[14:0], dac_sdata};
            end else begin
                r_channel_reg <= {shift_reg[14:0], dac_sdata};
            end
        end
        lrclk_prev <= lrclk;
    end

   //`ifndef WRITE_CODEC_OUT
        initial begin
            integer fdl;
            integer fdr;
            fdl = $fopen("../../../util/tmp/codec_out_l", "w");
            fdr = $fopen("../../../util/tmp/codec_out_r", "w");
            if (fdl && fdr) begin
                $display("Writing sample to file...");

                forever begin
                @(posedge bclk);
                    if (switch_channel) begin
                        if (lrclk_prev == 0) begin
                            $fwrite(fdl, $signed(l_channel_reg));
                            $fwrite(fdl, ",");
                        end else begin
                            $fwrite(fdr, $signed(r_channel_reg));
                            $fwrite(fdr, ",");
                        end
                    end
                end
            end
        end
   //`endif

endmodule
