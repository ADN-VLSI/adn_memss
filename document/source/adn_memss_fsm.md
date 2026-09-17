# adn_memss_fsm (module)

### Author: Adnan Sami Anirban (adnananirban259@gmail.com)

### Source: adn_memss_fsm.sv

## Top IO

<img src="./adn_memss_fsm_top.svg">

## Parameters

|Name|Type|Dimension|Default|Description|
|-|-|-|-|-|
|DW|int||64||
|AW|int||32||
|pmi_req_t|type||logic||
|pmi_rsp_t|type||logic||


## Ports

|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|clk_i|input|logic|||
|arst_ni|input|logic|||
|cpu_sideband_t_i|input|sideband_t|||
|cpu_pmi_req_t_i|input|pmi_req_t|||
|cpu_pmi_rsp_t_o|output|pmi_rsp_t|||
|mem_pmi_req_t_o|output|pmi_req_t|||
|mem_pmi_rsp_t_i|input|pmi_rsp_t|||
|alu_op_o|output|amo_op_t|||
|alu_dword_o|output|logic|||
|alu_word_hi_o|output|logic|||
|alu_mem_data_o|output|logic [DW-1:0]|||
|alu_rs2_o|output|logic [DW-1:0]|||
|alu_result_i|input|logic [DW-1:0]|||
|alu_rd_old_i|input|logic [DW-1:0]|||
|rsv_req_addr_o|output|logic [AW-1:0]|||
|rsv_req_dword_o|output|logic|||
|rsv_set_o|output|logic|||
|rsv_sc_eval_o|output|logic|||
|rsv_wr_commit_o|output|logic|||
|rsv_wr_addr_o|output|logic [AW-1:0]|||
|rsv_wr_dword_o|output|logic|||
|rsv_sc_hit_i|input|logic|||


## Description

@foez---bhai, write the purpose of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

@foez---bhai, describe the use case of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1      | 2026-09-16 | Adnan Sami Anirban | Initial version                                        |
| 1.0      | 2026-09-16 | Adnan Sami Anirban | Stable release                                         |

Author : Adnan Sami Anirban (adnananirban259@gmail.com)
