# 6710-RTL

## FFT interface

The FFT is a synchronous, forward radix-2 transform. `BLOCK_SIZE_POWER` sets
the number of complex samples to `2**BLOCK_SIZE_POWER` (default: 256). The
supported minimum is 3, matching the twiddle LUT. Each component is a signed
two's-complement fixed-point word with `DECIMAL_WIDTH` fractional bits and
`INTEGER_WIDTH` integer bits including the sign (defaults: 8 and 8).

`rst` is synchronous and aborts any transaction. All interface signals use
`clk`; the serial stream is not UART or I2S and has no baud-rate generator,
start bits, or backpressure. The sender and receiver must share the clock.

* When `input_ready` is high, assert `begin_input` for a rising edge. Starting
  with the **next** rising edge, supply one input bit per clock, MSB first:
  real then imaginary, for each sample in natural order. Send exactly
  `2 * BLOCK_SIZE * WIDTH` consecutive bits.
* Once processing completes, `output_ready` is high. To read the result, assert
  `begin_output` for a rising edge while `output_ready` is high and
  `begin_input` is low. The first output bit is driven immediately after the
  next rising edge and may be sampled on the following rising edge. Subsequent
  bits follow on every clock, MSB first, with real and imaginary words
  interleaved in natural frequency-bin order. There are exactly
  `2 * BLOCK_SIZE * WIDTH` bits; `data_out` is zero when not transmitting.
* While results are waiting, `input_ready` is also high. Starting a new input
  block instead discards the unread result. If both begin signals are high,
  input takes priority. Start requests when the respective ready signal is low
  are ignored. After the last output word is loaded, `input_ready` can rise
  while its final bits are still being transmitted.

Arithmetic wraps on overflow; there is no per-stage scaling, saturation, or
overflow flag. Input magnitudes must leave enough headroom for growth across
the FFT. Each twiddle is a signed Q1.(WIDTH-1) approximation, and each
fixed-point product is truncated before the butterfly additions. Truncation
errors can accumulate across a block, particularly for very small input values.

Run `make test` for component and end-to-end simulations. The FFT tests
compare 8-, 16-, and 256-point serial transactions against a direct DFT and
a bit-exact reference. Each size includes a real sine wave at every integer
bin frequency and 128 reproducible blocks of complex random noise. Protocol
edge cases are also exercised with 8- and 16-bit words by `make protocol`.
The sample memory uses asynchronous reads; FPGA memory inference and the
real-valued LUT-generation function should be checked for the target toolchain.
