.EXPORT reg_pc
.EXPORT reg_sp

.EXPORT reg_a
.EXPORT reg_x
.EXPORT reg_y

.EXPORT flag_negative
.EXPORT flag_overflow
.EXPORT flag_decimal
.EXPORT flag_interrupt
.EXPORT flag_zero
.EXPORT flag_carry

.EXPORT init_state
.EXPORT pack_sr
.EXPORT unpack_sr

# From binary.s
.IMPORT binary

# From error.s
.IMPORT report_error

# From memory.s
.IMPORT read

# From util.s
.IMPORT check_range

##########
# vm state

reg_pc:
    db  0
reg_sp:
    db  0xff

reg_a:
    db  0
reg_x:
    db  0
reg_y:
    db  0

flag_negative:              # N
    db  0
flag_overflow:              # V
    db  0
flag_decimal:               # D
    db  0
flag_interrupt:             # I
    db  0
flag_zero:                  # Z
    db  0
flag_carry:                 # C
    db  0

##########
init_state:
.FRAME tmp
    arb -1

    # Load the start address to pc
    add [binary + 0], 0, [reg_pc]

    # If it is -1, use the reset vector
    eq  [reg_pc], -1, [rb + tmp]
    jz  [rb + tmp], init_state_skip_reset_vec

    # Read the reset vector from 0xfffc and 0xfffd
    add 0xfffd, 0, [rb - 1]
    arb -1
    call read
    mul [rb - 3], 0x100, [rb + tmp]           # read(0xfffd) * 0x100 -> [tmp]

    add 0xfffc, 0, [rb - 1]
    arb -1
    call read
    add [rb - 3], [rb + tmp], [reg_pc]      # read(0xfffc) + read(0xfffd) * 0x100 -> [reg_pc]

init_state_skip_reset_vec:
    # Check if pc is a sane value
    add [reg_pc], 0, [rb - 1]
    add 0xffff, 0, [rb - 2]
    arb -2
    call check_range

    arb 1
    ret 0
.ENDFRAME

##########
pack_sr:
.FRAME sr                                           # returns sr
    arb -1

    add 0b00110000, 0, [rb + sr]

    jz  [flag_carry], pack_sr_after_carry
    add [rb + sr], 0b00000001, [rb + sr]
pack_sr_after_carry:

    jz  [flag_zero], pack_sr_after_zero
    add [rb + sr], 0b00000010, [rb + sr]
pack_sr_after_zero:

    jz  [flag_interrupt], pack_sr_after_interrupt
    add [rb + sr], 0b00000100, [rb + sr]
pack_sr_after_interrupt:

    jz  [flag_decimal], pack_sr_after_decimal
    add [rb + sr], 0b00001000, [rb + sr]
pack_sr_after_decimal:

    jz  [flag_overflow], pack_sr_after_overflow
    add [rb + sr], 0b01000000, [rb + sr]
pack_sr_after_overflow:

    jz  [flag_negative], pack_sr_after_negative
    add [rb + sr], 0b10000000, [rb + sr]
pack_sr_after_negative:

    arb 1
    ret 0
.ENDFRAME

##########
unpack_sr:
.FRAME sr;
    lt  0b01111111, [rb + sr], [flag_negative]
    jz  [flag_negative], unpack_sr_after_negative
    add [rb + sr], -0b10000000, [rb + sr]
unpack_sr_after_negative:

    lt  0b00111111, [rb + sr], [flag_overflow]
    jz  [flag_overflow], unpack_sr_after_overflow
    add [rb + sr], -0b01000000, [rb + sr]
unpack_sr_after_overflow:

    lt  0b00011111, [rb + sr], [flag_decimal]               # flag_decimal used as tmp
    jz  [flag_decimal], unpack_sr_after_ignored
    add [rb + sr], -0b00100000, [rb + sr]
unpack_sr_after_ignored:

    lt  0b00001111, [rb + sr], [flag_decimal]               # flag_decimal used as tmp
    jz  [flag_decimal], unpack_sr_after_break
    add [rb + sr], -0b00010000, [rb + sr]
unpack_sr_after_break:

    lt  0b00000111, [rb + sr], [flag_decimal]
    jz  [flag_decimal], unpack_sr_after_decimal
    add [rb + sr], -0b00001000, [rb + sr]
unpack_sr_after_decimal:

    lt  0b00000011, [rb + sr], [flag_interrupt]
    jz  [flag_interrupt], unpack_sr_after_interrupt
    add [rb + sr], -0b00000100, [rb + sr]
unpack_sr_after_interrupt:

    lt  0b00000001, [rb + sr], [flag_zero]
    jz  [flag_zero], unpack_sr_after_zero
    add [rb + sr], -0b00000010, [rb + sr]
unpack_sr_after_zero:

    lt  0, [rb + sr], [flag_carry]

    ret 1
.ENDFRAME

.EOF
