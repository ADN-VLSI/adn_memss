/*

# Purpose
This module implements a hardware reservation table designed to track memory address reservations for Load-Reserved (LR) and Store-Conditional (SC) operations. It maintains a set of active reservations and provides mechanisms to validate, invalidate, and clear entries based on incoming memory access patterns, ensuring atomic-like behavior for synchronization primitives.

### Use Case
This module is primarily used in multi-core or multi-threaded processor systems to implement atomic memory operations (Load-Reserved/Store-Conditional). When a processor executes an LR instruction, this module records the target memory address. If a subsequent store or AMO (Atomic Memory Operation) from any agent overlaps with this reserved address, the reservation is invalidated. When the processor attempts an SC instruction, this module checks if the reservation is still valid; if so, the SC succeeds, otherwise, it fails. This mechanism allows for lock-free synchronization primitives like mutexes and semaphores without requiring a global bus lock.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1      | 2026-09-15 | Adnan Sami Anirban | Initial version                                        |
| 1.0      | 2026-09-15 | Adnan Sami Anirban | Stable release                                         |

Author : Adnan Sami Anirban (adnananirban259@gmail.com)
This file is part of ADN-VLSI/adn_template
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_memss_address_reservation_table #(
    // PARAMETERS
    parameter int AW    = 32,   // Address width in bits
    parameter int DEPTH = 4     // Number of concurrent reservation entries supported
) (
    // PORTS
    input  logic          clk_i,        // System clock
    input  logic          arst_ni,      // Asynchronous reset, active low

    input  logic [AW-1:0] addr_i,       // Target address for LR/SC/Store operations
    input  logic          dword_i,      // Data size: 1 = 8-byte reservation, 0 = 4-byte

    input  logic          lr_i,         // Load-Reserved pulse: trigger new reservation entry
    input  logic          sc_i,         // Store-Conditional pulse: evaluate and clear on hit
    input  logic          store_i,      // Store/AMO write pulse: invalidate on address overlap

    output logic          sc_hit_o      // Combinational output: SC operation found a valid reservation
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS GENERATED
  //////////////////////////////////////////////////////////////////////////////////////////////////
  localparam int IDXW = (DEPTH > 1) ? $clog2(DEPTH) : 1;
  localparam int SEQW = IDXW + 1;   // Sequence counter width for age tracking
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Reservation entry storage arrays
  logic [AW-1:0]   ent_addr  [0:DEPTH-1];   // Base address of reservation
  logic            ent_dword [0:DEPTH-1];   // Size flag (1=8B, 0=4B)
  logic            ent_valid [0:DEPTH-1];   // Entry valid bit
  logic [SEQW-1:0] ent_seq   [0:DEPTH-1];   // Insertion order (age) for LRU eviction
  logic [SEQW-1:0] seq_cnt;                 // Global sequence counter for tracking age

  // Combinational lookup results for address matching and slot management
  logic            match_hit;               // High if input address overlaps with valid entry
  logic [IDXW-1:0] match_idx;               // Index of the matching reservation
  logic            have_free;               // High if an empty slot is available
  logic [IDXW-1:0] free_idx;                // Index of the first available free slot
  logic            any_valid;               // High if at least one entry is valid
  logic [IDXW-1:0] oldest_idx;              // Index of the oldest entry for eviction
  logic [IDXW-1:0] insert_idx;              // Selected index for new reservation

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SC hit is combinational: valid only if SC pulse matches an existing reservation
  assign sc_hit_o   = sc_i && match_hit;
  // Selection logic: use free slot if available, otherwise evict oldest
  assign insert_idx = have_free ? free_idx : oldest_idx;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Compute exclusive end address of a reservation / request
  function automatic logic [AW-1:0] end_addr(
      input logic [AW-1:0] a,
      input logic          dw
  );
    return a + (dw ? AW'(8) : AW'(4));
  endfunction

  // True when two address ranges overlap
  function automatic logic ranges_overlap(
      input logic [AW-1:0] a1, input logic dw1,
      input logic [AW-1:0] a2, input logic dw2
  );
    logic [AW-1:0] e1 = end_addr(a1, dw1);
    logic [AW-1:0] e2 = end_addr(a2, dw2);
    return (a1 < e2) && (a2 < e1);
  endfunction
  ////////////////////////////////////////////////////////////////////////////////////////////////
  // COMBINATIONAL LOOKUPS
  ////////////////////////////////////////////////////////////////////////////////////////////////
  always_comb begin
    // Parallel range-overlap search to identify matching reservations
    match_hit = 1'b0;
    match_idx = '0;
    for (int i = 0; i < DEPTH; i++) begin
      if (ent_valid[i] && ranges_overlap(addr_i, dword_i, ent_addr[i], ent_dword[i])) begin
        match_hit = 1'b1;
        match_idx = i[IDXW-1:0];
      end
    end

    // Find a free slot (prefer higher index)
    have_free = 1'b0;
    free_idx  = '0;
    for (int i = DEPTH-1; i >= 0; i--) begin
      if (!ent_valid[i]) begin
        have_free = 1'b1;
        free_idx  = i[IDXW-1:0];
      end
    end

    // Find oldest valid entry (smallest sequence number) for LRU replacement
    any_valid  = 1'b0;
    oldest_idx = '0;
    for (int i = 0; i < DEPTH; i++) begin
      if (ent_valid[i] && (!any_valid || (ent_seq[i] < ent_seq[oldest_idx]))) begin
        any_valid  = 1'b1;
        oldest_idx = i[IDXW-1:0];
      end
    end
  end

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  ////////////////////////////////////////////////////////////////////////////////////////////////
  // Main state update block for reservation table entries
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      for (int i = 0; i < DEPTH; i++) begin
        ent_valid[i] <= 1'b0;
        ent_addr[i]  <= '0;
        ent_dword[i] <= 1'b0;
        ent_seq[i]   <= '0;
      end
      seq_cnt <= '0;
    end else begin
      // LR : insert (use free slot or evict oldest)
      if (lr_i) begin
        ent_valid[insert_idx] <= 1'b1;
        ent_addr [insert_idx] <= addr_i;
        ent_dword[insert_idx] <= dword_i;
        ent_seq  [insert_idx] <= seq_cnt;
        seq_cnt               <= seq_cnt + 1'b1;
      end
      // SC : on hit remove the matching entry
      else if (sc_i) begin
        if (match_hit) ent_valid[match_idx] <= 1'b0;
      end
      // Store / AMO write : invalidate any overlapping reservation
      else if (store_i) begin
        if (match_hit) ent_valid[match_idx] <= 1'b0;
      end
    end
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // INITIAL CHECKS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  `ifdef SIMULATION
    initial begin
      if (DEPTH < 1)
        $error("%m : DEPTH must be >= 1");
    end
  `endif

endmodule
