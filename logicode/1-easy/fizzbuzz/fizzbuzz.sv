module fizzbuzz #(
    parameter FIZZ = 3,
    BUZZ = 5,
    MAX_CYCLES = 100
) (
    input  logic clk,
    input  logic resetn,
    output logic fizz,
    output logic buzz,
    output logic fizzbuzz
);

  logic [7:0] count;

  assign fizz     = (count % FIZZ == 0);
  assign buzz     = (count % BUZZ == 0);
  assign fizzbuzz = fizz & buzz;

  always_ff @(posedge clk) begin
    if (!resetn) begin
      count <= '0;
    end else begin
      if (count == MAX_CYCLES)
        count <= '0;
      else
        count <= count + 1'b1;
    end
  end

endmodule

