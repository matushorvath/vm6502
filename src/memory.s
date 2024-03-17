.EXPORT init_memory
.EXPORT read
.EXPORT write
.EXPORT push
.EXPORT pull

# From the linked 6502 binary
.IMPORT binary_load_address
.IMPORT binary_count
.IMPORT binary_header
.IMPORT binary_data

# From error.s
.IMPORT report_error

# From state.s
.IMPORT reg_sp

# From util.s
.IMPORT check_range
.IMPORT mod

# Where IO is mapped in 6502 memory
.SYMBOL IOPORT                          0xfff0

##########
init_memory:
.FRAME section_index, section_address, section_start, section_size, tmp, src, tgt, cnt
    arb -8

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

init_memory_section_loop:
    jz  [rb + section_index], init_memory_section_done
    add [rb + section_index], -1, [rb + section_index]

    # Load section header
    mul [rb + section_index], 3, [rb + tmp]
    add binary_header, [rb + tmp], [rb + tmp]

    add [rb + tmp], 0, [ip + 1]
    add [0], 0, [rb + section_address]
    add [rb + tmp], 1, [ip + 1]
    add [0], 0, [rb + section_start]
    add [rb + tmp], 2, [ip + 1]
    add [0], 0, [rb + section_size]

    # Offset section start address by binary_load_address
    add [binary_load_address], [rb + section_address], [rb + section_address]

    # Validate the section will fit to 16-bits when loaded there
    add [rb + section_address], [rb + section_size], [rb + tgt]
    lt  0x10000, [rb + tgt], [rb + tmp]
    jz  [rb + tmp], init_memory_section_address_ok

    add image_too_big_error, 0, [rb - 1]
    arb -1
    call report_error

init_memory_section_address_ok:
    # Calculate beginning address of the source
    add binary_data, [rb + section_start], [rb + src]

    # Calculate the beginning address of the target
    add [mem], [rb + section_address], [rb + tgt]

    # Do we need to move the section at all?
    eq  [rb + src], [rb + tgt], [rb + tmp]
    jnz [rb + tmp], init_memory_bytes_done

    # Number of bytes to copy
    add [rb + section_size], 0, [rb + cnt]      # TODO refactor, don't need cnt

init_memory_bytes_loop:
    # Move the image from src to tgt (iterating in reverse direction)
    jz  [rb + cnt], init_memory_bytes_done
    add [rb + cnt], -1, [rb + cnt]

    # Copy one byte
    add [rb + src], [rb + cnt], [ip + 5]
    add [rb + tgt], [rb + cnt], [ip + 3]
    add [0], 0, [0]

    # Zero the source byte
    add [rb + src], [rb + cnt], [ip + 3]
    add 0, 0, [0]

    jz  0, init_memory_bytes_loop

init_memory_bytes_done:
    jz  0, init_memory_section_loop

init_memory_section_done:
    arb 8
    ret 0
.ENDFRAME

##########
read:
.FRAME addr; value, tmp                 # returns value
    arb -2

    # Is this IO?
    eq  [rb + addr], IOPORT, [rb + tmp]
    jz  [rb + tmp], read_mem

    # Yes, do we need to simulate a 0x0d?
    jnz [read_io_simulate_0d_flag], read_io_simulate_0d

read_io_next_char:
    # No, regular input
    in  [rb + value]

    # Drop any 0x0d characters, we simulate those after a 0x0a automatically
    eq  [rb + value], 13, [rb + tmp]
    jnz [rb + tmp], read_io_next_char

    # If 0x0a, next input char should be 0x0d
    eq  [rb + value], 10, [read_io_simulate_0d_flag]

    jz  0, read_done

read_io_simulate_0d:
    # If the last character we got was 0x0a, simulate a following 0x0d
    add 0, 0, [read_io_simulate_0d_flag]
    add 13, 0, [rb + value]

    jz  0, read_done

read_mem:
    # No, regular memory read
    add [mem], [rb + addr], [ip + 1]
    add [0], 0, [rb + value]

read_done:
    arb 2
    ret 1

read_io_simulate_0d_flag:
    db  0
.ENDFRAME

##########
write:
.FRAME addr, value; tmp
    arb -1

    # Is this IO?
    eq  [rb + addr], IOPORT, [rb + tmp]
    jz  [rb + tmp], write_mem

    # Yes, drop any 0x0a characters
    eq  [rb + value], 13, [rb + tmp]
    jnz [rb + tmp], write_done

    # Output the character
    out [rb + value]
    jz  0, write_done

write_mem:
    # No, regular memory write
    add [mem], [rb + addr], [ip + 3]
    add [rb + value], 0, [0]

write_done:
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

##########
mem:
    db  0

image_too_big_error:
    db  "image too big to load at specified address", 0

.EOF
