// =======================================================
// ECE251B - Computer Architecture
// Prof. Rob Marano
// Author: Hoseon Yu & Evan Dong
//
// direct mapped cache
// =======================================================

`ifndef CACHEDIRECT
`define CACHEDIRECT

`timescale 1ns/100ps

module cache_directMapped(
    input  logic        clk, reset,

    input  logic [15:0] addr,        // from aluoutM
    input  logic [15:0] writedata,   // from writedataM
    input  logic        memwrite,    // SW
    input  logic        memread,     // LW (memtoregM)
    output logic [15:0] readdata,    // to readdataM
    output logic        stall,       // to hazard unit

    output logic [15:0] mem_addr,
    output logic [15:0] mem_writedata,
    output logic        mem_write,
    output logic        mem_read,
    input  logic [15:0] mem_readdata,
    input  logic        mem_ready,

    // for gtkwave
    output logic        dbg_hit,
    output logic [1:0]  dbg_state,
    output logic [2:0]  dbg_index,
    output logic [11:0] dbg_tag
);

// ------- Cache structure ------- 
// 8 blocks, each contains 1 valid, 12 tag bits, 16 data bits
logic        validArray [0:7];
logic [11:0] tagArray   [0:7];
logic [15:0] dataArray  [0:7];

// ------- Parsing Address ------- 
// [15:4]: tag, [3:1]: index, offset ignored
logic [11:0] tag;
logic [2:0] index;

assign tag = addr[15:4];
assign index = addr [3:1];

// ------- Hit / Miss Logic -------
logic hit, miss;

assign hit = validArray[index] && (tagArray[index] == tag);
assign miss = (memread || memwrite) && !hit;
assign readdata = hit ? dataArray[index] : 16'bx;

assign dbg_hit   = hit;
assign dbg_state = state;
assign dbg_index = addrIndex;
assign dbg_tag   = addrTag;

// ------- Main Memory & FSM logic -------
typedef enum logic { IDLE, FETCHING } state_t;
state_t state, nextState;

// IDLE: normal operation
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        for (int i = 0; i < 8; i++) begin
            validArray[i] <= 16'b0;
            tagArray[i] <= 16'b0;
            dataArray <= 16'b0;
        end
    end else begin
        state <= nextState;

        // if Hit and memory write, update the cache
        if (memwrite && hit) begin
            dataArray[index] <= writedata;
        end

        // if it missed, you should put the data in to the cache
        // in fetch it returns data, so we can now fill that in
        if (state == FETCHING && mem_ready) begin
            validArray[index] <= 1'b1;
            tagArray[index] <= tag;
            dataArray[index] <= memwrite ? writedata : mem_readdata;
        end
    end
end

always_comb begin
    nextState = state;
    stall    = 0;
    mem_addr = addr;
    mem_writedata = writedata;
    mem_write = 0;
    mem_read = 0;

    case (state)
        IDLE: begin
            if (memread && !hit) begin
                // read miss — go fetch from memory
                stall      = 1'b1;
                mem_read   = 1'b1;
                next_state = FETCH;
            end else if (memwrite && hit) begin
                // write hit — write through to memory
                mem_write  = 1'b1;
            end else if (memwrite && !hit) begin
                // write miss — write to memory only (no-allocate)
                mem_write  = 1'b1;
            end
        end

        FETCH: begin
            // stall CPU until memory responds
            stall      = 1'b1;
            mem_read   = 1'b1;
            nextstate = IDLE; // dmem responds in 1 cycle
            end
    endcase
end

endmodule

`endif
