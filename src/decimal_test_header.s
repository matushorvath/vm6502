# This the header for the 6502 decimal test binary.
# It needs to be linked immediately after binary.o and immediately before the decimal test binary itself.

# The binary can be built from git repository https://github.com/Klaus2m5/6502_65C02_functional_tests

# Start address for the decimal test binary
# Can be found using bin_files/6502_functional_test.lst, search for "Program start address is at"
    db  1024        # 0x0400

# Load address for the decimal test binary
    db  0

# Set up tracing
#  0 - disable tracing
# -1 - trace always
# >0 - start tracing after passing that address
    db  -1

# Callback address TODO
.IMPORT decimal_test_callback
    db  decimal_test_callback

.EOF
