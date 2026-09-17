/*

@foez---bhai, write the purpose of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

@foez---bhai, describe the use case of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1      | 2026-09-17 | Adnan Sami Anirban | Initial version                                        |
| 1.0      | 2026-09-17 | Adnan Sami Anirban | Stable release                                         |

Author : Adnan Sami Anirban (adnananirban259@gmail.com)
This file is part of ADN-VLSI/adn_memss
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

// @foez---bhai, add comments to the parameters, ports
module adn_memss_top
  import adn_memss_pkg::*;
#(
    parameter type pmi_req_t = logic,
    parameter type pmi_rsp_t = logic,
    parameter int  RSV_DEPTH = 4
) (
    input  logic       clk_i,
    input  logic       arst_ni,

    input  sideband_t  cpu_sideband_t_i,
    input  pmi_req_t   cpu_pmi_req_t_i,
    output pmi_rsp_t   cpu_pmi_rsp_t_o,

    output pmi_req_t   mem_pmi_req_t_o,
    input  pmi_rsp_t   mem_pmi_rsp_t_i
);

  // @foez---bhai, add comments to the functional blocks, signals, and submodules

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS GENERATED
  //////////////////////////////////////////////////////////////////////////////////////////////////
  localparam int AW = $bits(cpu_pmi_req_t_i.maddr);
  localparam int DW = $bits(cpu_pmi_req_t_i.mwdata);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  amo_op_t        alu_op;
  logic           alu_dword, alu_word_hi;
  logic [DW-1:0]  alu_mem_data, alu_rs2, alu_result, alu_rd_old;

  logic [AW-1:0]  rsv_req_addr, rsv_wr_addr;
  logic           rsv_req_dword, rsv_wr_dword;
  logic           rsv_set, rsv_sc_eval, rsv_wr_commit;
  logic           rsv_sc_hit;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SUBMODULES
  //////////////////////////////////////////////////////////////////////////////////////////////////
adn_memss_fsm #(
      .DW        (DW),
      .AW        (AW),
      .pmi_req_t (pmi_req_t),
      .pmi_rsp_t (pmi_rsp_t)
  ) u_fsm (
      .clk_i              (clk_i),
      .arst_ni            (arst_ni),
      .cpu_sideband_t_i   (cpu_sideband_t_i),
      .cpu_pmi_req_t_i    (cpu_pmi_req_t_i),
      .cpu_pmi_rsp_t_o    (cpu_pmi_rsp_t_o),
      .mem_pmi_req_t_o    (mem_pmi_req_t_o),
      .mem_pmi_rsp_t_i    (mem_pmi_rsp_t_i),
      .alu_op_o           (alu_op),
      .alu_dword_o        (alu_dword),
      .alu_word_hi_o      (alu_word_hi),
      .alu_mem_data_o     (alu_mem_data),
      .alu_rs2_o          (alu_rs2),
      .alu_result_i       (alu_result),
      .alu_rd_old_i       (alu_rd_old),
      .rsv_req_addr_o     (rsv_req_addr),
      .rsv_req_dword_o    (rsv_req_dword),
      .rsv_set_o          (rsv_set),
      .rsv_sc_eval_o      (rsv_sc_eval),
      .rsv_wr_commit_o    (rsv_wr_commit),
      .rsv_wr_addr_o      (rsv_wr_addr),
      .rsv_wr_dword_o     (rsv_wr_dword),
      .rsv_sc_hit_i       (rsv_sc_hit)
  );

  adn_memss_alu #(
      .DW (DW)
  ) u_alu (
      .op_i       (alu_op),
      .dword_i    (alu_dword),
      .word_hi_i  (alu_word_hi),
      .mem_data_i (alu_mem_data),
      .rs2_i      (alu_rs2),
      .result_o   (alu_result),
      .rd_old_o   (alu_rd_old)
  );

  adn_memss_address_reservation_unit #(
      .AW    (AW),
      .DEPTH (RSV_DEPTH)
  ) u_rsv (
      .clk_i       (clk_i),
      .arst_ni     (arst_ni),
      .req_addr_i  (rsv_req_addr),
      .req_dword_i (rsv_req_dword),
      .set_i       (rsv_set),
      .sc_eval_i   (rsv_sc_eval),
      .wr_commit_i (rsv_wr_commit),
      .wr_addr_i   (rsv_wr_addr),
      .wr_dword_i  (rsv_wr_dword),
      .sc_hit_o    (rsv_sc_hit)
  );
endmodule
