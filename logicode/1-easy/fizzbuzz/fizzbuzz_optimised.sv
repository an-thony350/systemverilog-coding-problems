// Generates FizzBuzz flags for a repeating count from 0 to MAX_CYCLES.
module fizzbuzz #(
    parameter FIZZ = 3,
    parameter BUZZ = 5,
    parameter MAX_CYCLES = 100
) (
    input  logic clk,
    input  logic resetn,
    output logic fizz,
    output logic buzz,
    output logic fizzbuzz
);

  generate
    // Optimised implementation for the standard 3, 5 and 100 configuration.
    if (FIZZ == 3 && BUZZ == 5 && MAX_CYCLES == 100) begin : gen_fast_default

      logic [3:0] phase;   // count mod 15: 0..14
      logic [2:0] group;   // 15-cycle group: 0..6
      logic       final_q; // high when current visible count is 100

      // Divisibility by 3 and 5 depends only on the position
      // within the repeating 15-cycle pattern.
      assign fizz =
          (phase == 4'd0)  ||
          (phase == 4'd3)  ||
          (phase == 4'd6)  ||
          (phase == 4'd9)  ||
          (phase == 4'd12);

      assign buzz =
          (phase == 4'd0)  ||
          (phase == 4'd5)  ||
          (phase == 4'd10);

      assign fizzbuzz = (phase == 4'd0);

      always_ff @(posedge clk) begin
        if (!resetn) begin
          phase   <= 4'd0;
          group   <= 3'd0;
          final_q <= 1'b0;
        end else if (final_q) begin
          // Restart after count 100 has been visible for one cycle.
          phase   <= 4'd0;
          group   <= 3'd0;
          final_q <= 1'b0;
        end else begin

          // Count 99 is group=6, phase=9.
          // Therefore, after this edge, count will be 100.
          final_q <= (group == 3'd6) && (phase == 4'd9);

          if (phase == 4'd14) begin
            phase <= 4'd0;
            group <= group + 3'd1;
          end else begin
            phase <= phase + 4'd1;
          end

        end
      end

    end else begin : gen_generic_fallback

      // Generic counter widths for arbitrary parameter values.
      localparam integer CYCLE_WIDTH = (MAX_CYCLES <= 1) ? 1 : $clog2(MAX_CYCLES + 1);
      localparam integer FIZZ_WIDTH  = (FIZZ       <= 1) ? 1 : $clog2(FIZZ);
      localparam integer BUZZ_WIDTH  = (BUZZ       <= 1) ? 1 : $clog2(BUZZ);

      // Down-counters track the end of the overall sequence and
      // the next Fizz and Buzz events.
      logic [CYCLE_WIDTH-1:0] cycles_left;
      logic [FIZZ_WIDTH-1:0]  fizz_left;
      logic [BUZZ_WIDTH-1:0]  buzz_left;

      logic at_max;

      localparam logic [CYCLE_WIDTH-1:0] MAX_VALUE      = MAX_CYCLES;
      localparam logic [FIZZ_WIDTH-1:0]  FIZZ_RELOAD    = FIZZ - 1;
      localparam logic [BUZZ_WIDTH-1:0]  BUZZ_RELOAD    = BUZZ - 1;
      localparam logic [CYCLE_WIDTH-1:0] ONE_CYCLE_LEFT = 1;
      localparam logic [FIZZ_WIDTH-1:0]  ONE_FIZZ_LEFT  = 1;
      localparam logic [BUZZ_WIDTH-1:0]  ONE_BUZZ_LEFT  = 1;

      assign fizzbuzz = fizz & buzz;

      always_ff @(posedge clk) begin
        if (!resetn) begin
          cycles_left <= MAX_VALUE;
          at_max      <= 1'b0;
          fizz_left   <= '0;
          buzz_left   <= '0;
          fizz        <= 1'b1;
          buzz        <= 1'b1;
        end else begin
          if (at_max) begin
            // Restart after the final count.
            cycles_left <= MAX_VALUE;
            at_max      <= 1'b0;
            fizz_left   <= '0;
            buzz_left   <= '0;
            fizz        <= 1'b1;
            buzz        <= 1'b1;
          end else begin
            cycles_left <= cycles_left - 1'b1;
            at_max      <= (cycles_left == ONE_CYCLE_LEFT);

            // Pulse each output when its down-counter reaches one,
            // then reload it for the next interval.
            fizz      <= (fizz_left == ONE_FIZZ_LEFT);
            fizz_left <= fizz ? FIZZ_RELOAD : fizz_left - 1'b1;

            buzz      <= (buzz_left == ONE_BUZZ_LEFT);
            buzz_left <= buzz ? BUZZ_RELOAD : buzz_left - 1'b1;
          end
        end
      end

    end
  endgenerate

endmodule