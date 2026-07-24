// Population-count circuit: returns the number of set bits in din.
module counting_ones #(
    parameter DATA_WIDTH = 16
) (
    input  logic [DATA_WIDTH-1:0] din,
    output logic [$clog2(DATA_WIDTH):0] dout
);

  generate
    // Specialised balanced adder tree for the common 16-bit case.
    if (DATA_WIDTH == 16) begin : gen_fast_16

      // Partial counts for groups of 2, 4 and 8 input bits.
      logic [1:0] c2 [7:0];
      logic [2:0] c4 [3:0];
      logic [3:0] c8 [1:0];

      genvar i;

      // Count the ones in each pair of input bits.
      for (i = 0; i < 8; i++) begin : gen_pairs
        assign c2[i] = {1'b0, din[2*i]} + {1'b0, din[2*i+1]};
      end

      // Combine pairs to form four-bit counts.
      for (i = 0; i < 4; i++) begin : gen_quads
        assign c4[i] = {1'b0, c2[2*i]} + {1'b0, c2[2*i+1]};
      end

      // Combine the four-bit counts into eight-bit counts.
      for (i = 0; i < 2; i++) begin : gen_octets
        assign c8[i] = {1'b0, c4[2*i]} + {1'b0, c4[2*i+1]};
      end

      // Final addition gives the number of ones across all 16 bits.
      assign dout = {1'b0, c8[0]} + {1'b0, c8[1]};

    end else begin : gen_generic

      // Generic implementation used for other input widths.
      logic [$clog2(DATA_WIDTH):0] count;

      always_comb begin
        count = '0;
        for (int i = 0; i < DATA_WIDTH; i++) begin
          count = count + din[i];
        end
      end

      assign dout = count;

    end
  endgenerate

endmodule