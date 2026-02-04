`timescale 1ns/1ps
module rob #(
    parameter DEPTH = 8,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        rst,
    input  logic        disp_valid, 
    input  logic        dispatch_en,
    input  logic [4:0]  dest_reg,
    output logic [ADDR_WIDTH-1:0] disp_tag,
    output logic [ADDR_WIDTH-1:0] allocated_id,
    output logic        disp_ready,
    output logic        full,
    input  logic        cpl_valid,
    input  logic        wb_en,
    input  logic [ADDR_WIDTH-1:0] cpl_tag,
    input  logic [ADDR_WIDTH-1:0] wb_rob_id,
    input  logic [31:0] wb_data,
    input  logic        commit_ready,
    output logic        commit_valid,
    output logic [ADDR_WIDTH-1:0] commit_tag,
    output logic        retire_en,
    output logic [4:0]  retire_reg,
    input  logic        flush,
    output logic        empty
);
//Add RTL here
endmodule
