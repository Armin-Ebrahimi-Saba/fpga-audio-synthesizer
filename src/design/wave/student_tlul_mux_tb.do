onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /student_tlul_mux_tb/CONNECTED_SLAVES
add wave -noupdate /student_tlul_mux_tb/SHIFTOUT_OFFSET
add wave -noupdate /student_tlul_mux_tb/SHIFTIN_OFFSET
add wave -noupdate /student_tlul_mux_tb/SHIFTCFG_OFFSET
add wave -noupdate /student_tlul_mux_tb/clk
add wave -noupdate /student_tlul_mux_tb/rst_n
add wave -noupdate /student_tlul_mux_tb/tl_host_d2h
add wave -noupdate /student_tlul_mux_tb/tl_host_h2d
add wave -noupdate /student_tlul_mux_tb/tl_device_d2h
add wave -noupdate /student_tlul_mux_tb/tl_device_h2d
add wave -noupdate -divider 2
add wave -noupdate /student_tlul_mux_tb/CONNECTED_SLAVES
add wave -noupdate /student_tlul_mux_tb/SHIFTOUT_OFFSET
add wave -noupdate /student_tlul_mux_tb/SHIFTIN_OFFSET
add wave -noupdate /student_tlul_mux_tb/SHIFTCFG_OFFSET
add wave -noupdate /student_tlul_mux_tb/clk
add wave -noupdate /student_tlul_mux_tb/rst_n
add wave -noupdate /student_tlul_mux_tb/tl_host_d2h
add wave -noupdate /student_tlul_mux_tb/tl_host_h2d
add wave -noupdate /student_tlul_mux_tb/tl_device_d2h
add wave -noupdate /student_tlul_mux_tb/tl_device_h2d
add wave -noupdate -divider bus
add wave -noupdate -expand /student_tlul_mux_tb/DUT/tl_host_o
add wave -noupdate -expand /student_tlul_mux_tb/DUT/tl_host_i
add wave -noupdate -expand -subitemconfig {{/student_tlul_mux_tb/DUT/tl_device_o[1]} -expand {/student_tlul_mux_tb/DUT/tl_device_o[0]} -expand} /student_tlul_mux_tb/DUT/tl_device_o
add wave -noupdate /student_tlul_mux_tb/DUT/tl_device_i
add wave -noupdate /student_tlul_mux_tb/DUT/device_sel
add wave -noupdate /student_tlul_mux_tb/DUT/device_sel_valid
add wave -noupdate /student_tlul_mux_tb/DUT/error_response
add wave -noupdate -divider {New Divider}
add wave -noupdate -expand /student_tlul_mux_tb/#ublk#43933410#54/addr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {425384724 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 261
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits fs
update
WaveRestoreZoom {67607750 fs} {554063326 fs}
