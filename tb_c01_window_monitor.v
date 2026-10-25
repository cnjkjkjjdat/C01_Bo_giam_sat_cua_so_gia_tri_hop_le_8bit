`timescale 1ns/1ps

module tb_c01_window_monitor;
    reg  [7:0] sample_in;
    reg  [7:0] min_val;
    reg  [7:0] max_val;
    wire       below;
    wire       in_window;
    wire       above;
    wire       config_error;

    c01_window_monitor uut (
        .sample_in(sample_in),
        .min_val(min_val),
        .max_val(max_val),
        .below(below),
        .in_window(in_window),
        .above(above),
        .config_error(config_error)
    );

    initial begin
        // Ghi lại dạng sóng tín hiệu
        $dumpfile("gls_waveform.vcd");
        $dumpvars(0, tb_c01_window_monitor);

        $display("==================================================");
        $display("--- DUMPING WAVEFORM FOR GTKWAVE ---");
        $display("==================================================");

        // Test cases
        sample_in = 8'd15; min_val = 8'd10; max_val = 8'd20; #10;
        sample_in = 8'd5;  min_val = 8'd10; max_val = 8'd20; #10;
        sample_in = 8'd25; min_val = 8'd10; max_val = 8'd20; #10;
        sample_in = 8'd15; min_val = 8'd20; max_val = 8'd10; #10;

        $finish;
    end
endmodule
