# This the header for the MS Basic binary.
# It needs to be linked immediately after binary.o and immediately before the MS Basic binary itself.

.EXPORT binary_start_address
.EXPORT binary_load_address
.EXPORT binary_enable_tracing
.EXPORT binary_vm_callback

# Initial pc value; use the reset vector
binary_start_address:
    db  -1

# Load address for the MS Basic binary; needs to match the BASROM memory region in $(MSBASICDIR)/vm6502.cfg.
binary_load_address:
    db  0xc000

# Tracing (0 - disable tracing, -1 - trace always, >0 - tracing past given address)
binary_enable_tracing:
    db  0

# Optional callback function to call before each instruction, zero if not used
binary_vm_callback:
    db  0

# Symbols binary_count, binary_size and binary_data are provided by msbasic_data.o

.EOF
