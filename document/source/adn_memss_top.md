# adn_memss_top (module)

### Author: Adnan Sami Anirban (adnananirban259@gmail.com)

### Source: adn_memss_top.sv

## Top IO

<img src="./adn_memss_top_top.svg">

## Parameters

|Name|Type|Dimension|Default|Description|
|-|-|-|-|-|
|pmi_req_t|type||logic||
|pmi_rsp_t|type||logic||
|RSV_DEPTH|int||4||


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


## Description

@foez---bhai, write the purpose of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

@foez---bhai, describe the use case of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1      | 2026-09-17 | Adnan Sami Anirban | Initial version                                        |
| 1.0      | 2026-09-17 | Adnan Sami Anirban | Stable release                                         |

Author : Adnan Sami Anirban (adnananirban259@gmail.com)
