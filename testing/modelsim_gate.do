# Run from the repository root with: do testing/modelsim_gate.do
# This selects the newest timestamped Genus netlist automatically.
catch {quit -sim}
set NETLIST ""
set newest -1
foreach candidate [glob -nocomplain genus/outputs_*/fft_m.v] {
    if {[file mtime $candidate] > $newest} {
        set newest [file mtime $candidate]
        set NETLIST $candidate
    }
}
if {$NETLIST eq ""} {
    error "No gate netlist found. Run: cd genus && genus -f SCRIPTS/synthesis.tcl"
}

if {[file exists work]} {vdel -lib work -all}
vlib work
vlog -sv /research/ece/lnis-teaching/Designkits/tsmc180nm/full_custom_lib/verilog/sclib_tsmc180.v
vlog -sv $NETLIST testing/fft_gate_tb.v
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
