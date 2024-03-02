# Callback function called by the VM for every 6502 instruction executed.

.EXPORT decimal_test_callback

# From state.s
.IMPORT reg_pc

# From libxib.a
.IMPORT print_str
.IMPORT halt_and_catch_fire

# We use this to detect a failed/successful test run and halt the VM, since the decimal test
# itself never finishes, it just enters a tight endless loop.

# Test finished address
# Can be found using bin_files/6502_functional_test.lst, search for /end_of_test$/
.SYMBOL FINISHED_ADDRESS                1099        # 0x044B

# Test error status address; 0 if test passed, 1 if test failed
# Can be found using bin_files/6502_functional_test.lst, search for /ERROR: +\.res +1,0/
.SYMBOL ERROR                           11          # 0x000B

# TODO automatically determine FINISHED_ADDRESS and ERROR from 6502_decimal_test.lst
# TODO these will potentially change with every execution
# TODO awk -e '/ERROR: +\.res +1,0/ { print(strtonum("0x" $1)) }' < ../6502_65C02_functional_tests/ca65/6502_decimal_test.lst
# TODO awk -e '/end_of_test$/ { print(strtonum("0x" $1)) }' < ../6502_65C02_functional_tests/ca65/6502_decimal_test.lst

decimal_test_callback:
.FRAME tmp                              # returns tmp
    arb -1

    # Have we reached the successful end of the test?
    eq  [reg_pc], FINISHED_ADDRESS, [rb + tmp]
    jnz [rb + tmp], decimal_test_callback_finished

    # Return 1 to keep running
    add 1, 0, [rb + tmp]
    jz  0, decimal_test_callback_done

decimal_test_callback_finished:
    # Determine success or failure
    jnz [ERROR], decimal_test_callback_failed

    # Successful test run
    add decimal_test_passed, 0, [rb - 1]
    arb -1
    call print_str

    # Return 0 to halt
    add 0, 0, [rb + tmp]
    jz  0, decimal_test_callback_done

decimal_test_callback_failed:
    # Failed test run
    add decimal_test_failed, 0, [rb - 1]
    arb -1
    call print_str

    # Crash the intcode VM to report an error
    # For this to work, stdin must be redirected from a file, e.g. from /dev/null
    # If you don't redirect stdin, this just waits for console input forever
    call halt_and_catch_fire

decimal_test_callback_done:
    arb 1
    ret 0
.ENDFRAME

# Strings
decimal_test_passed:
    db  "Decimal test PASSED", 10, 0
decimal_test_failed:
    db  "Decimal test FAILED", 10, 0

.EOF
