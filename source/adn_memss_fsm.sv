/*

@foez---bhai, write the purpose of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

@foez---bhai, describe the use case of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

| REVISION | DATE       | AUTHOR              | DESCRIPTION                                            |
|----------|------------|---------------------|--------------------------------------------------------|
| 0.1      | 2026-09-16 | Adnan Sami Anirban  | Initial version                                        |
| 1.0      | 2026-09-16 | Motasim Faiyaz      | Stable release                                         |

Author : Motasim Faiyaz (motasimfaiyaz@gmail.com)
Co-Author : Adnan Sami Anirban (adnananirban259@gmail.com)
This file is part of ADN-VLSI/adn_template
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

// @foez---bhai, add comments to the parameters, ports
`include "adn_memss_pkg.sv"
module adn_memss_fsm
  import adn_memss_pkg::*;
#(
    parameter int  DW        = 64,
    parameter int  AW        = 32,
    parameter type pmi_req_t = logic,
    parameter type pmi_rsp_t = logic
) (
    input  logic       clk_i,
    input  logic       arst_ni,

    input  sideband_t  cpu_sideband_t_i,
    input  pmi_req_t   cpu_pmi_req_t_i,
    output pmi_rsp_t   cpu_pmi_rsp_t_o,

    output pmi_req_t   mem_pmi_req_t_o,
    input  pmi_rsp_t   mem_pmi_rsp_t_i,

    output amo_op_t       alu_op_o,
    output logic          alu_dword_o,
    output logic          alu_word_hi_o,
    output logic [DW-1:0] alu_mem_data_o,
    output logic [DW-1:0] alu_rs2_o,
    input  logic [DW-1:0] alu_result_i,
    input  logic [DW-1:0] alu_rd_old_i,

    output logic [AW-1:0] rsv_req_addr_o,
    output logic          rsv_req_dword_o,
    output logic          rsv_set_o,
    output logic          rsv_sc_eval_o,
    output logic          rsv_wr_commit_o,
    output logic [AW-1:0] rsv_wr_addr_o,
    output logic          rsv_wr_dword_o,
    input  logic          rsv_sc_hit_i
);

//////////////////////////////////////////////////////////////////////////////////////////////////
// LOCALPARAMS GENERATED
//////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int SW = DW / 8;

//////////////////////////////////////////////////////////////////////////////////////////////////
// TYPEDEFS
//////////////////////////////////////////////////////////////////////////////////////////////////

  typedef enum logic [2:0] {
    S_IDLE,
    S_SC_CHK,
    S_RD,
    S_WR,
    S_ACK
  } state_t;

//////////////////////////////////////////////////////////////////////////////////////////////////
// SIGNALS
//////////////////////////////////////////////////////////////////////////////////////////////////

  state_t state_q, state_n;
  logic   req_sent_q, req_sent_n;

  logic [AW-1:0]  addr_q;
  logic [DW-1:0]  wdata_q;
  logic [SW-1:0]  strb_q;
  logic           we_q;
  sideband_t      sb_q;
  logic [DW-1:0]  old_q;
  logic           err_q;
  logic           sc_fail_q;

  logic           word_hi;
  logic [DW-1:0]  atomic_wr_data;
  logic [SW-1:0]  atomic_wr_strb;
  logic [DW-1:0]  resp_data;

  logic accept;
  logic misalign_acc;
  logic rd_done;
  logic wr_done;
  logic gnt_rd;
  logic gnt_wr;

//////////////////////////////////////////////////////////////////////////////////////////////////
// ASSIGNMENTS
//////////////////////////////////////////////////////////////////////////////////////////////////

  assign word_hi = (DW == 64) ? addr_q[2] : 1'b0;

  assign accept = (state_q == S_IDLE) && cpu_pmi_req_t_i.mreq;
  assign misalign_acc = accept && is_misaligned(
      cpu_pmi_req_t_i.maddr,
      cpu_sideband_t_i.op,
      cpu_sideband_t_i.doubleword
  );
  assign rd_done = (state_q == S_RD) && mem_pmi_rsp_t_i.mack;
  assign wr_done = (state_q == S_WR) && mem_pmi_rsp_t_i.mack;
  assign gnt_rd  = (state_q == S_RD) && mem_pmi_req_t_o.mreq && mem_pmi_rsp_t_i.mgnt;
  assign gnt_wr  = (state_q == S_WR) && mem_pmi_req_t_o.mreq && mem_pmi_rsp_t_i.mgnt;

  assign alu_op_o       = sb_q.op;
  assign alu_dword_o    = sb_q.doubleword;
  assign alu_word_hi_o  = word_hi;
  assign alu_mem_data_o = old_q;
  assign alu_rs2_o      = wdata_q;

  assign rsv_req_addr_o  = addr_q;
  assign rsv_req_dword_o = sb_q.doubleword;
  assign rsv_wr_addr_o   = addr_q;
  assign rsv_wr_dword_o  = sb_q.doubleword;

//////////////////////////////////////////////////////////////////////////////////////////////////
// SEQUENTIALS
//////////////////////////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      state_q    <= S_IDLE;
      req_sent_q <= 1'b0;
    end else begin
      state_q    <= state_n;
      req_sent_q <= req_sent_n;
    end
  end

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      err_q     <= 1'b0;
      sc_fail_q <= 1'b0;
    end else begin
      if (accept) begin
        addr_q    <= cpu_pmi_req_t_i.maddr;
        wdata_q   <= cpu_pmi_req_t_i.mwdata;
        strb_q    <= cpu_pmi_req_t_i.mstrb;
        we_q      <= cpu_pmi_req_t_i.mwe;
        sb_q      <= cpu_sideband_t_i;
        err_q     <= misalign_acc;
        sc_fail_q <= 1'b0;
      end
      if (rd_done) begin
        old_q <= mem_pmi_rsp_t_i.mrdata;
        err_q <= mem_pmi_rsp_t_i.mresp;
      end
      if (wr_done) begin
        err_q <= mem_pmi_rsp_t_i.mresp;
      end
      if (state_q == S_SC_CHK) begin
        sc_fail_q <= ~rsv_sc_hit_i;
        if (!rsv_sc_hit_i) begin
          err_q <= 1'b1;
        end
      end
    end
  end

//////////////////////////////////////////////////////////////////////////////////////////////////
// METHODS
//////////////////////////////////////////////////////////////////////////////////////////////////

  function automatic logic is_misaligned(
      input logic [AW-1:0] a,
      input amo_op_t       op,
      input logic          dw
  );
    if (op == NONE) begin
      return 1'b0;
    end
    if (DW == 32) begin
      return (a[1:0] != 2'b00);
    end
    return dw ? (a[2:0] != 3'b000) : (a[1:0] != 2'b00);
  endfunction

  always_comb begin
    state_n    = state_q;
    req_sent_n = req_sent_q;

    unique case (state_q)
      S_IDLE: begin
        req_sent_n = 1'b0;
        if (cpu_pmi_req_t_i.mreq) begin
          if (misalign_acc) begin
            state_n = S_ACK;
          end else begin
            unique case (cpu_sideband_t_i.op)
              NONE:    state_n = cpu_pmi_req_t_i.mwe ? S_WR : S_RD;
              LR:      state_n = S_RD;
              SC:      state_n = S_SC_CHK;
              default: state_n = S_RD;
            endcase
          end
        end
      end

      S_SC_CHK: begin
        state_n = rsv_sc_hit_i ? S_WR : S_ACK;
      end

      S_RD: begin
        if (mem_pmi_rsp_t_i.mack) begin
          req_sent_n = 1'b0;
          if (mem_pmi_rsp_t_i.mresp) begin
            state_n = S_ACK;
          end else if (sb_q.op == NONE || sb_q.op == LR) begin
            state_n = S_ACK;
          end else begin
            state_n = S_WR;
          end
        end else if (gnt_rd) begin
          req_sent_n = 1'b1;
        end
      end

      S_WR: begin
        if (mem_pmi_rsp_t_i.mack) begin
          req_sent_n = 1'b0;
          state_n    = S_ACK;
        end else if (gnt_wr) begin
          req_sent_n = 1'b1;
        end
      end

      S_ACK: begin
        state_n = S_IDLE;
      end

      default: begin
        state_n = S_IDLE;
      end
    endcase
  end

  generate
    if (DW == 64) begin : g_wr64
      always_comb begin
        if (sb_q.doubleword) begin
          atomic_wr_strb = '1;
          atomic_wr_data = (sb_q.op == SC) ? wdata_q : alu_result_i;
        end else begin
          atomic_wr_strb = word_hi ? 8'hF0 : 8'h0F;
          atomic_wr_data = (sb_q.op == SC) ? {wdata_q[31:0], wdata_q[31:0]}
                                           : alu_result_i;
        end
      end
    end else begin : g_wr32
      always_comb begin
        atomic_wr_strb = '1;
        atomic_wr_data = (sb_q.op == SC) ? wdata_q : alu_result_i;
      end
    end
  endgenerate

  always_comb begin
    mem_pmi_req_t_o = '0;
    unique case (state_q)
      S_RD: begin
        mem_pmi_req_t_o.maddr = addr_q;
        mem_pmi_req_t_o.mwe   = 1'b0;
        mem_pmi_req_t_o.mreq  = ~req_sent_q;
      end
      S_WR: begin
        mem_pmi_req_t_o.maddr  = addr_q;
        mem_pmi_req_t_o.mwe    = 1'b1;
        mem_pmi_req_t_o.mreq   = ~req_sent_q;
        mem_pmi_req_t_o.mwdata = (sb_q.op == NONE) ? wdata_q : atomic_wr_data;
        mem_pmi_req_t_o.mstrb  = (sb_q.op == NONE) ? strb_q  : atomic_wr_strb;
      end
      default: ;
    endcase
  end

  always_comb begin
    unique case (sb_q.op)
      NONE:    resp_data = old_q;
      SC:      resp_data = sc_fail_q ? {{(DW - 1){1'b0}}, 1'b1} : '0;
      LR:      resp_data = alu_rd_old_i;
      default: resp_data = alu_rd_old_i;
    endcase
  end

  always_comb begin
    cpu_pmi_rsp_t_o      = '0;
    cpu_pmi_rsp_t_o.mgnt = (state_q == S_IDLE);
    if (state_q == S_ACK) begin
      cpu_pmi_rsp_t_o.mack   = 1'b1;
      cpu_pmi_rsp_t_o.mrdata = resp_data;
      cpu_pmi_rsp_t_o.mresp  = err_q;
    end
  end

  always_comb begin
    rsv_set_o = (state_q == S_RD) && (sb_q.op == LR) &&
                mem_pmi_rsp_t_i.mack && !mem_pmi_rsp_t_i.mresp;
    rsv_sc_eval_o   = (state_q == S_SC_CHK);
    rsv_wr_commit_o = (state_q == S_WR) && (sb_q.op != SC) && mem_pmi_rsp_t_i.mack;
  end
endmodule
