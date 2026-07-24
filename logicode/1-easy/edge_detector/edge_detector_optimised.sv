// Produces a one-cycle pulse when din changes from low to high.
module edge_detector (
    input  logic clk,
    input  logic resetn,
    input  logic din,
    output logic dout
);

    // Stores the current and previous sampled values of din.
    logic [1:0] din_history;

    always_ff @(posedge clk) begin
        // Masking din with resetn shifts zeros into the history during reset.
        din_history <= {din_history[0], din & resetn};
    end

    // High for one cycle when the latest sample is 1
    // and the preceding sample was 0.
    assign dout = din_history[0] & ~din_history[1];

endmodule