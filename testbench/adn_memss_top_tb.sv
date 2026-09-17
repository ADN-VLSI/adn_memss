/*

| TEST CASE | DATE       | AUTHOR          | DESCRIPTION                                           |
|-----------|------------|-----------------|-------------------------------------------------------|  
| TC_001    | 2026-09-17 | Adnan Sami Anirban | Test case description goes here                       |
| TC_002    | 2026-09-17 | Adnan Sami Anirban | Test case description goes here                       |

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

module adn_memss_top_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  import adn_memss_pkg::*;
  // bring in the testbench essentials functions and macros
  `include "vip/adn_common_tb_headers.sv"
  `include "pmi/typedef.svh"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  localparam int DW = 64;
  localparam int AW = 32;
  localparam int SW = DW / 8;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  `PMI_T(pmi,AW,DW)

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  logic clk, arst_n;
  sideband_t cpu_sb;
  pmi_req_t  cpu_req, mem_req;
  pmi_rsp_t  cpu_rsp, mem_rsp;

  int pass, fail;
  logic [DW-1:0] rd;
  logic          rsp;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  adn_memss_top #(
      .pmi_req_t (pmi_req_t),
      .pmi_rsp_t (pmi_rsp_t),
      .RSV_DEPTH (4)
  ) dut (
      .clk_i            (clk),
      .arst_ni          (arst_n),
      .cpu_sideband_t_i (cpu_sb),
      .cpu_pmi_req_t_i  (cpu_req),
      .cpu_pmi_rsp_t_o  (cpu_rsp),
      .mem_pmi_req_t_o  (mem_req),
      .mem_pmi_rsp_t_i  (mem_rsp)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  task automatic do_req(
      input  amo_op_t       op,
      input  logic          dword,
      input  logic [AW-1:0] addr,
      input  logic [DW-1:0] wdata,
      input  logic          mwe,
      input  logic [SW-1:0] strb,
      output logic [DW-1:0] rdata,
      output logic          resp
  );
    @(posedge clk);
    cpu_req.mreq      <= 1'b1;
    cpu_req.maddr     <= addr;
    cpu_req.mwdata    <= wdata;
    cpu_req.mwe       <= mwe;
    cpu_req.mstrb     <= strb;
    cpu_sb.op         <= op;
    cpu_sb.doubleword <= dword;
    cpu_sb.aq         <= 1'b0;
    cpu_sb.rl         <= 1'b0;

    while (!cpu_rsp.mgnt) @(posedge clk);
    @(posedge clk);
    cpu_req.mreq <= 1'b0;

    while (!cpu_rsp.mack) @(posedge clk);
    rdata = cpu_rsp.mrdata;
    resp  = cpu_rsp.mresp;
    @(posedge clk);
  endtask

  task automatic check(string name, logic [DW-1:0] got, logic [DW-1:0] exp);
    if (got === exp) begin
      note_case(1);
      $display("PASS  %s  got=%h", name, got);
    end else begin
      note_case(0);
      $display("FAIL  %s  got=%h exp=%h", name, got, exp);
    end
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  logic [DW-1:0] mem [0:1023];
  logic [DW-1:0] rdata_q;
  logic          ack_q;

  assign mem_rsp.mgnt   = mem_req.mreq;
  assign mem_rsp.mack   = ack_q;
  assign mem_rsp.mrdata = rdata_q;
  assign mem_rsp.mresp  = 1'b0;

  always_ff @(posedge clk or negedge arst_n) begin
    if (!arst_n) begin
      ack_q   <= 1'b0;
      rdata_q <= '0;
    end else begin
      ack_q <= 1'b0;
      if (mem_req.mreq) begin
        rdata_q <= mem[mem_req.maddr[11:3]];
        if (mem_req.mwe) begin
          for (int b = 0; b < SW; b++)
            if (mem_req.mstrb[b])
              mem[mem_req.maddr[11:3]][b*8 +: 8] <= mem_req.mwdata[b*8 +: 8];
        end
        ack_q <= 1'b1;
      end
    end
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  always #5 clk = ~clk;

  initial begin
    clk     = 0;
    arst_n  = 0;
    cpu_req = '0;
    cpu_sb  = '0;
    pass    = 0;
    fail    = 0;

    for (int i = 0; i < 1024; i++) mem[i] = '0;

    repeat (4) @(posedge clk);
    arst_n = 1;
    @(posedge clk);

    $display("==== adn_memss basic smoke ====");

    // 1) Store word + load word
    do_req(NONE, 0, 32'h1000, {32'b0, 32'hDEAD_BEEF}, 1, 8'h0F, rd, rsp);
    do_req(NONE, 0, 32'h1000, '0, 0, 8'h00, rd, rsp);
    check("1 SW/LW", rd[31:0], 32'hDEAD_BEEF);

    // 2) AMOADD.W
    do_req(NONE, 0, 32'h1000, {32'b0, 32'd10}, 1, 8'h0F, rd, rsp);
    do_req(AMOADD, 0, 32'h1000, {32'b0, 32'd5}, 0, 8'h00, rd, rsp);
    check("2 AMOADD.W old", rd[31:0], 32'd10);
    do_req(NONE, 0, 32'h1000, '0, 0, 8'h00, rd, rsp);
    check("2 AMOADD.W mem", rd[31:0], 32'd15);

    // 3) LR.W + SC.W success
    do_req(LR, 0, 32'h1000, '0, 0, 8'h00, rd, rsp);
    do_req(SC, 0, 32'h1000, {32'b0, 32'hCAFE_BABE}, 0, 8'h00, rd, rsp);
    check("3 SC success rd", rd, 64'd0);
    check("3 SC success mresp", {63'b0, rsp}, 64'd0);
    do_req(NONE, 0, 32'h1000, '0, 0, 8'h00, rd, rsp);
    check("3 SC mem", rd[31:0], 32'hCAFE_BABE);

    // 4) SC without LR → fail (project: mrdata=1, mresp=1)
    do_req(SC, 0, 32'h1000, {32'b0, 32'h1111}, 0, 8'h00, rd, rsp);
    check("4 SC fail rd", rd, 64'd1);
    check("4 SC fail mresp", {63'b0, rsp}, 64'd1);

    // 5) Misaligned LR.D → mresp=1
    do_req(LR, 1, 32'h1004, '0, 0, 8'h00, rd, rsp);
    check("5 LR.D misalign mresp", {63'b0, rsp}, 64'd1);
  end
  initial begin
    #50_000;
    $display("TIMEOUT");
    $finish;
  end
endmodule
