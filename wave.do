onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fpu_tb/clk
add wave -noupdate /fpu_tb/rst
add wave -noupdate -radix binary /fpu_tb/stim
add wave -noupdate /fpu_tb/start
add wave -noupdate -radix unsigned /fpu_tb/addr
add wave -noupdate -radix float32 /fpu_tb/fpu_dut/dp_dut/input_a
add wave -noupdate -radix float32 /fpu_tb/fpu_dut/dp_dut/input_b
add wave -noupdate -radix float32 /fpu_tb/output_z
add wave -noupdate /fpu_tb/error
add wave -noupdate -radix binary /fpu_tb/done
add wave -noupdate -radix unsigned /fpu_tb/fpu_dut/cu_dut/state
add wave -noupdate -radix unsigned /fpu_tb/fpu_dut/cu_dut/next_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {265 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
configure wave -timelineunits ns
update
WaveRestoreZoom {206 ns} {308 ns}
