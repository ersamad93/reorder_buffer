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

    typedef struct packed {
        logic valid;
        logic done;
    } rob_entry_t;

    rob_entry_t rob_mem [DEPTH];

    logic [TAG_W-1:0] alloc_ptr;
    logic [TAG_W-1:0] commit_ptr;
    logic [TAG_W:0]   count;

    assign disp_ready = (count < DEPTH);
    assign disp_tag   = alloc_ptr;

    assign commit_valid = rob_mem[commit_ptr].valid &&
                          rob_mem[commit_ptr].done;

    assign commit_tag = commit_ptr;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            alloc_ptr  <= '0;
            commit_ptr <= '0;
            count      <= '0;
            foreach (rob_mem[i]) begin
                rob_mem[i].valid <= 1'b0;
                rob_mem[i].done  <= 1'b0;
            end
        end else begin

            // Dispatch
            if (disp_valid && disp_ready) begin
                rob_mem[alloc_ptr].valid <= 1'b1;
                rob_mem[alloc_ptr].done  <= 1'b0;
                alloc_ptr <= alloc_ptr + 1'b1;
                count <= count + 1'b1;
            end

            // Completion (out-of-order)
            if (cpl_valid) begin
                rob_mem[cpl_tag].done <= 1'b1;
            end

            // Commit (in-order)
            if (commit_valid && commit_ready) begin
                rob_mem[commit_ptr].valid <= 1'b0;
                rob_mem[commit_ptr].done  <= 1'b0;
                commit_ptr <= commit_ptr + 1'b1;
                count <= count - 1'b1;
            end
        end
    end

endmodule