// https://learn.sparkfun.com/tutorials/midi-tutorial/hardware--electronic-implementation

module syn_midi_parser # (
  parameter int VELOCITY = 128
) (
  input logic clk_i,
  input logic rst_ni,

  input logic [7:0] pmod_a,

  output logic irq_midi_pending,

  output tlul_pkg::tl_d2h_t tl_o,
  input  tlul_pkg::tl_h2d_t tl_i
);
  //////////////////////////////
  // REGISTER INTERFACE BEGIN //
  //////////////////////////////
  import syn_midi_parser_reg_pkg::*;

  syn_midi_parser_hw2reg_t hw2reg;
  syn_midi_parser_reg2hw_t reg2hw;

  syn_midi_parser_reg_top reg_top_i (
    .clk_i,
    .rst_ni,
    .tl_i,
    .tl_o,
    .reg2hw,
    .hw2reg,
    .devmode_i('1)
  );

  ////////////////////////////
  // REGISTER INTERFACE END //
  ////////////////////////////

  typedef enum logic {
    NOTE_OFF,
    NOTE_ON
  } message_t;

  typedef enum logic[1:0] {
    IDLE,
    START,
    DATA,
    STOP
  } byte_state_t;

  typedef enum logic[1:0] {
    WAITING,
    STATUS_BYTE,
    NOTE_BYTE,
    VELOCITY_BYTE
  } parsing_state_t; 

  // clock frquency of the midi controller 
  localparam int BAUD_RATE = 31250; 
  localparam int CLOCK_FREQ = 48_000_000;
  localparam int BIT_TICKS = CLOCK_FREQ / BAUD_RATE; // 1600

  // FSM registers
  byte_state_t byte_state;
  parsing_state_t status_parsingstate;
  logic midi_rx;
  logic midi_rx_R; // double register the incoming data to avoid metastability
  logic [4:0] bit_index;
  logic [15:0] tick_count;   // < 2048
  logic [7:0] status;          // 1[3 bit message][4 bit channel number] 
  logic [7:0] data1;           // 0[7 bit note: in our simple synthesizer] 
  logic [7:0] data2;           // 0[7 bit velocity: in our simple synthesizer]
  logic [7:0] midi_byte;

  // reading a bit multiple times to ensure that the bit is stable
  localparam int READ_REPEAT = 5; // number of times to read the bit to ensure stability. should be odd number
  localparam int THRESHHOLD = READ_REPEAT/2 + 1;  // e.g, for READ_REPEAT = 3, THRESHHOLD = 2 or for READ_REPEAT = 5, THRESHHOLD = 3 which means that the bit must be stable for 3 out of 5 reads
  localparam int SUM_SIZE = 2; // $clog2(MEM_DEPTH);  
  logic [SUM_SIZE:0] sum; // e.g., for READ_REPEAT = 3, sum is 2 bits wide, and if sum >= THRESHHOLD , then bit is 1 else bit is 0
  logic [SUM_SIZE:0] read_count; // count the number of times the bit is read

  assign hw2reg.status_output.midi_channel.d = status[3:0];
  assign hw2reg.status_output.event_type.d = status[6:4];
  assign hw2reg.status_output.data_1.d = {1'b0, data1[6:0]};
  assign hw2reg.status_output.data_2.d = {1'b0, data2[6:0]};
  assign hw2reg.status_parsingstate.d = status_parsingstate;

  // Double-register the incoming data
  // it can now be used in the UART-receiver's clock domain
  // counter metastability
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      midi_rx_R <= 1;
      midi_rx   <= 1;
    end else begin
      midi_rx_R   <= pmod_a[2];
      midi_rx     <= midi_rx_R;
    end
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      irq_midi_pending <= 0;
      status_parsingstate <= WAITING;
      byte_state   <= IDLE;
      tick_count   <= '0;
      status       <= '0;
      data1        <= '1;
      data2        <= '1;
      midi_byte    <= '0;
      sum          <= '0;
      read_count   <= '0;
      bit_index    <= '0;
    end else begin
      irq_midi_pending <= irq_midi_pending && ~reg2hw.status_output.event_type.re;
      case (byte_state)
        IDLE: begin
          if (midi_rx == 1'b0) begin                 // detect start bit (low)
            byte_state  <= START;
            midi_byte   <= '0;
            tick_count  <= BIT_TICKS / 2;  // sample in middle of bit
            read_count  <= '0;
            sum         <= '0;
          end else begin
            byte_state   <= IDLE; // wait for start bit
          end
        end
        START: begin
          if (tick_count == 0 || read_count > 0) begin
            if (read_count == READ_REPEAT) begin
              if (sum >= THRESHHOLD) begin
                byte_state <= IDLE;
              end else begin
                byte_state <= DATA;
                tick_count <= BIT_TICKS - 1;  // to see n ticks must set to n-1 
                if (status_parsingstate == WAITING) begin // check if we are waiting for a new midi message or its a continuation of the previous one
                  status_parsingstate <= STATUS_BYTE;
                end
                bit_index <= '0;
                midi_byte <= '0;
              end
              read_count <= 0;
              sum <= '0; // reset sum after reading the bit
            end else begin
              read_count <= read_count + 1;
              sum <= sum + midi_rx; // accumulate the value of the bit
            end
          end else begin
            tick_count <= tick_count - 1;
          end
        end
        DATA: begin
          if (tick_count == 0 || read_count > 0) begin
            if (read_count == READ_REPEAT) begin
              if (sum >= THRESHHOLD) begin
                midi_byte <= {1'b1, midi_byte[7:1]};
              end else begin
                midi_byte <= {1'b0, midi_byte[7:1]};
              end
              tick_count <= BIT_TICKS - 1;
              bit_index <= bit_index + 1;
              if (bit_index == 7) begin
                byte_state <= STOP;
              end 
              read_count <= 0;
              sum <= '0; // reset sum after reading the bit
            end else begin
              read_count <= read_count + 1;
              sum <= sum + midi_rx; // accumulate the value of the bit
            end
          end else begin
            tick_count <= tick_count - 1;
          end
        end
        STOP: begin
          if (tick_count == 0 || read_count > 0) begin
            if (read_count == READ_REPEAT) begin
              if (sum >= THRESHHOLD) begin
                // set the midi message registers
                bit_index <= 0;
                if (status_parsingstate == STATUS_BYTE || midi_byte[7] == 1'b1) begin
                  status_parsingstate <= NOTE_BYTE;
                  status <= midi_byte;
                end else if (status_parsingstate == NOTE_BYTE) begin
                  status_parsingstate <= VELOCITY_BYTE;
                  data1 <= midi_byte;
                end else begin
                  status_parsingstate <= WAITING;
                  irq_midi_pending <= 1;
                  data2 <= midi_byte;
                end
              end else begin
                status_parsingstate <= WAITING;
              end
              byte_state <= IDLE;
              tick_count <= BIT_TICKS - 1;
              read_count <= 0;
              sum <= '0; // reset sum after reading the bit
            end else begin
              read_count <= read_count + 1;
              sum <= sum + midi_rx; // accumulate the value of the bit
            end
          end else begin
            tick_count <= tick_count - 1;
          end
        end
      endcase
    end
  end

endmodule
