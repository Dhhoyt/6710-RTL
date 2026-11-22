# Run from the repository root with: do testing/modelsim_gate.do
# This selects the newest timestamped Genus netlist automatically.
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

add wave -divider "Interface"
add wave /fft_gate_tb/clk /fft_gate_tb/rst
add wave /fft_gate_tb/begin_input /fft_gate_tb/data_in /fft_gate_tb/input_ready
add wave /fft_gate_tb/output_ready /fft_gate_tb/begin_output /fft_gate_tb/data_out
add wave -divider "Self-checker"
add wave -radix hexadecimal /fft_gate_tb/received_word /fft_gate_tb/expected_word
add wave -radix unsigned /fft_gate_tb/sample /fft_gate_tb/component
