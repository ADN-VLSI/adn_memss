# ADN MEMSS Design Specification

## Theory

# Memory Subsystem 

A **memory subsystem** is the part of a processor-based system that manages communication between the processor and memory. It receives memory access requests from the processor, decodes the requested operation, controls the access sequence, and returns the required data or completion status. The subsystem supports normal **load and store operations** as well as **atomic memory operations**. **Load-Reserved (LR)** and **Store-Conditional (SC)** are used to implement synchronization primitives. LR loads a value from a memory location while establishing a reservation on that location. A subsequent SC attempts to store a new value only if the reservation is still valid. The SC therefore succeeds or fails depending on whether the monitored location has been modified by another access. **Atomic Memory Operations (AMOs)** perform a read-modify-write operation as a single atomic transaction. The memory subsystem reads the original value, performs the required operation such as **swap, add, AND, OR, XOR, minimum, or maximum**, and writes the result back to memory without allowing another transaction to interfere with the atomic sequence. The memory subsystem also provides **interface and data-width adaptation** between the processor and physical memory. A width-conversion stage can split or combine memory transfers when the processor-side and memory-side data widths are different, while same-width accesses can pass through directly.

Overall, the memory subsystem provides a reliable and reusable interface between the **CPU and physical memory**, handling **load/store accesses, LR/SC synchronization, AMO atomic operations, request sequencing, response generation, and memory-width conversion**, while keeping the processor-side control logic independent of the underlying memory implementation.
## Questions and Answers

| Question | Answer |
| --- | --- |
| What problem does the design solve? | _It allows multiple harts (CPU/LSU) to access a shared external memory, properly._ |
| What are the supported operating modes? | _Compatible with both 32 bits and 64 bit HARTs and or Memory modules._ |
| What are the error and boundary conditions? | Addresses must be aligned. The CPU and memory data widths must match. |
| How can the signed and unsigned problem be solved? | Use signed comparison for `AMOMIN`/`AMOMAX` and unsigned comparison for `AMOMINU`/`AMOMAXU`. |
| How is LR/SC handled in a multihart system? | Each hart keeps its own reserved address. An SC succeeds only if that reservation is still valid. |
| What happens to a hart's LR reservation when another core writes to the same memory address? | The reservation is cleared, so the next SC fails. |
| What events are allowed to invalidate an LR reservation? | A write to the reserved address, an SC attempt, reset, or an explicit reservation clear can invalidate it. |


## Block Diagram
The following diagram shows the approved architectural design of **memory subsystem**.


<img src="adn_memss_des.svg" alt="MEMSUB Architecture">


## Signals

| Signal Name | Direction | Description |
|---|---|---|
| `clk_i` | Input | Clock signal. |
| `arst_ni` | Input | Active-low asynchronous reset signal. |
| `cpu_sideband_t_i` | Input | Request from CPU containing information about **aq, rl, doubleword, op, NONE, LR, SC, AMOSWAP,AMOADD, AMOXOR, AMOAND, AMOOR, AMOMIN, AMOMAX, AMOMINU and AMOMAXU**. |
| `cpu_pmi_req_t_i` | Input | Request from CPU containing information about **maddr, mwe, mwdata, mstrb, and mreq**. |
| `mem_pmi_rsp_t_i` | Input | Memory response containing information about **mgnt, mack, mrdata, and mresp**. |
| `mem_pmi_req_t_o` | Output | Memory request sent to the memory subsystem. |
| `cpu_pmi_rsp_t_o` | Output | Response sent to CPU from the memory subsystem. |

## Functional Blocks

### FSM

It is the core unit of the system. It captures the instruction from the CPU, decodes it, and processes it accordingly. The FSM consists of the following states: **IDLE, SC_CHECK, RD, WR, and ACK**. It controls **Normal Load/Store, AMO_ALU, Reservation (LR/SC), and memory request/response operation flow**. 

#### FSM Block Diagram

