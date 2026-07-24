// Parallel-in, serial-out shift register.
// din is loaded in parallel when din_en is high, then shifted out LSB-first.
module piso_shift_reg #(
    parameter DATA_WIDTH = 32
) (
    input  logic clk,
    input  logic resetn,
    input  logic [DATA_WIDTH-1:0] din,
    input  logic din_en,
    output logic dout
);

  logic [DATA_WIDTH-1:0] sreg;
  logic valid;

  // Keep the serial output low during reset and before the first load.
  assign dout = (resetn && valid) ? sreg[0] : 1'b0;

  // Once data has been loaded, the output is considered valid.
  // valid remains high for all later shifts.
  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn)
      valid <= 1'b0;
    else if (din_en)
      valid <= 1'b1;
  end

  genvar i;
  generate
    // Build the shift register from individual scan flip-flops.
    for (i = 0; i < DATA_WIDTH; i++) begin : gen_sreg
      logic shift_d;

      // Shift towards bit 0. The top bit shifts in a zero.
      if (i == DATA_WIDTH-1)
        assign shift_d = 1'b0;
      else
        assign shift_d = sreg[i+1];

      piso_scan_ff u_ff (
          .clk    (clk),
          .load   (din_en),
          .d_load (din[i]),
          .d_shift(shift_d),
          .q      (sreg[i])
      );
    end
  endgenerate

endmodule


// Wrapper around a scan flip-flop.
// load selects between the parallel-load input and the shift input.
module piso_scan_ff (
    input  logic clk,
    input  logic load,
    input  logic d_load,
    input  logic d_shift,
    output logic q
);

`ifdef SYNTHESIS
  // Map directly to the Sky130 scan flip-flop during synthesis.
  sky130_fd_sc_hd__sdfxtp_1 u_scan_ff (
      .CLK(clk),
      .D  (d_shift),
      .SCD(d_load),
      .SCE(load),
      .Q  (q)
  );
`else
  // Behavioural equivalent used for simulation.
  always_ff @(posedge clk) begin
    q <= load ? d_load : d_shift;
  end
`endif

endmodule