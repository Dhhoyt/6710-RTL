# Run from the repository root with: do testing/modelsim_rtl.do
if {[file exists work]} {vdel -lib work -all}
vlib work
vlog -sv src/fixed_point_multiply.v src/dff.v src/mux.v src/sin_cos_lut.v src/transform_indexer.v src/butterfly_unit.v src/controller.v src/fft.v testing/fft_gate_tb.v
vsim -voptargs=+acc work.fft_gate_tb

add wave -divider "Interface"
add wave /fft_gate_tb/clk /fft_gate_tb/rst
add wave /fft_gate_tb/begin_input /fft_gate_tb/data_in /fft_gate_tb/input_ready
add wave /fft_gate_tb/output_ready /fft_gate_tb/begin_output /fft_gate_tb/data_out
add wave -divider "Self-checker"
add wave -radix hexadecimal /fft_gate_tb/received_word /fft_gate_tb/expected_word
add wave -radix unsigned /fft_gate_tb/sample /fft_gate_tb/component
