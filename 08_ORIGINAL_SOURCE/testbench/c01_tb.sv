module c01_tb;
    logic [7:0] sample_in;
    logic [7:0] min_val;
    logic [7:0] max_val;

    logic below, inside, above, config_error;
    logic below_ref, inside_ref, above_ref, config_error_ref;

    c01_window_monitor dut(.*);

    c01_reference ref_i(
        .sample_in(sample_in),
        .min_val(min_val),
        .max_val(max_val),
        .below_ref(below_ref),
        .inside_ref(inside_ref),
        .above_ref(above_ref),
        .config_error_ref(config_error_ref)
    );

    task automatic check(
        input logic [7:0] s,
        input logic [7:0] lo,
        input logic [7:0] hi
    );
        begin
            sample_in = s;
            min_val   = lo;
            max_val   = hi;
            #1;

            assert(below === below_ref)
                else $fatal(1, "below mismatch s=%0d lo=%0d hi=%0d",s,lo,hi);
            assert(inside === inside_ref)
                else $fatal(1, "inside mismatch s=%0d lo=%0d hi=%0d",s,lo,hi);
            assert(above === above_ref)
                else $fatal(1, "above mismatch s=%0d lo=%0d hi=%0d",s,lo,hi);
            assert(config_error === config_error_ref)
                else $fatal(1, "config_error mismatch");

            assert(!(below && inside))
                else $fatal(1, "below/inside overlap");
            assert(!(inside && above))
                else $fatal(1, "inside/above overlap");
            assert(!(below && above))
                else $fatal(1, "below/above overlap");

            if (!config_error)
                assert((below + inside + above) == 1)
                    else $fatal(1, "not exactly one classification");
            else
                assert({below,inside,above} === 3'b000)
                    else $fatal(1, "classification active during config error");
        end
    endtask

    initial begin
        // Official Charter boundary categories.
        check(8'd49,  8'd50, 8'd100);
        check(8'd50,  8'd50, 8'd100);
        check(8'd75,  8'd50, 8'd100);
        check(8'd100, 8'd50, 8'd100);
        check(8'd101, 8'd50, 8'd100);
        check(8'd75,  8'd100,8'd50);

        // Extra boundary cases.
        check(8'd0,   8'd0,   8'd0);
        check(8'd255, 8'd255, 8'd255);
        check(8'd0,   8'd0,   8'd255);
        check(8'd255, 8'd0,   8'd255);

        // Representative exhaustive sample sweeps.
        for (int lo=0; lo<256; lo+=17)
            for (int hi=lo; hi<256; hi+=19)
                for (int s=0; s<256; s++)
                    check(s[7:0],lo[7:0],hi[7:0]);

        $display("C01 functional verification PASS");
        $finish;
    end
endmodule
