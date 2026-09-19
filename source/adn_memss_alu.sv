/*

@foez---bhai, write the purpose of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

@foez---bhai, describe the use case of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1      | 2026-09-17 | Shykul Islam Siam | Initial version                                        |
| 1.0      | 2026-09-17 | Shykul Islam Siam | Stable release                                         |

Author : Shykul Islam Siam (shykulislam32@gmail.com)
This file is part of ADN-VLSI/adn_template
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

`include "adn_memss_pkg.sv"

// @foez---bhai, add comments to the parameters, ports
module adn_memss_alu                        // Arithmetic unit for atomic memory operations (AMOs).
  import adn_memss_pkg::*;                 // Import AMO operation encodings and shared types.
#(
    parameter int DW = 64                 // Configurable memory-data width in bits.
) ( // Begin module port list.
    input  amo_op_t       op_i,           // Atomic memory operation to perform.
    input  logic          dword_i,        // Select a full-width operation (64-bit configuration only).
    input  logic          word_hi_i,      // Select the upper 32-bit word for word-sized operations.
    input  logic [DW-1:0] mem_data_i,     // Original value read from memory.
    input  logic [DW-1:0] rs2_i,          //AMO source operand used by the operation.
    output logic [DW-1:0] result_o,       //Value to write back to memory.
    output logic [DW-1:0] rd_old_o        //Pre-operation memory value returned to rd.
); // End module port list.

  function automatic logic [31:0] alu_w(input amo_op_t op,        // Compute a 32-bit AMO result.
                                        input logic [31:0] a,     // Supply the original memory word.
                                        input logic [31:0] b);    // Supply the AMO source word.
    case (op)                                                     // Select the requested word-sized AMO operation.
      AMOSWAP : alu_w = b;                                        // Replace memory data with the source operand.
      AMOADD  : alu_w = a + b;                                    // Add the source operand to memory data.
      AMOXOR  : alu_w = a ^ b;                                    // XOR memory data with the source operand.
      AMOAND  : alu_w = a & b;                                    // AND memory data with the source operand.
      AMOOR   : alu_w = a | b;                                    // OR memory data with the source operand.
      AMOMIN  : alu_w = ($signed(a) < $signed(b)) ? a : b;        // Select the signed minimum.
      AMOMAX  : alu_w = ($signed(a) > $signed(b)) ? a : b;        // Select the signed maximum.
      AMOMINU : alu_w = (a < b) ? a : b;                          // Select the unsigned minimum.
      AMOMAXU : alu_w = (a > b) ? a : b;                          // Select the unsigned maximum.
      default : alu_w = a;                                        // Preserve memory data for an unrecognized operation.
    endcase                                                       // End word AMO operation selection.
  endfunction                                                     // End 32-bit AMO helper function.

  function automatic logic [DW-1:0] alu_full(input amo_op_t op,       // Compute a full-width AMO result.
                                             input logic [DW-1:0] a,  // Supply original full-width memory data.
                                             input logic [DW-1:0] b); // Supply full-width AMO source data.
    case (op)                                                         // Select the requested full-width AMO operation.
      AMOSWAP : alu_full = b;                                         // Replace memory data with the source operand.
      AMOADD  : alu_full = a + b;                                     // Add the source operand to memory data.
      AMOXOR  : alu_full = a ^ b;                                     // XOR memory data with the source operand.
      AMOAND  : alu_full = a & b;                                     // AND memory data with the source operand.
      AMOOR   : alu_full = a | b;                                     // OR memory data with the source operand.
      AMOMIN  : alu_full = ($signed(a) < $signed(b)) ? a : b;         // Select the signed minimum.
      AMOMAX  : alu_full = ($signed(a) > $signed(b)) ? a : b;         // Select the signed maximum.
      AMOMINU : alu_full = (a < b) ? a : b;                           // Select the unsigned minimum.
      AMOMAXU : alu_full = (a > b) ? a : b;                           // Select the unsigned maximum.
      default : alu_full = a;                                         // Preserve memory data for an unrecognized operation.
    endcase                                                           // End full-width AMO operation selection.
  endfunction                                                         // End full-width AMO helper function.

  generate
    if (DW == 64) begin : g_dw64
      logic [31:0] old_word, rs2_word, res_word;
      logic [63:0] res_full;

      always_comb old_word = word_hi_i ? mem_data_i[63:32] : mem_data_i[31:0];
      // LSU shifts rs2 into upper half when addr[2]==1
      always_comb rs2_word = word_hi_i ? rs2_i[63:32] : rs2_i[31:0];
      always_comb res_word = alu_w(op_i, old_word, rs2_word);
      always_comb res_full = alu_full(op_i, mem_data_i, rs2_i);

      always_comb begin
        if (dword_i) begin
          result_o = res_full;
          rd_old_o = mem_data_i;
        end else begin
          result_o = {res_word, res_word};
          rd_old_o = {{32{old_word[31]}}, old_word};
        end
      end
    end else begin : g_dw32
      logic [31:0] res_word;
      always_comb res_word = alu_w(op_i, mem_data_i[31:0], rs2_i[31:0]);
      always_comb result_o = res_word;
      always_comb rd_old_o = mem_data_i[31:0];
    end
  endgenerate
endmodule
