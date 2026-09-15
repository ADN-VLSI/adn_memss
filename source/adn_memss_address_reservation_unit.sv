/*

@foez---bhai, write the purpose of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

@foez---bhai, describe the use case of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

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

// @foez---bhai, add comments to the parameters, ports
module adn_memss_address_reservation_unit #(
    // PARAMETERS
    parameter int AW    = 32,   // Address width
    parameter int DEPTH = 4     // Number of concurrent reservation entries
) (
    // PORTS
    input  logic          clk_i,         // Clock
    input  logic          arst_ni,       // Asynchronous reset, active low

    input  logic [AW-1:0] req_addr_i,    // Address from LR / SC request
    input  logic          req_dword_i,   // Size flag from LR / SC request

    input  logic          set_i,         // LR pulse – create reservation
    input  logic          sc_eval_i,     // SC pulse – evaluate reservation
    input  logic          wr_commit_i,   // Store/AMO write commit pulse

    input  logic [AW-1:0] wr_addr_i,     // Address of the committed write
    input  logic          wr_dword_i,    // Size flag of the committed write

    output logic          sc_hit_o       // Combinational SC hit result
);
  ////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  ////////////////////////////////////////////////////////////////////////////////////////////////
  logic [AW-1:0] tbl_addr;
  logic          tbl_dword;

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  ////////////////////////////////////////////////////////////////////////////////////////////////
  // Select address/size source:
  //   - write-commit path uses the write address
  //   - LR / SC path uses the request address
  always_comb begin
    if (wr_commit_i) begin
      tbl_addr  = wr_addr_i;
      tbl_dword = wr_dword_i;
    end else begin
      tbl_addr  = req_addr_i;
      tbl_dword = req_dword_i;
    end
  end

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // SUBMODULES
  ////////////////////////////////////////////////////////////////////////////////////////////////
  adn_memss_address_reservation_table #(
      .AW    (AW),
      .DEPTH (DEPTH)
  ) u_tbl (
      .clk_i    (clk_i),
      .arst_ni  (arst_ni),
      .addr_i   (tbl_addr),
      .dword_i  (tbl_dword),
      .lr_i     (set_i),
      .sc_i     (sc_eval_i),
      .store_i  (wr_commit_i),
      .sc_hit_o (sc_hit_o)
  );

  ////////////////////////////////////////////////////////////////////////////////////////////////
  // INITIAL CHECKS
  ////////////////////////////////////////////////////////////////////////////////////////////////
`ifdef SIMULATION
  initial begin
    if (DEPTH < 1)
      $error("%m : DEPTH must be >= 1");
  end
`endif
endmodule
