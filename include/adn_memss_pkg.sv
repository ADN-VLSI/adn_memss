`ifndef __GUARD_ADN_MEMSS_PKG_SV__
`define __GUARD_ADN_MEMSS_PKG_SV__ 0

package adn_memss_pkg;
    typedef enum logic [3:0] {
        NONE,
        LR,
        SC,
        AMOSWAP,
        AMOADD,
        AMOXOR,
        AMOAND,
        AMOOR,
        AMOMIN,
        AMOMAX,
        AMOMINU,
        AMOMAXU
    } amo_op_t;

  // Sideband information for AMO instructions
    typedef struct packed {
        logic   aq;
        logic   rl;
        logic   doubleword;
        amo_op_t op;
    } sideband_t;

endpackage

`endif
