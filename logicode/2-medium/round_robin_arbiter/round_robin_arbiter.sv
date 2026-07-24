module round_robin_arbiter #(
    parameter N = 4
) (
    input  logic         clk,
    input  logic         resetn,
    input  logic [N-1:0] req,
    output logic [N-1:0] grant,
    output logic         valid
);

    localparam int INDEX_WIDTH = (N <= 1) ? 1 : $clog2(N);

    logic [INDEX_WIDTH-1:0] priority_ptr;
    logic [INDEX_WIDTH-1:0] priority_ptr_next;

    logic [N-1:0] grant_next;
    logic         valid_next;

    logic   found;
    integer base;

    always_comb begin
        grant_next        = '0;
        valid_next        = 1'b0;
        priority_ptr_next = priority_ptr;

        found = 1'b0;
        base  = priority_ptr;

        // Search from priority_ptr to N-1.
        for (int i = 0; i < N; i++) begin
            if (!found && (i >= base) && req[i]) begin
                grant_next[i] = 1'b1;
                valid_next    = 1'b1;
                found         = 1'b1;

                // The next search starts after the winner.
                if (i == N - 1)
                    priority_ptr_next = '0;
                else
                    priority_ptr_next = i + 1;
            end
        end

        // Wrap around and search from 0 to priority_ptr-1.
        for (int i = 0; i < N; i++) begin
            if (!found && (i < base) && req[i]) begin
                grant_next[i] = 1'b1;
                valid_next    = 1'b1;
                found         = 1'b1;

                if (i == N - 1)
                    priority_ptr_next = '0;
                else
                    priority_ptr_next = i + 1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!resetn) begin
            priority_ptr <= '0;
            grant        <= '0;
            valid        <= 1'b0;
        end else begin
            priority_ptr <= priority_ptr_next;
            grant        <= grant_next;
            valid        <= valid_next;
        end
    end

endmodule