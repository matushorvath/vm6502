.EXPORT report_error

# From state.s
.IMPORT reg_pc

# From libxib.s
.IMPORT print_num_radix
.IMPORT print_str

##########
report_error:
.FRAME message;
    add .msg_start, 0, [rb - 1]
    arb -1
    call print_str

    add [rb + message], 0, [rb - 1]
    arb -1
    call print_str

    add .msg_pc, 0, [rb - 1]
    arb -1
    call print_str

    add [reg_pc], 0, [rb - 1]
    add 16, 0, [rb - 2]
    add 0, 0, [rb - 3]
    arb -3
    call print_num_radix

    add .msg_end, 0, [rb - 1]
    arb -1
    call print_str

    out 10

    hlt

.msg_start:
    db  "vm6502 error: ", 0
.msg_pc:
    db  " (pc: ", 0
.msg_end:
    db  ")", 0
.ENDFRAME

.EOF
