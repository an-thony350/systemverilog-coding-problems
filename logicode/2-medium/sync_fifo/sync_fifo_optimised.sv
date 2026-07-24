// Parameterised synchronous FIFO with registered output data and occupancy count.
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

  // Pointer width only needs to address entries 0 to DEPTH-1.
  // Count needs one extra bit so that it can represent DEPTH itself.
  localparam int unsigned PTR_WIDTH   = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
  localparam int unsigned COUNT_WIDTH = $clog2(DEPTH) + 1;

  localparam logic [PTR_WIDTH-1:0]   LAST_ADDR         = DEPTH - 1;
  localparam logic [COUNT_WIDTH-1:0] DEPTH_COUNT       = DEPTH;
  localparam logic [COUNT_WIDTH-1:0] ALMOST_FULL_COUNT = DEPTH - 1;

  // Power-of-two depths get pointer wraparound for free through overflow.
  localparam bit DEPTH_IS_POW2 = (DEPTH == (1 << PTR_WIDTH));

  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  logic [PTR_WIDTH-1:0] wr_ptr;
  logic [PTR_WIDTH-1:0] rd_ptr;

  // Duplicate status flags to reduce fanout.
  // full/empty are the public output copies.
  (* keep = "true" *) logic full_ptr;
  (* keep = "true" *) logic empty_ptr;
  (* keep = "true" *) logic full_cnt;
  (* keep = "true" *) logic empty_cnt;

  // Separate accepted-operation signals avoid creating one shared
  // high-fanout write or read enable.
  logic wr_fire_ptr;
  logic rd_fire_ptr;
  logic wr_fire_cnt;
  logic rd_fire_cnt;

  logic inc_only;
  logic dec_only;

  logic one_left;
  logic almost_full;

  // Pointer and memory control use their local copies of the flags.
  assign wr_fire_ptr = wr_en && !full_ptr;
  assign rd_fire_ptr = rd_en && !empty_ptr;

  // Occupancy tracking uses separate local copies.
  assign wr_fire_cnt = wr_en && !full_cnt;
  assign rd_fire_cnt = rd_en && !empty_cnt;

  // The count changes only when exactly one operation is accepted.
  assign inc_only = wr_fire_cnt && !rd_fire_cnt;
  assign dec_only = rd_fire_cnt && !wr_fire_cnt;

  // Look-ahead conditions used to update the registered status flags.
  assign one_left    = (count == {{(COUNT_WIDTH-1){1'b0}}, 1'b1});
  assign almost_full = (count == ALMOST_FULL_COUNT);

  // Increment a pointer, adding explicit wrap logic only when the FIFO
  // depth is not a power of two.
  function automatic logic [PTR_WIDTH-1:0] ptr_inc(
      input logic [PTR_WIDTH-1:0] ptr
  );
    if (DEPTH_IS_POW2) begin
      ptr_inc = ptr + {{(PTR_WIDTH-1){1'b0}}, 1'b1};
    end else begin
      ptr_inc = (ptr == LAST_ADDR) ? '0
                                   : ptr + {{(PTR_WIDTH-1){1'b0}}, 1'b1};
    end
  endfunction

  always_ff @(posedge clk) begin
    if (!resetn) begin
      wr_ptr    <= '0;
      rd_ptr    <= '0;
      count     <= '0;
      rd_data   <= '0;

      full      <= 1'b0;
      empty     <= 1'b1;

      full_ptr  <= 1'b0;
      empty_ptr <= 1'b1;
      full_cnt  <= 1'b0;
      empty_cnt <= 1'b1;
    end else begin
      // Accepted writes update memory and advance the write pointer.
      if (wr_fire_ptr) begin
        mem[wr_ptr] <= wr_data;
        wr_ptr      <= ptr_inc(wr_ptr);
      end

      // Reads are synchronous: rd_data updates on the active clock edge.
      if (rd_fire_ptr) begin
        rd_data <= mem[rd_ptr];
        rd_ptr  <= ptr_inc(rd_ptr);
      end

      // Simultaneous read and write leave the occupancy unchanged.
      if (inc_only) begin
        count <= count + {{(COUNT_WIDTH-1){1'b0}}, 1'b1};
      end else if (dec_only) begin
        count <= count - {{(COUNT_WIDTH-1){1'b0}}, 1'b1};
      end

      // Use the current count to calculate what the flags should be
      // after a write-only or read-only cycle.
      if (inc_only) begin
        full      <= almost_full;
        full_ptr  <= almost_full;
        full_cnt  <= almost_full;

        empty     <= 1'b0;
        empty_ptr <= 1'b0;
        empty_cnt <= 1'b0;
      end else if (dec_only) begin
        full      <= 1'b0;
        full_ptr  <= 1'b0;
        full_cnt  <= 1'b0;

        empty     <= one_left;
        empty_ptr <= one_left;
        empty_cnt <= one_left;
      end
    end
  end

endmodule