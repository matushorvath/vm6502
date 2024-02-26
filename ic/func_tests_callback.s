# Callback function called by the VM for every 6502 instruction executed.

.EXPORT func_tests_callback

# From state.s
.IMPORT reg_pc

# From libxib.a
.IMPORT print_num_radix
.IMPORT print_str
.IMPORT halt_and_catch_fire

# We use this to detect a failed/successful test run and halt the VM, since the functional tests
# themselves never finish, they just enter a tight endless loop.

# Previous value of the pc register
func_tests_prev_pc:
    db  -1

# Test success address
# Can be found using bin_files/6502_functional_test.lst, search for "test passed, no errors"
.SYMBOL SUCCESS_ADDRESS                 13417       # 0x3469

func_tests_callback:
.FRAME tmp                              # returns tmp
    arb -1

    # Have we reached the successful end of tests?
    eq  [reg_pc], SUCCESS_ADDRESS, [rb + tmp]
    jnz [rb + tmp], func_tests_callback_passed

    # Are we in a tight loop?
    eq  [reg_pc], [func_tests_prev_pc], [rb + tmp]
    jnz [rb + tmp], func_tests_callback_failed

    # Save previous pc value
    add [reg_pc], 0, [func_tests_prev_pc]

    # Return 1 to keep running
    add 1, 0, [rb + tmp]
    jz  0, func_tests_callback_done

func_tests_callback_passed:
    # Successful test run
    add func_tests_passed, 0, [rb - 1]
    arb -1
    call print_str

    # Return 0 to halt
    add 0, 0, [rb + tmp]
    jz  0, func_tests_callback_done

func_tests_callback_failed:
    # Failed test run
    add func_tests_failed_start, 0, [rb - 1]
    arb -1
    call print_str

    add [reg_pc], 0, [rb - 1]
    add 16, 0, [rb - 2]
    arb -2
    call print_num_radix

    add func_tests_failed_end, 0, [rb - 1]
    arb -1
    call print_str

    # Crash the intcode VM to report an error
    # For this to work, stdin must be redirected from a file, e.g. from /dev/null
    # If you don't redirect stdin, this just waits for console input forever
    call halt_and_catch_fire

func_tests_callback_done:
    arb 1
    ret 0
.ENDFRAME

# Strings
func_tests_passed:
    db  "Functional tests PASSED", 10, 0
func_tests_failed_start:
    db  "Functional tests FAILED (address: $", 0
func_tests_failed_end:
    db  ")", 10, 0

.EOF
