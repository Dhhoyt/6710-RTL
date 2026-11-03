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

  function automatic [ENTRIES*LUT_OUTPUT_BITS-1:0] generate_lut;
    input integer unused;
    integer i;
    real amplitude, a;
    begin
      amplitude    = (2.0 ** (LUT_OUTPUT_BITS-1)) - 1.0;
      generate_lut = 0;
      for (i = 0; i < ENTRIES; i = i + 1) begin
        a = 6.283185307179586 * i / (4.0 * LUT_SIZE);  // 2*pi*i / 2^N
        generate_lut[i*LUT_OUTPUT_BITS+:LUT_OUTPUT_BITS] = $rtoi($floor($sin(a) * amplitude + 0.5));
      end
    end
  endfunction

  localparam integer [ENTRIES*LUT_OUTPUT_BITS-1:0] LUT = generate_lut(0);

  wire [                1:0] quadrant = angle[ANGLE_RESOLUTION_BITS-1-:2];
  wire [       IDX_BITS-1:0] idx = angle[IDX_BITS-1:0];
  wire [         IDX_BITS:0] idx_mir = LUT_SIZE - idx;  // ranges 1..LUT_SIZE

  wire [LUT_OUTPUT_BITS-1:0] direct = LUT[idx*LUT_OUTPUT_BITS+:LUT_OUTPUT_BITS];  // S(x)
  wire [LUT_OUTPUT_BITS-1:0] mirror = LUT[idx_mir*LUT_OUTPUT_BITS+:LUT_OUTPUT_BITS];  // S(90-x)

  always @* begin
    case (quadrant)
      2'd0: begin
        sin_val = direct;
        cos_val = mirror;
      end  // 0-90
      2'd1: begin
        sin_val = mirror;
        cos_val = -direct;
      end  // 90-180
      2'd2: begin
        sin_val = -direct;
        cos_val = -mirror;
      end  // 180-270
      2'd3: begin
        sin_val = -mirror;
        cos_val = direct;
      end  // 270-360
    endcase
  end
endmodule

