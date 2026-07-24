// Full-adder wrapper.
// Verilator uses the behavioural model, while the standard-cell flow
// instantiates the dedicated SKY130 full-adder cell.
module fa_fast (
    input  logic a, b, cin,
    output logic sum, cout
);
`ifdef VERILATOR
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
`else
    sky130_fd_sc_hd__fa_1 u_fa (
        .A    (a),
        .B    (b),
        .CIN  (cin),
        .SUM  (sum),
        .COUT (cout)
    );
`endif
endmodule


// Half-adder wrapper used where only two bits need to be combined.
module ha_fast (
    input  logic a, b,
    output logic sum, cout
);
`ifdef VERILATOR
    assign sum  = a ^ b;
    assign cout = a & b;
`else
    sky130_fd_sc_hd__ha_1 u_ha (
        .A    (a),
        .B    (b),
        .SUM  (sum),
        .COUT (cout)
    );
`endif
endmodule


// Counts the number of asserted bits in din.
module counting_ones #(
    parameter DATA_WIDTH = 16
) (
    input  logic [DATA_WIDTH-1:0] din,
    output logic [$clog2(DATA_WIDTH):0] dout
);

  generate
    if (DATA_WIDTH == 16) begin : gen_fast_16

      // Intermediate sum and carry signals for the compressor tree.
      logic s10, s11, s12, s13, s14;
      logic c10, c11, c12, c13, c14;

      logic s20, s21, s22;
      logic c20, c21, c22;

      logic s30, s31;
      logic c30, c31, c32;

      logic s40, c40, c41;
      logic c50;

      // Stage 1: compress fifteen input bits into five sum/carry pairs.
      fa_fast f10(din[0],  din[1],  din[2],  s10, c10);
      fa_fast f11(din[3],  din[4],  din[5],  s11, c11);
      fa_fast f12(din[6],  din[7],  din[8],  s12, c12);
      fa_fast f13(din[9],  din[10], din[11], s13, c13);
      fa_fast f14(din[12], din[13], din[14], s14, c14);

      // Further compress the weight-one sums and weight-two carries.
      fa_fast f20(s10, s11, s12,     s20, c20);
      fa_fast f21(s13, s14, din[15], s21, c21);
      fa_fast f22(c10, c11, c12,     s22, c22);

      // Produce output bit 0 and carry the remaining value upward.
      ha_fast h30(s20, s21, dout[0], c30);

      fa_fast f30(c20, c21, s22, s30, c31);
      fa_fast f31(c13, c14, c30, s31, c32);

      // Produce output bit 1.
      ha_fast h40(s30, s31, dout[1], c40);

      // Compress the remaining weight-four terms.
      fa_fast f40(c22, c31, c32, s40, c41);

      // Produce the upper result bits.
      ha_fast h50(c40, s40, dout[2], c50);
      ha_fast h60(c41, c50, dout[3], dout[4]);

    end else begin : gen_generic
      // Portable fallback for widths other than 16.
      always_comb begin
        dout = '0;
        for (int i = 0; i < DATA_WIDTH; i++)
          dout = dout + din[i];
      end
    end
  endgenerate

endmodule