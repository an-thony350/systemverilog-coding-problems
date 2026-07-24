// Simple three-state elevator controller.
// The state encoding is exposed directly through the state output.
module elevator_cont (
    input  logic       clk,
    input  logic       reset,
    input  logic       up_request,
    input  logic       down_request,
    output logic [1:0] state
);

  localparam logic [1:0] IDLE        = 2'b00;
  localparam logic [1:0] MOVING_UP   = 2'b01;
  localparam logic [1:0] MOVING_DOWN = 2'b10;

  always_ff @(posedge clk) begin
    if (reset)
      state <= IDLE;
    else
      // If both requests are high, up_request takes priority and
      // the resulting state is MOVING_UP.
      state <= {
        down_request & ~up_request,
        up_request
      };
  end

endmodule