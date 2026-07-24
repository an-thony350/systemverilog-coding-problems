module divide_by_evens_clock (
    input  logic clk,
    input  logic resetn,
    output logic div2,
    output logic div4,
    output logic div6
);

  logic [3:0] phase;  // 0..11, LCM of 2, 4, and 6

  always_ff @(posedge clk) begin
    if (!resetn) begin
      phase <= 4'd0;
      div2  <= 1'b0;
      div4  <= 1'b0;
      div6  <= 1'b0;
    end else begin
      // Generate outputs from the current phase.
      // First active cycle after reset: phase == 0, so all outputs go high.
      div2 <= ~phase[0];

      div4 <= ~phase[1];

      div6 <= (phase < 4'd3) || ((phase >= 4'd6) && (phase < 4'd9));

      if (phase == 4'd11)
        phase <= 4'd0;
      else
        phase <= phase + 4'd1;
    end
  end

endmodule