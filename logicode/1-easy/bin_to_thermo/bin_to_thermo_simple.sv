module bin_to_thermo #(
    parameter DIN_WIDTH = 8
) (
    input  logic [DIN_WIDTH-1:0] din,
    output logic [2**DIN_WIDTH-1:0] dout
);

  localparam int DOUT_WIDTH = 2**DIN_WIDTH;

  always_comb begin
    dout = '0;

    for (int i = 0; i < DOUT_WIDTH; i++) begin
      if (i <= din)
        dout[i] = 1'b1;
    end
  end

endmodule