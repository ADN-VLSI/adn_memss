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
  `include "vip/adn_common_tb_headers.sv"
  `include "pmi/typedef.svh"

//////////////////////////////////////////////////////////////////////////////////////////////////
// LOCALPARAMS
//////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int DW = 64;
  localparam int AW = 64;
  localparam int SW = DW / 8;

//////////////////////////////////////////////////////////////////////////////////////////////////
// TYPEDEFS
//////////////////////////////////////////////////////////////////////////////////////////////////

  `PMI_T(pmi, AW, DW)

//////////////////////////////////////////////////////////////////////////////////////////////////
// SIGNALS
//////////////////////////////////////////////////////////////////////////////////////////////////

  logic      clk;
  logic      arst_n;
  sideband_t cpu_sb;
  pmi_req_t  cpu_req;
  pmi_req_t  mem_req;
  pmi_rsp_t  cpu_rsp;
  pmi_rsp_t  mem_rsp;

  logic [DW-1:0] rd;
  logic          rsp;
  logic [31:0]   w;

  logic [DW-1:0] mem [0:1023];
  logic [DW-1:0] rdata_q;
  logic          ack_q;

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
// ASSIGNMENTS
//////////////////////////////////////////////////////////////////////////////////////////////////

  assign mem_rsp.mgnt   = mem_req.mreq;
  assign mem_rsp.mack   = ack_q;
  assign mem_rsp.mrdata = rdata_q;
  assign mem_rsp.mresp  = 1'b0;

//////////////////////////////////////////////////////////////////////////////////////////////////
// SEQUENTIALS
//////////////////////////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk or negedge arst_n) begin
    if (!arst_n) begin
      ack_q   <= 1'b0;
      rdata_q <= '0;
    end else begin
      ack_q <= 1'b0;
      if (mem_req.mreq) begin
        rdata_q <= mem[mem_req.maddr[11:3]];
        if (mem_req.mwe) begin
          for (int b = 0; b < SW; b++) begin
            if (mem_req.mstrb[b]) begin
              mem[mem_req.maddr[11:3]][b*8 +: 8] <= mem_req.mwdata[b*8 +: 8];
            end
          end
        end
        ack_q <= 1'b1;
      end
    end
  end

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

    while (!cpu_rsp.mgnt) begin
      @(posedge clk);
    end
    @(posedge clk);
    cpu_req.mreq <= 1'b0;

    while (!cpu_rsp.mack) begin
      @(posedge clk);
    end
    rdata = cpu_rsp.mrdata;
    resp  = cpu_rsp.mresp;
    @(posedge clk);
  endtask

  task automatic store_w(input logic [AW-1:0] addr, input logic [31:0] data);
    logic [DW-1:0] wdata;
    logic [SW-1:0] strb;
    if (addr[2]) begin
      wdata = {data, 32'b0};
      strb  = 8'hF0;
    end else begin
      wdata = {32'b0, data};
      strb  = 8'h0F;
    end
    do_req(NONE, 1'b0, addr, wdata, 1'b1, strb, rd, rsp);
  endtask

  task automatic load_w(input logic [AW-1:0] addr, output logic [31:0] data);
    do_req(NONE, 1'b0, addr, '0, 1'b0, 8'h00, rd, rsp);
    data = addr[2] ? rd[63:32] : rd[31:0];
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

  task automatic apply_reset();
    clk     <= 1'b0;
    arst_n  <= 1'b0;
    cpu_req <= '0;
    cpu_sb  <= '0;
    rd      <= '0;
    rsp     <= 1'b0;
    for (int i = 0; i < 1024; i++) begin
      mem[i] = '0;
    end
    repeat (4) @(posedge clk);
    arst_n <= 1'b1;
    @(posedge clk);
  endtask

  task automatic tc_001_sw_lw();
    $display("--- TC_001 SW/LW ---");
    store_w(64'h1000, 32'hDEAD_BEEF);
    load_w(64'h1000, w);
    check("TC_001 SW/LW", w, 32'hDEAD_BEEF);
  endtask

  task automatic tc_002_amoadd_w();
    $display("--- TC_002 AMOADD.W ---");
    store_w(64'h1000, 32'd10);
    do_req(AMOADD, 1'b0, 64'h1000, {32'b0, 32'd5}, 1'b0, 8'h00, rd, rsp);
    check("TC_002 AMOADD.W old", rd[31:0], 32'd10);
    load_w(64'h1000, w);
    check("TC_002 AMOADD.W mem", w, 32'd15);
  endtask

  task automatic tc_003_lr_sc_success();
    $display("--- TC_003 LR/SC success ---");
    store_w(64'h1000, 32'h0);
    do_req(LR, 1'b0, 64'h1000, '0, 1'b0, 8'h00, rd, rsp);
    do_req(SC, 1'b0, 64'h1000, {32'b0, 32'hCAFE_BABE}, 1'b0, 8'h00, rd, rsp);
    check("TC_003 SC success rd", rd, 64'd0);
    check("TC_003 SC success mresp", {63'b0, rsp}, 64'd0);
    load_w(64'h1000, w);
    check("TC_003 SC mem", w, 32'hCAFE_BABE);
  endtask

  task automatic tc_004_sc_fail_no_lr();
    $display("--- TC_004 SC without LR ---");
    do_req(SC, 1'b0, 64'h1000, {32'b0, 32'h1111}, 1'b0, 8'h00, rd, rsp);
    check("TC_004 SC fail rd", rd, 64'd1);
    check("TC_004 SC fail mresp", {63'b0, rsp}, 64'd1);
  endtask

  task automatic tc_005_lr_d_misalign();
    $display("--- TC_005 LR.D misalign ---");
    do_req(LR, 1'b1, 64'h1004, '0, 1'b0, 8'h00, rd, rsp);
    check("TC_005 LR.D misalign mresp", {63'b0, rsp}, 64'd1);
  endtask

//////////////////////////////////////////////////////////////////////////////////////////////////
// PROCEDURALS
//////////////////////////////////////////////////////////////////////////////////////////////////

  always #5 clk = ~clk;

  initial begin
    apply_reset();

    $display("==== adn_memss_top_tb start ====");

    tc_001_sw_lw();
    tc_002_amoadd_w();
    tc_003_lr_sc_success();
    tc_004_sc_fail_no_lr();
    tc_005_lr_d_misalign();

    $display("==== adn_memss_top_tb done ====");
    $finish;
  end

  initial begin
    #50_000;
    $display("TIMEOUT");
    $finish;
  end

endmodule
