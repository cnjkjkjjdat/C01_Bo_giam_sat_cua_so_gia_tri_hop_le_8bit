`timescale 1ns/1ps
module sky130_fd_sc_hd__and2_1 (output X, input A, B); assign X = A & B; endmodule
module sky130_fd_sc_hd__or2_1  (output X, input A, B); assign X = A | B; endmodule
module sky130_fd_sc_hd__nand2_1(output Y, input A, B); assign Y = ~(A & B); endmodule
module sky130_fd_sc_hd__nor2_1 (output Y, input A, B); assign Y = ~(A | B); endmodule
module sky130_fd_sc_hd__inv_1  (output Y, input A);    assign Y = ~A;      endmodule
module sky130_fd_sc_hd__xor2_1 (output X, input A, B); assign X = A ^ B;   endmodule
module sky130_fd_sc_hd__xnor2_1(output Y, input A, B); assign Y = ~(A ^ B); endmodule
