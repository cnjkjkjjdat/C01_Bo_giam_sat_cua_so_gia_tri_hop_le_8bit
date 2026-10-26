`timescale 1ns/1ps

module c01_window_monitor (
    input  wire [7:0] sample_in,
    input  wire [7:0] min_val,
    input  wire [7:0] max_val,
    output wire       below,
    output wire       in_window,
    output wire       above,
    output wire       config_error
);
    wire is_below;
    wire is_above;
    wire is_cfg_err;

    assign is_below   = (sample_in < min_val);
    assign is_above   = (sample_in > max_val);
    assign is_cfg_err = (min_val > max_val);

    assign config_error = is_cfg_err;
    assign below        = is_below & ~is_cfg_err;
    assign above        = is_above & ~is_cfg_err;
    assign in_window    = ~(is_below | is_above | is_cfg_err);

endmodule
