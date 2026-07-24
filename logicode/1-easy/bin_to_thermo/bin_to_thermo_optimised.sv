// For each output index IDX, dout[IDX] is asserted when: din >= IDX
// Therefore, this implementation uses an inclusive thermometer convention:
// dout[din:0] are high and all higher-indexed bits are low.
// The input comparison is split into balanced high and low portions to avoid
// independently implementing a full DIN_WIDTH-bit comparison for every output.
module bin_to_thermo #(
    parameter DIN_WIDTH = 8
) (
    input  logic [DIN_WIDTH-1:0] din,
    output logic [2**DIN_WIDTH-1:0] dout
);

  // Divide the binary input into approximately equal low and high portions.
  //
  // For an even DIN_WIDTH, both portions have the same width.
  // For an odd DIN_WIDTH, HI_WIDTH receives the additional bit.
  //
  // Example for DIN_WIDTH = 8:
  //   LO_WIDTH = 4
  //   HI_WIDTH = 4
  localparam int LO_WIDTH = DIN_WIDTH / 2;
  localparam int HI_WIDTH = DIN_WIDTH - LO_WIDTH;

  // Number of possible values represented by each input portion.
  //
  // These also determine the dimensions of the generated output structure:
  //   HI_SIZE blocks, each containing LO_SIZE output bits.
  //
  // For DIN_WIDTH = 8:
  //   LO_SIZE = 16
  //   HI_SIZE = 16
  //   Total output bits = 16 * 16 = 256
  localparam int LO_SIZE = 2**LO_WIDTH;
  localparam int HI_SIZE = 2**HI_WIDTH;

  // Aliases for the low-order and high-order portions of din.
  //
  // Since din is equivalent to:
  //
  //   din = hi * LO_SIZE + lo
  //
  // the comparison against each output index can be performed
  // hierarchically using hi first and lo only when necessary.
  logic [LO_WIDTH-1:0] lo;
  logic [HI_WIDTH-1:0] hi;

  assign lo = din[LO_WIDTH-1:0];
  assign hi = din[DIN_WIDTH-1:LO_WIDTH];

  // Elaboration-time loop variables.
  //
  // These loops generate parallel combinational hardware; they do not
  // execute sequentially at runtime.
  genvar b, i;

  generate
    // Generate one block for every possible high-order input value.
    for (b = 0; b < HI_SIZE; b++) begin : gen_block

      // Generate one output bit for every possible low-order value
      // within the current high-order block.
      for (i = 0; i < LO_SIZE; i++) begin : gen_bit

        // Convert the two-dimensional block/bit coordinates into the
        // corresponding flat thermometer-output index.
        //
        //   IDX = b * LO_SIZE + i
        localparam int IDX = b * LO_SIZE + i;

        // Width-matched constants for the high-order and low-order
        // comparisons below.
        localparam logic [HI_WIDTH-1:0] B_VALUE = b;
        localparam logic [LO_WIDTH-1:0] I_VALUE = i;

        // IDX = 0 is always less than or equal to any unsigned din value.
        //
        // Hardwiring this bit removes all comparison logic for dout[0].
        if (b == 0 && i == 0) begin : gen_always_one
          assign dout[IDX] = 1'b1;

        // At the beginning of a block, i is zero, so the complete condition:
        //
        //   (hi > B_VALUE) |
        //   ((hi == B_VALUE) & (lo >= 0))
        //
        // simplifies because every unsigned lo value is greater than or
        // equal to zero:
        //
        //   hi >= B_VALUE
        //
        // This removes the low-order comparator for every block-start bit.
        end else if (i == 0) begin : gen_block_start
          assign dout[IDX] = (hi >= B_VALUE);

        // General comparison for IDX = b * LO_SIZE + i.
        //
        // din is greater than IDX when either:
        //
        //   1. Its high-order portion is greater than the block number, or
        //   2. Its high-order portion equals the block number and its
        //      low-order portion is greater than or equal to the bit number.
        //
        // This is equivalent to a full-width:
        //
        //   din >= IDX
        //
        // but exposes smaller, reusable comparisons to synthesis.
        end else begin : gen_general
          assign dout[IDX] = (hi > B_VALUE) |
                             ((hi == B_VALUE) & (lo >= I_VALUE));
        end

      end
    end
  endgenerate

endmodule