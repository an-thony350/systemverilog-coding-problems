// Generate divide-by-2, divide-by-4 and divide-by-6 square waves
// from a common input clock.
module divide_by_evens_clock (
    input  logic clk,
    input  logic resetn,
    output logic div2,
    output logic div4,
    output logic div6
);

  // Two-bit state for the mod-3 counter used by div6.
  logic cnt6_0;
  logic cnt6_1;

  // The counter reaches its terminal state once every three cycles.
  wire cnt6_terminal = cnt6_1 & ~cnt6_0;  // state 2'b10

  always_ff @(posedge clk) begin
    if (!resetn) begin
      div2   <= 1'b0;
      div4   <= 1'b0;
      div6   <= 1'b0;

      // Start in the terminal state so div6 toggles
      // on the first cycle after reset.
      cnt6_1 <= 1'b1;
      cnt6_0 <= 1'b0;
    end else begin
      // Toggle every input cycle, giving clk / 2.
      div2 <= ~div2;

      // Toggle every second input cycle, giving clk / 4.
      // The old value of div2 is used because these are
      // non-blocking assignments.
      if (!div2) begin
        div4 <= ~div4;
      end

      // Toggle every third input cycle, giving clk / 6.
      if (cnt6_terminal) begin
        div6 <= ~div6;
      end

      // Minimized mod-3 state sequence:
      // 10 -> 00 -> 01 -> 10 -> ...
      cnt6_1 <= cnt6_0;
      cnt6_0 <= ~cnt6_1 & ~cnt6_0;
    end
  end

endmodule