`timescale 1ns/1ps
module rob #(
    parameter DEPTH = 8,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  logic        clk,
    input  logic        rst_n,      // Active low reset
    input  logic        rst,        // Active high reset (from extensive test)
    
    // Dispatch Interface
    input  logic        disp_valid, 
    input  logic        dispatch_en, // Alias for disp_valid
    input  logic [4:0]  dest_reg,    // Destination register
    output logic [ADDR_WIDTH-1:0] disp_tag,
    output logic [ADDR_WIDTH-1:0] allocated_id, // Alias for disp_tag
    output logic        disp_ready,
    output logic        full,        // Alias for !disp_ready

    // Completion / Writeback Interface
    input  logic        cpl_valid,
    input  logic        wb_en,       // Alias for cpl_valid
    input  logic [ADDR_WIDTH-1:0] cpl_tag,
    input  logic [ADDR_WIDTH-1:0] wb_rob_id, // Alias for cpl_tag
    input  logic [31:0] wb_data,

    // Commit / Retire Interface
    input  logic        commit_ready,
    output logic        commit_valid,
    output logic [ADDR_WIDTH-1:0] commit_tag,
    output logic        retire_en,    // Alias for commit_valid && commit_ready
    output logic [4:0]  retire_reg,

    // Control
    input  logic        flush,
    output logic        empty
);

    // Internal Storage
    logic [DEPTH-1:0] completed;
    logic [4:0]       destination_regs [DEPTH-1:0];
    
    // Pointers
    logic [ADDR_WIDTH:0] head; // Points to the oldest instruction (for commit)
    logic [ADDR_WIDTH:0] tail; // Points to the next free slot (for dispatch)

    // Combined Resets
    logic actual_rst;
    assign actual_rst = !rst_n || rst || flush;

    // Status Signals
    assign full       = (head[ADDR_WIDTH] != tail[ADDR_WIDTH]) && 
                        (head[ADDR_WIDTH-1:0] == tail[ADDR_WIDTH-1:0]);
    assign empty      = (head == tail);
    assign disp_ready = !full;

    // Dispatch logic
    assign disp_tag     = tail[ADDR_WIDTH-1:0];
    assign allocated_id = disp_tag;

    // Commit logic
    assign commit_valid = !empty && completed[head[ADDR_WIDTH-1:0]];
    assign commit_tag   = head[ADDR_WIDTH-1:0];
    assign retire_en    = commit_valid && commit_ready;
    assign retire_reg   = destination_regs[head[ADDR_WIDTH-1:0]];

    integer i;
    always_ff @(posedge clk) begin
        if (actual_rst) begin
            head      <= 0;
            tail      <= 0;
            completed <= 0;
            for (i = 0; i < DEPTH; i = i + 1) destination_regs[i] <= 0;
        end else begin
            // 1. Dispatch (In-Order)
            if ((disp_valid || dispatch_en) && !full) begin
                destination_regs[tail[ADDR_WIDTH-1:0]] <= (dispatch_en) ? dest_reg : 5'b0;
                completed[tail[ADDR_WIDTH-1:0]]        <= 1'b0;
                tail <= tail + 1;
            end

            // 2. Completion (Out-of-Order)
            if (cpl_valid || wb_en) begin
                if (wb_en) completed[wb_rob_id] <= 1'b1;
                else       completed[cpl_tag]    <= 1'b1;
            end

            // 3. Commit (In-Order)
            if (retire_en || (commit_ready && commit_valid)) begin
                completed[head[ADDR_WIDTH-1:0]] <= 1'b0;
                head <= head + 1;
            end
        end
    end

endmodule
