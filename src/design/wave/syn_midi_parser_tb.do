onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /syn_midi_parser_tb/DUT/VELOCITY
add wave -noupdate /syn_midi_parser_tb/DUT/BAUD_RATE
add wave -noupdate /syn_midi_parser_tb/DUT/CLOCK_FREQ
add wave -noupdate /syn_midi_parser_tb/DUT/BIT_TICKS
add wave -noupdate /syn_midi_parser_tb/DUT/clk_i
add wave -noupdate /syn_midi_parser_tb/DUT/rst_ni
add wave -noupdate /syn_midi_parser_tb/DUT/pmod_a
add wave -noupdate /syn_midi_parser_tb/DUT/irq_midi_pending
add wave -noupdate /syn_midi_parser_tb/DUT/tl_o
add wave -noupdate /syn_midi_parser_tb/DUT/tl_i
add wave -noupdate /syn_midi_parser_tb/DUT/hw2reg
add wave -noupdate /syn_midi_parser_tb/DUT/reg2hw
add wave -noupdate /syn_midi_parser_tb/DUT/byte_state
add wave -noupdate /syn_midi_parser_tb/DUT/status_parsingstate
add wave -noupdate /syn_midi_parser_tb/DUT/midi_rx
add wave -noupdate /syn_midi_parser_tb/DUT/bit_index
add wave -noupdate /syn_midi_parser_tb/DUT/tick_counter
add wave -noupdate /syn_midi_parser_tb/DUT/status
add wave -noupdate /syn_midi_parser_tb/DUT/data1
add wave -noupdate /syn_midi_parser_tb/DUT/data2
add wave -noupdate /syn_midi_parser_tb/DUT/midi_byte
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1297070000000 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 213
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 fs} {2361210966229 fs}
