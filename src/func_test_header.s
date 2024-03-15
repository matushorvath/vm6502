# This the header for the 6502 functional test binary.
# It needs to be linked immediately after binary.o and immediately before the functional test binary itself.

# The binary is available in git repository https://github.com/Klaus2m5/6502_65C02_functional_tests

.EXPORT binary_start_address
.EXPORT binary_load_address
.EXPORT binary_enable_tracing
.EXPORT binary_vm_callback

.IMPORT func_test_callback

# Initial pc value; can be found using bin_files/6502_functional_test.lst, search for "Program start address is at"
binary_start_address:
    db  0x0400

# Load address for the functional test binary
binary_load_address:
    db  0

# Tracing (0 - disable tracing, -1 - trace always, >0 - tracing past given address)
binary_enable_tracing:
    db  0

# Optional callback function to call before each instruction, zero if not used
binary_vm_callback:
    db  func_test_callback

# Symbols binary_length and binary data are provided by func_test_data.o

.EOF
