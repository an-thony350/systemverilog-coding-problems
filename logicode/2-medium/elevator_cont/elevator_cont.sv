module elevator_cont (
    input logic clk,
    input logic reset,
    input logic up_request,
    input logic down_request,
    output logic [1:0] state
);
  // your code here
typedef enum {IDLE, MOVING_UP, MOVING_DOWN} state_t;

state_t cur_state, next_state;

always_comb begin
  if(!reset) begin
    if (up_request) begin
      next_state <= MOVING_UP;
    end else if (down_request) begin
      next_state <= MOVING_DOWN;
    end else next_state <= IDLE;
  end else next_state <= IDLE;
end

always_ff @(posedge clk) begin
  if(!reset) begin
    cur_state <= next_state;
  end else begin
    cur_state <= IDLE;
  end
end

assign state = cur_state;

endmodule