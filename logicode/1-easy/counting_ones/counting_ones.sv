module counting_ones #(
    parameter DATA_WIDTH = 16
) (
    input logic [DATA_WIDTH-1:0] din,
    output logic [$clog2(DATA_WIDTH):0] dout
);
  // your code here
  logic [$clog2(DATA_WIDTH):0] count;

  always_comb begin
    count = 'b0;
    for (int i = 0; i < DATA_WIDTH; i++) begin
      if (din[i]) count++;
    end

  end
  
  assign dout = count; 
endmodule