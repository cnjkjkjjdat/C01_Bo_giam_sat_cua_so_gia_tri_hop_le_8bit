// C01 mentor reference proposal.
// Freeze official student interface only after checking official C01 HTML.

module c01_window_monitor (
    input  logic [7:0] sample_in,
    input  logic [7:0] min_val,
    input  logic [7:0] max_val,
    output logic       below,
    output logic       inside,
    output logic       above,
    output logic       config_error
);
    always_comb begin
        config_error = (min_val > max_val);

        below  = 1'b0;
        inside = 1'b0;
        above  = 1'b0;

        if (!config_error) begin
            below  = (sample_in < min_val);
            above  = (sample_in > max_val);
            inside = !below && !above;
        end
    end
endmodule
