.EXPORT init_memory

# From the linked 6502 binary
.IMPORT binary_load_address
.IMPORT binary_count
.IMPORT binary_header
.IMPORT binary_data

# From error.s
.IMPORT report_error

# From state.s
.IMPORT mem

# From util.s
.IMPORT check_range

##########
init_memory:
.FRAME section_index
    arb -1

    # Initialize memory space for the 6502.

    # Validate the load address is a valid 16-bit number
    add [binary_load_address], 0, [rb - 1]
    add 0xffff, 0, [rb - 2]
    arb -2
    call check_range

    # The 6502 memory space will start where section data starts now
    add binary_data, 0, [mem]

    # Process binary sections end to start
    add [binary_count], 0, [rb + section_index]

.loop:
    jz  [rb + section_index], .done
    add [rb + section_index], -1, [rb + section_index]

    add [rb + section_index], 0, [rb - 1]
    arb -1
    call init_section

    jz  0, .loop

.done:
    arb 1
    ret 0
.ENDFRAME

##########
init_section:
.FRAME section_index; section_address, section_start, section_size, tmp
    arb -4

    # Load section header
    mul [rb + section_index], 3, [rb + tmp]
    add binary_header, [rb + tmp], [rb + tmp]

    add [rb + tmp], 0, [ip + 1]
    add [0], 0, [rb + section_address]
    add [rb + tmp], 1, [ip + 1]
    add [0], 0, [rb + section_start]
    add [rb + tmp], 2, [ip + 1]
    add [0], 0, [rb + section_size]

    # Calculate target 6502 address where this section should be moved
    add [binary_load_address], [rb + section_address], [rb + section_address]

    # Validate the section will fit to 16-bits when moved there
    add [rb + section_address], [rb + section_size], [rb + tmp]
    lt  0x10000, [rb + tmp], [rb + tmp]
    jnz [rb + tmp], .too_big

    # Source intcode address where this section currently is
    add binary_data, [rb + section_start], [rb - 1]
    # Target intcode address where this section should be moved
    add [mem], [rb + section_address], [rb - 2]
    # Number of bytes to copy
    add [rb + section_size], 0, [rb - 3]

    arb -3
    call move_memory_reverse

    arb 4
    ret 1

.too_big:
    add .too_big_message, 0, [rb - 1]
    arb -1
    call report_error

.too_big_message:
    db  "image too big to load at specified address", 0
.ENDFRAME

##########
move_memory_reverse:
.FRAME source, target, count; tmp
    arb -1

    # Do we need to move the memory at all?
    eq  [rb + source], [rb + target], [rb + tmp]
    jnz [rb + tmp], .done

.loop:
    # Move a section from source to target (iterating in reverse direction)
    jz  [rb + count], .done
    add [rb + count], -1, [rb + count]

    # Copy one byte
    add [rb + source], [rb + count], [ip + 5]
    add [rb + target], [rb + count], [ip + 3]
    add [0], 0, [0]

    # Zero the source byte
    add [rb + source], [rb + count], [ip + 3]
    add 0, 0, [0]

    jz  0, .loop

.done:
    arb 1
    ret 3
.ENDFRAME

.EOF
