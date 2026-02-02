`timescale 1ns/1ps
module rob #(
    parameter int DEPTH = 8,
    localparam int TAG_W = $clog2(DEPTH)
)(
    input  logic clk,
    input  logic rst_n,

    // Dispatch
    input  logic disp_valid,
    output logic disp_ready,
    output logic [TAG_W-1:0] disp_tag,

    // Completion
    input  logic cpl_valid,
    input  logic [TAG_W-1:0] cpl_tag,

    // Commit
    output logic commit_valid,
    input  logic commit_ready,
    output logic [TAG_W-1:0] commit_tag
);

   //Add RTL code here

endmodule
