IVERILOG ?= iverilog
VVP      ?= vvp
PYTHON   ?= python3
BUILD    := build

TESTS := sin_cos_lut fixed_point_multiply butterfly_unit controller transform_indexer protocol fft

.PHONY: all test clean $(TESTS)
all: test
test: $(TESTS)

# One build rule per test: compile the testbench into $(BUILD)/<name>.vvp
$(BUILD)/sin_cos_lut.vvp: testing/sin_cos_lut_tb.v src/sin_cos_lut.v | $(BUILD)
	$(IVERILOG) -g2012 -o $@ $^

$(BUILD)/fixed_point_multiply.vvp: testing/fixed_point_multiply_tb.v src/fixed_point_multiply.v | $(BUILD)
	$(IVERILOG) -g2012 -o $@ $^

$(BUILD)/butterfly_unit.vvp: testing/butterfly_unit_tb.v src/butterfly_unit.v src/sin_cos_lut.v src/fixed_point_multiply.v | $(BUILD)
	$(IVERILOG) -g2012 -o $@ $^

$(BUILD)/controller.vvp: testing/controller_tb.v src/controller.v src/transform_indexer.v | $(BUILD)
	$(IVERILOG) -g2012 -o $@ $^

$(BUILD)/transform_indexer.vvp: testing/transform_indexer_tb.v src/transform_indexer.v | $(BUILD)
	$(IVERILOG) -g2012 -o $@ $^

$(BUILD)/fft_8.vvp: testing/fft_tb.v src/fft.v src/controller.v src/transform_indexer.v src/butterfly_unit.v src/sin_cos_lut.v src/fixed_point_multiply.v | $(BUILD)
	$(IVERILOG) -g2012 -s fft_tb -o $@ $^

$(BUILD)/fft_16.vvp: testing/fft_tb.v src/fft.v src/controller.v src/transform_indexer.v src/butterfly_unit.v src/sin_cos_lut.v src/fixed_point_multiply.v | $(BUILD)
	$(IVERILOG) -g2012 -s fft_tb -Pfft_tb.POWER=4 -o $@ $^

$(BUILD)/fft_256.vvp: testing/fft_tb.v src/fft.v src/controller.v src/transform_indexer.v src/butterfly_unit.v src/sin_cos_lut.v src/fixed_point_multiply.v | $(BUILD)
	$(IVERILOG) -g2012 -s fft_tb -Pfft_tb.POWER=8 -o $@ $^

$(BUILD)/protocol_8.vvp: testing/test_protocol_tb.v src/fft.v src/controller.v src/transform_indexer.v src/butterfly_unit.v src/sin_cos_lut.v src/fixed_point_multiply.v | $(BUILD)
	$(IVERILOG) -g2012 -s test_protocol_tb -Ptest_protocol_tb.WIDTH=8 -o $@ $^

$(BUILD)/protocol_16.vvp: testing/test_protocol_tb.v src/fft.v src/controller.v src/transform_indexer.v src/butterfly_unit.v src/sin_cos_lut.v src/fixed_point_multiply.v | $(BUILD)
	$(IVERILOG) -g2012 -s test_protocol_tb -o $@ $^

# One run rule per test: the python script simulates and checks each output line
sin_cos_lut: $(BUILD)/sin_cos_lut.vvp
	$(PYTHON) testing/test_sin_cos_lut.py

fixed_point_multiply: $(BUILD)/fixed_point_multiply.vvp
	$(PYTHON) testing/test_fixed_point_multiply.py

butterfly_unit: $(BUILD)/butterfly_unit.vvp
	$(PYTHON) testing/test_butterfly_unit.py

controller: $(BUILD)/controller.vvp
	$(PYTHON) testing/test_controller.py

transform_indexer: $(BUILD)/transform_indexer.vvp
	$(PYTHON) testing/test_transform_indexer.py

protocol: $(BUILD)/protocol_8.vvp $(BUILD)/protocol_16.vvp
	$(PYTHON) testing/test_protocol.py 8
	$(PYTHON) testing/test_protocol.py 16

fft: $(BUILD)/fft_8.vvp $(BUILD)/fft_16.vvp $(BUILD)/fft_256.vvp
	$(PYTHON) testing/test_fft.py 8
	$(PYTHON) testing/test_fft.py 16
	$(PYTHON) testing/test_fft.py 256


$(BUILD):
	mkdir -p $@

clean:
	rm -rf $(BUILD)
