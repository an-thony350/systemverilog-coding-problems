module edge_detector (
    input  logic clk,
    input  logic resetn,
    input  logic din,
    output logic dout
);
  // your code here

  logic detected;

  always_ff @(posedge clk) begin
    if (resetn) begin
      if (detected) dout <= 0;
      else
      dout <= din;
      detected <= din;
    end 

  end
endmodule