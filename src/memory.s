.EXPORT read
.EXPORT write
.EXPORT push
.EXPORT pull

# From state.s
.IMPORT mem
.IMPORT reg_sp

# From util.s
.IMPORT mod

# Where IO is mapped in 6502 memory
.SYMBOL IOPORT                          0xfff0

##########
read:
.FRAME addr; value, tmp                 # returns value
    arb -2

    # Is this IO?
    eq  [rb + addr], IOPORT, [rb + tmp]
    jz  [rb + tmp], .mem

    # Yes, do we need to simulate a 0x0d?
    jnz [.simulate_0d_flag], .simulate_0d

.next_char:
    # No, regular input
    in  [rb + value]

    # Drop any 0x0d characters, we simulate those after a 0x0a automatically
    eq  [rb + value], 13, [rb + tmp]
    jnz [rb + tmp], .next_char

    # If 0x0a, next input char should be 0x0d
    eq  [rb + value], 10, [.simulate_0d_flag]

    jz  0, .done

.simulate_0d:
    # If the last character we got was 0x0a, simulate a following 0x0d
    add 0, 0, [.simulate_0d_flag]
    add 13, 0, [rb + value]

    jz  0, .done

.mem:
    # No, regular memory read
    add [mem], [rb + addr], [ip + 1]
    add [0], 0, [rb + value]

.done:
    arb 2
    ret 1

.simulate_0d_flag:
    db  0
.ENDFRAME

##########
write:
.FRAME addr, value; tmp
    arb -1

    # Is this IO?
    eq  [rb + addr], IOPORT, [rb + tmp]
    jz  [rb + tmp], .mem

    # Yes, drop any 0x0a characters
    eq  [rb + value], 13, [rb + tmp]
    jnz [rb + tmp], .done

    # Output the character
    out [rb + value]
    jz  0, .done

.mem:
    # No, regular memory write
    add [mem], [rb + addr], [ip + 3]
    add [rb + value], 0, [0]

.done:
    arb 1
    ret 2
.ENDFRAME

##########
push:
.FRAME value;
    add 0x100, [reg_sp], [rb - 1]       # stack starts at 0x100
    add [rb + value], 0, [rb - 2]
    arb -2
    call write

    add [reg_sp], -1, [rb - 1]
    add 0x100, 0, [rb - 2]
    arb -2
    call mod
    add [rb - 4], 0, [reg_sp]

    ret 1
.ENDFRAME

##########
pull:
.FRAME tmp                              # returns tmp
    arb -1

    add [reg_sp], 1, [rb - 1]
    add 0x100, 0, [rb - 2]
    arb -2
    call mod
    add [rb - 4], 0, [reg_sp]

    add 0x100, [reg_sp], [rb - 1]         # stack starts at 0x100
    arb -1
    call read
    add [rb - 3], 0, [rb + tmp]

    arb 1
    ret 0
.ENDFRAME

.EOF
