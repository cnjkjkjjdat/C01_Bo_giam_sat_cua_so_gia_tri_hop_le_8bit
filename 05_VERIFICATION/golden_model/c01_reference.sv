// Independent-style reference for the mentor proposal.
// Inclusive [min,max] semantics.

module c01_reference (
    input  logic [7:0] sample_in,
    input  logic [7:0] min_val,
    input  logic [7:0] max_val,
    output logic       below_ref,
    output logic       inside_ref,
    output logic       above_ref,
    output logic       config_error_ref
);
    always_comb begin
        config_error_ref = (min_val > max_val);
        below_ref  = 1'b0;
        inside_ref = 1'b0;
        above_ref  = 1'b0;

        if (!config_error_ref) begin
            if (sample_in < min_val)
                below_ref = 1'b1;
            else if (sample_in > max_val)
                above_ref = 1'b1;
            else
                inside_ref = 1'b1;
        end
    end
endmodule
