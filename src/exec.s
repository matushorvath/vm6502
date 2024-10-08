.EXPORT execute
.EXPORT execute_nop
.EXPORT invalid_opcode

# From the linked 6502 binary
.IMPORT binary_enable_tracing
.IMPORT binary_vm_callback

# From error.s
.IMPORT report_error

# From instructions.s
.IMPORT instructions

# From memory.s
.IMPORT read

# From state.s
.IMPORT reg_pc

# From trace.s
.IMPORT print_trace

# From util.s
.IMPORT incpc

##########
execute:
.FRAME tmp, op, exec_fn, param_fn
    arb -4

.loop:
    # Skip tracing if disabled
    jz  [binary_enable_tracing], .tracing_done

    # If the [binary_enable_tracing] flag is positive, we use it as an address
    # starting from where we should turn on tracing
    eq  [binary_enable_tracing], [reg_pc], [rb + tmp]
    jz  [rb + tmp], .tracing_different_address

    # Address match, turn on tracing
    add -1, 0, [binary_enable_tracing]

.tracing_different_address:
    # Print trace if enabled
    eq  [binary_enable_tracing], -1, [rb + tmp]
    jz  [rb + tmp], .tracing_done

    call print_trace

.tracing_done:
    # Call the callback if enabled
    jz  [binary_vm_callback], .callback_done

    call [binary_vm_callback]
    jnz [rb - 2], .callback_done

    # Callback returned 0, halt
    jz  0, .hlt

.callback_done:
    # Read op code
    add [reg_pc], 0, [rb - 1]
    arb -1
    call read
    add [rb - 3], 0, [rb + op]

    # Increase pc
    call incpc

    # Process hlt
    eq  [rb + op], 2, [rb + tmp]
    jnz [rb + tmp], .hlt

    # Find exec and param functions for this instruction
    mul [rb + op], 7, [rb + tmp]                            # one record is 7 bytes long

    add instructions + 5, [rb + tmp], [ip + 1]              # exec function is at index 5 in the record
    add [0], 0, [rb + exec_fn]

    add instructions + 6, [rb + tmp], [ip + 1]              # param function is at index 6 in the record
    add [0], 0, [rb + param_fn]

    # If there is a param_fn, call it; then call exec_fn with the result as a parameter
    jz  [rb + param_fn], .no_param_fn

    call [rb + param_fn]
    add [rb - 2], 0, [rb - 1]
    arb -1
    call [rb + exec_fn + 1]     # +1 to compensate for arb -1

    jz  0, .loop

.no_param_fn:
    # No param_fn, just call exec_fn with no parameters
    call [rb + exec_fn]

    jz  0, .loop

.hlt:
    arb 4
    ret 0
.ENDFRAME

##########
execute_nop:
.FRAME
    ret 0
.ENDFRAME

##########
invalid_opcode:
.FRAME
    arb -0

    add invalid_opcode_message, 0, [rb - 1]
    arb -1
    call report_error

invalid_opcode_message:
    db  "invalid opcode", 0
.ENDFRAME

.EOF
