module piso_shift_reg #(
    parameter DATA_WIDTH = 32
) (
    input logic clk,
    input logic resetn,
    input logic [DATA_WIDTH-1:0] din,
    input logic din_en,
    output logic dout
);
  // your code here
  logic [DATA_WIDTH-1:0] sreg;

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      dout <= 1'b0;
      sreg <= 'b0;
    end else if (din_en) begin
      dout <= din[0];
      sreg <= din >> 1;
    end else begin
      dout <= sreg[0];
      sreg <= sreg >> 1;
    end
  end

endmodule