```mermaid
flowchart LR
    reset(( )):::invisible
    sidle((<b>S_IDLE</b> <br> cpu_resp_o.mgnt = 1 <br> mem_req_o.mreq = 0))
    srd((<b>S_RD</b> <br> mem_req_o.maddr = addr.q <br> mem_req_o.mwe = 0 <br> mem_req_o = 1))
    swr((<b>S_WR</b> <br> mem_req_o.mwe = 1 <br> mem_req_o.mreq = 1 <br> mwdata = storedata/alu_result/rs2 <br> mstrb = strb/amo_strb))
    schk((<b>S_SC_CHK</b> <br> rsv_clear_o = 1 <br> if wr_commit = 1))
    sack((<b>S_ACK</b> <br> cpu_rsp_o.mack = 1 <br> cpu_rsp_o.mrdata = data_o <br> cpu_rsp_o.mresp = err ))
    
    reset -->|reset| sidle
    sidle -->|mreq && <br> op == sc| schk -->|sc_hit = 0|sack
    sidle -->|op == LR <br> or, op == amo <br> or, op == NONE <br> or, !mwe| srd -->|mack && <br> op == amo|swr
    schk -->|sc_hit == 1| swr

    sidle --> |cpu_req_i.mreq| sidle
    srd --> |!mack| srd
    swr --> |!mack| swr

    sidle -.->|mreq && misalligned: <br>  error| sack
    sack -.-> sidle
    sidle --> |mreq && <br> op == NONE <br>&& mwe| swr
    swr -->|mem_rsp.mack <br> or, <br> mem_rsp_i.mrsp = 1| sack
    srd -->|mem_rsp_i.mresp = 1 && <br> or, op == Load/LR | sack

 classDef invisible fill:none,stroke:none,color:none

```


The memory subsystem controls and executes the logic for memory operations. It receives memory operation requests from the CPU, processes and decodes them through the FSM block, performs the required operation, and generates the corresponding memory request and CPU response.

### AMO_ALU

Performs the required operation for **Normal Load/Store and Atomic Memory Operations**.

### Reservation Unit

Performs the required operations for **Load Reserved (LR) and Store Conditional (SC)**. It can clear or update the reservation and maintains the **reserved address and its validity**.


## Architectural Decision

### Proposal_1

_Describe the first architectural option, including its implementation approach, benefits, limitations, and estimated cost._

### Proposal_2

_Describe the second architectural option, including its implementation approach, benefits, limitations, and estimated cost._

### Approved_Proposal

- **Selected proposal:** _Proposal_1 or Proposal_2._
- **Decision owner:** _Name or team._
- **Decision date:** _YYYY-MM-DD._
- **Rationale:** _Explain why this proposal was approved._
- **Consequences:** _Document expected trade-offs and follow-up actions._

## Verification

### Debug Issues and Solutions

| Serial No. | Debug issue | Solution | 
| --- | --- | --- | 
| 01 | *Describe the issue.* | *Describe the fix.* | 
| 02 | *Describe the issue.* | *Describe the fix.* | 

### Verification Checklist

- [ ] RTL compiles without errors or unexpected warnings.
- [ ] Reset behavior is verified.
- [ ] Normal operating scenarios are covered.
- [ ] Boundary and error conditions are covered.
- [ ] Assertions pass.
- [ ] Regression passes.
- [ ] Coverage results meet the project target.

## Project Outcome

Summarize the completed implementation, verification results, known limitations, and any recommended future work.

- **Implementation status:** _Not started / In progress / Complete._
- **Verification status:** _Not started / In progress / Complete._
- **Known limitations:** _Add limitations._
- **Follow-up work:** _Add follow-up items._

## Simulation Command

Run the default simulation with:

```bash
make simulate TOP=<top_module_name> TN=<test_case_name> TC=<test_count> VCD=<0|1> DEBUG=<0|1> GUI=<0|1>
```

Examples:

```bash
# Run a test case in batch mode.
make simulate TOP=dummy_tb TN=default TC=1 VCD=0 DEBUG=0 GUI=0

# Run the simulation with the graphical interface.
make simulate TOP=dummy_tb TN=default TC=1 VCD=1 DEBUG=1 GUI=1
```
