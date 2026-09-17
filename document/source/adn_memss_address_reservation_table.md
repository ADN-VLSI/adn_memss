# adn_memss_address_reservation_table (module)

### Author: Adnan Sami Anirban (adnananirban259@gmail.com)

### Source: adn_memss_address_reservation_table.sv

## Top IO

<img src="./adn_memss_address_reservation_table_top.svg">

## Parameters

|Name|Type|Dimension|Default|Description|
|-|-|-|-|-|
|AW|int||32|Address width in bits|
|DEPTH|int||4|Number of concurrent reservation entries supported|


## Ports

|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|clk_i|input|logic||System clock|
|arst_ni|input|logic||Asynchronous reset, active low|
|addr_i|input|logic [AW-1:0]||Target address for LR/SC/Store operations|
|dword_i|input|logic||Data size: 1 = 8-byte reservation, 0 = 4-byte|
|lr_i|input|logic||Load-Reserved pulse: triggers new reservation insertion|
|sc_i|input|logic||Store-Conditional pulse: evaluates reservation and clears on hit|
|store_i|input|logic||Store/AMO write pulse: invalidates reservation on address overlap|
|sc_hit_o|output|logic||Combinational output: high if SC matches an active reservation|


## Description

This module implements a hardware reservation table designed to track memory address reservations for atomic operations (like LR/SC). It maintains a set of active reservations and provides logic to validate, invalidate, or match incoming memory access requests against stored address ranges.

### Use Case
This module is primarily used in multi-core or multi-master memory systems to implement the Load-Reserved (LR) and Store-Conditional (SC) synchronization primitives.
- **LR (Load-Reserved):** When a processor executes an LR instruction, this module records the target memory address and size, effectively "reserving" that location.
- **SC (Store-Conditional):** When an SC instruction is executed, this module checks if the reservation for that address is still active. If it is, the store proceeds and the reservation is cleared. If the reservation was invalidated (e.g., by another master writing to the same address), the SC fails.
- **Coherency/Consistency:** By monitoring store operations from other agents, this module ensures that if a memory location is modified after an LR but before the corresponding SC, the SC will correctly fail, maintaining the atomicity of the operation.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1      | 2026-09-15 | Adnan Sami Anirban | Initial version                                        |
| 1.0      | 2026-09-15 | Adnan Sami Anirban | Stable release                                         |

Author : Adnan Sami Anirban (adnananirban259@gmail.com)
