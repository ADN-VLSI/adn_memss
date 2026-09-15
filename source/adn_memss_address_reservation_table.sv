/*

@foez-bhai, write the purpose of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

@foez-bhai, describe the use case of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

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

// @foez-bhai, add comments to the parameters, ports
module adn_memss_address_reservation_table #(
    // PARAMETERS
    parameter int AW    = 32,   // Address width
    parameter int DEPTH = 4     // Number of concurrent reservation entries
) (
    // PORTS
    input  logic          clk_i,        // Clock
    input  logic          arst_ni,      // Asynchronous reset, active low

    input  logic [AW-1:0] addr_i,       // Address of current LR / SC / store
    input  logic          dword_i,      // 1 = 8-byte reservation, 0 = 4-byte

    input  logic          lr_i,         // LR pulse – insert new reservation
    input  logic          sc_i,         // SC pulse – evaluate and clear on hit
    input  logic          store_i,      // Store/AMO write pulse – invalidate on overlap

    output logic          sc_hit_o      // Combinational: SC found an overlapping reservation
);

  // @foez-bhai, add comments to the functional blocks, signals, and submodules

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS GENERATED
  //////////////////////////////////////////////////////////////////////////////////////////////////
  localparam int IDXW = (DEPTH > 1) ? $clog2(DEPTH) : 1;
  localparam int SEQW = IDXW + 1;   // Sequence counter width for age tracking
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Reservation entry storage
  logic [AW-1:0]   ent_addr  [0:DEPTH-1];   // Base address of reservation
  logic            ent_dword [0:DEPTH-1];   // Size flag (1=8B, 0=4B)
  logic            ent_valid [0:DEPTH-1];   // Entry valid
  logic [SEQW-1:0] ent_seq   [0:DEPTH-1];   // Insertion order (age)
  logic [SEQW-1:0] seq_cnt;                 // Global sequence counter

  // Combinational lookup results
  logic            match_hit;
  logic [IDXW-1:0] match_idx;
  logic            have_free;
  logic [IDXW-1:0] free_idx;
  logic            any_valid;
  logic [IDXW-1:0] oldest_idx;
  logic [IDXW-1:0] insert_idx;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SC hit is combinational
  assign sc_hit_o   = sc_i && match_hit;
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
    // Parallel range-overlap search
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

    // Find oldest valid entry (smallest sequence number)
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
