module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 8
) (
    input  logic                    clk,
    input  logic                    resetn,
    input  logic                    wr_en,
    input  logic [DATA_WIDTH-1:0]   wr_data,
    input  logic                    rd_en,
    output logic [DATA_WIDTH-1:0]   rd_data,
    output logic                    full,
    output logic                    empty,
    output logic [$clog2(DEPTH):0]  count
);
  // your code here
    localparam int unsigned PTR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    localparam int unsigned COUNT_WIDTH = $clog2(DEPTH + 1);

    localparam logic [PTR_WIDTH-1:0] LAST_ADDR = DEPTH - 1;

    localparam logic [COUNT_WIDTH-1:0] DEPTH_COUNT = DEPTH;

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    logic [PTR_WIDTH-1:0]   wr_ptr;
    logic [PTR_WIDTH-1:0]   rd_ptr;

    logic write_fire;
    logic read_fire;

    assign empty = (count == '0);
    assign full  = (count == DEPTH_COUNT);

    // An operation happens only when it is legal.
    assign write_fire = wr_en && !full;
    assign read_fire  = rd_en && !empty;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            wr_ptr   <= '0;
            rd_ptr   <= '0;
            count    <= '0;
            rd_data  <= '0;
        end else begin
            // Write operation
            if (write_fire) begin
                mem[wr_ptr] <= wr_data;

                if (wr_ptr == LAST_ADDR)
                    wr_ptr <= '0;
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end

            // Read operation
            if (read_fire) begin
                rd_data  <= mem[rd_ptr];
                if (rd_ptr == LAST_ADDR)
                    rd_ptr <= '0;
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end

            // Occupancy update
            case ({write_fire, read_fire})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule