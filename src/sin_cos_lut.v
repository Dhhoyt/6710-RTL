// Encodes exp(-2*pi*j*angle / 2^ANGLE_RESOLUTION_BITS).
module sin_cos_lut #(
    parameter integer ANGLE_RESOLUTION_BITS = 8,  // must be >= 3
    parameter integer LUT_OUTPUT_BITS       = 8
) (
    input  wire [ANGLE_RESOLUTION_BITS-1:0] angle,
    output reg  [      LUT_OUTPUT_BITS-1:0] sin_val,  // two's complement
    output reg  [      LUT_OUTPUT_BITS-1:0] cos_val
);

  localparam integer IDX_BITS = ANGLE_RESOLUTION_BITS - 2;
  localparam integer LUT_SIZE = 1 << IDX_BITS;              // samples per quadrant
  localparam integer ENTRIES  = LUT_SIZE + 1;               // +1 for the 90-degree peak

  // Q1.15 sine values for 0 through pi/2, inclusive.  A literal ROM is
  // accepted by both ModelSim and synthesis; the output is rescaled below.
  localparam logic [1039:0] LUT_Q15 = 1040'h7fff7ff57fd87fa67f617f097e9c7e1d7d897ce37c297b5c7a7c79897884776b7641750473b5725470e26f5e6dc96c236a6d68a666cf64e862f160eb5ed75cb35a82584255f5539b51334ebf4c3f49b4471c447a41ce3f173c56398c36ba33df30fb2e112b1f2826252822231f1a1c0b18f915e212c80fab0c8c096a064803240000;

  wire [                1:0] quadrant = angle[ANGLE_RESOLUTION_BITS-1-:2];
  wire [       IDX_BITS-1:0] idx = angle[IDX_BITS-1:0];
  wire [         IDX_BITS:0] idx_mir = LUT_SIZE - idx;  // ranges 1..LUT_SIZE

  // The literal table is sampled at 8-bit angle resolution.  Smaller FFTs
  // select the corresponding subset of those samples (for example, an
  // 8-point FFT uses indices 0, 32, and 64 for 0, 45, and 90 degrees).
  wire [6:0] direct_index = idx << (8 - ANGLE_RESOLUTION_BITS);
  wire [6:0] mirror_index = idx_mir << (8 - ANGLE_RESOLUTION_BITS);
  wire [15:0] direct_q15 = LUT_Q15[direct_index*16+:16];
  wire [15:0] mirror_q15 = LUT_Q15[mirror_index*16+:16];
  wire [LUT_OUTPUT_BITS-1:0] direct =
      (direct_q15 * ((1 << (LUT_OUTPUT_BITS-1)) - 1) + 16383) / 32767;
  wire [LUT_OUTPUT_BITS-1:0] mirror =
      (mirror_q15 * ((1 << (LUT_OUTPUT_BITS-1)) - 1) + 16383) / 32767;

  always_comb begin
    case (quadrant)
      2'd0: begin
        sin_val = -direct;
        cos_val = mirror;
      end  // 0-90
      2'd1: begin
        sin_val = -mirror;
        cos_val = -direct;
      end  // 90-180
      2'd2: begin
        sin_val = direct;
        cos_val = -mirror;
      end  // 180-270
      2'd3: begin
        sin_val = mirror;
        cos_val = direct;
      end  // 270-360

      // unreachable
      default: begin
        sin_val = 0;
        cos_val = 0;
      end
    endcase
  end
endmodule
