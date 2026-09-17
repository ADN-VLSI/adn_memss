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

  generate                                                            // Select logic appropriate for the configured data width.
    if (DW == 64) begin : g_dw64                                      // Implement native 64-bit AMO support.
      logic [31:0] old_word, res_word;                                // Hold the selected old word and its AMO result.
      logic [63:0] res_full;                                          // Hold the full-width AMO result.

      always_comb begin
        old_word = word_hi_i ? mem_data_i[63:32] : mem_data_i[31:0]; // Addressed 32-bit lane.
      end
      always_comb begin
        res_word = alu_w(op_i, old_word, rs2_i[31:0]); // Word AMO result.
      end
      always_comb begin
        res_full = alu_full(op_i, mem_data_i, rs2_i); // Full-width AMO result.
      end

      always_comb begin                                                        // Format outputs for doubleword or word AMOs.
        if (dword_i) begin                                                     // Return a native 64-bit AMO result.
          result_o = res_full;                                                 // Write the computed full-width value to memory.
          rd_old_o = mem_data_i;                                              // Return the original full-width memory value.
        end else begin                                                      // Return a 32-bit AMO result in the required interface format.
          result_o = {res_word, res_word};              // Replicate word result for the write-data interface.
          rd_old_o = {{32{old_word[31]}}, old_word};    // AMO.W returns the old word, sign-extended.
        end // End word-sized AMO handling.
      end // End output formatting logic.
    end else begin : g_dw32 // Implement native 32-bit AMO support.
      logic [31:0] res_word; // Hold the native 32-bit AMO result.
      always_comb begin
        res_word = alu_w(op_i, mem_data_i[31:0], rs2_i[31:0]); // Native 32-bit AMO result.
      end
      always_comb begin
        result_o = res_word; // Value written to memory.
      end
      always_comb begin
        rd_old_o = mem_data_i[31:0]; // Previous memory value returned to rd.
      end
    end // End 32-bit implementation branch.
  endgenerate // End data-width-dependent implementation selection.
endmodule // End atomic memory operation ALU module.
