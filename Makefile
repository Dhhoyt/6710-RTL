IVERILOG ?= iverilog
VVP      ?= vvp
PYTHON   ?= python3
BUILD    := build

TESTS := sin_cos_lut

.PHONY: all test clean $(TESTS)
all: test
test: $(TESTS)

# One build rule per test: compile the testbench into $(BUILD)/<name>.vvp
$(BUILD)/sin_cos_lut.vvp: testing/sin_cos_lut_tb.v src/sin_cos_lut.v | $(BUILD)
	$(IVERILOG) -g2012 -o $@ $^

# One run rule per test: the python script simulates and checks each output line
sin_cos_lut: $(BUILD)/sin_cos_lut.vvp
	$(PYTHON) testing/test_sin_cos_lut.py

$(BUILD):
	mkdir -p $@

clean:
	rm -rf $(BUILD)
