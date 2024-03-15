##########
# start of the binary to execute
#
# This needs to be the last object file linked into the VM, except for the 6502 binary to be executed.
# It exports the "binary" symbol that will either be followed by the linked-in binary, or by the
# concatenated binary in case no binary is linked in.
#
# We want the VM to be usable with a compiled-in binary, as well as just concatenating a binary
# immediately after the vm.input image. Because of this, we can't expect the binary to export any
# symbols (because those would not be present in an image without binary, so it wouldn't link).
#
# The end of the vm.input image is marked by the linker using the __heap_start symbol, which is
# also used by heap.s in libxib. The VM without a binary must not use the heap unless it takes
# care the overlap between the heap and the appended binary image.

# Header of the binary to execute. In this case there is no built-in binary,
# so we just define the symbols to make the VM compile

.EXPORT binary_start_address
.EXPORT binary_load_address
.EXPORT binary_enable_tracing
.EXPORT binary_vm_callback
.EXPORT binary_length
.EXPORT binary_data

# Initial pc value, or -1 to use the reset vector
+0 = binary_start_address:

# Load address of the binary image in 6502 memory
+1 = binary_load_address:

# Tracing (0 - disable tracing, -1 - trace always, >0 - tracing past given address)
+2 = binary_enable_tracing:

# Optional callback function to call before each instruction, zero if not used
+3 = binary_vm_callback:

# Size of the binary image
+4 = binary_length:

# Binary image data
+5 = binary_data:

.EOF
