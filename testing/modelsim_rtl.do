# Run from the repository root with: do testing/modelsim_rtl.do
catch {quit -sim}
if {[file exists work]} {vdel -lib work -all}
vlib work
vlog -sv src/fixed_point_multiply.v src/dff.v src/mux.v src/sin_cos_lut.v src/transform_indexer.v src/butterfly_unit.v src/controller.v src/fft.v testing/fft_gate_tb.v
vsim -voptargs=+acc work.fft_gate_tb
view wave

add wave -noupdate -divider "Interface"
add wave -noupdate sim:/fft_gate_tb/clk sim:/fft_gate_tb/rst
add wave -noupdate sim:/fft_gate_tb/begin_input sim:/fft_gate_tb/data_in sim:/fft_gate_tb/input_ready
add wave -noupdate sim:/fft_gate_tb/output_ready sim:/fft_gate_tb/begin_output sim:/fft_gate_tb/data_out
add wave -noupdate -divider "Self-checker"
add wave -noupdate -radix hexadecimal sim:/fft_gate_tb/received_word sim:/fft_gate_tb/expected_word
add wave -noupdate -radix unsigned sim:/fft_gate_tb/sample sim:/fft_gate_tb/component
wave refresh
