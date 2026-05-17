.data


; VM state
vm_flags        DB 0            ; bit0=ZF, bit1=SF
vm_sp           DB 18           ; software stack pointer (grows down from 18)
vm_halted       DB 0
trace_mode      DB 1
fetch_done      DB 0
current_opcode  DB 0
current_operand DB 0
acc_before      DW 0            ; ACC snapshot taken before each execute
pc_before       DW 0
instr_count    DW 0
user_value      DB 5            ; user injected starting value
saved_acc       DW 0            ; scratch slot used to print AX after PRT macro
vm_memory       DB 256 DUP(0)
vm_stack        DB 20 DUP(0)
prog_base       DW OFFSET prog1
prog_len        DB prog1_len

;  Jump table: dispatch via BX = opcode*2 
jump_table  DW OFFSET handler_halt,  OFFSET handler_load
            DW OFFSET handler_store, OFFSET handler_fetch
            DW OFFSET handler_add,   OFFSET handler_sub
            DW OFFSET handler_mul,   OFFSET handler_jmp
            DW OFFSET handler_jz,    OFFSET handler_jnz
            DW OFFSET handler_print, OFFSET handler_call
            DW OFFSET handler_ret,   OFFSET handler_cmp

; Demo programs each instruction = opcode byte, operand byte
prog1:  ; Arithmetic: 5+3=8, -1=7, *2=14
  DB 01h,05h, 04h,03h, 05h,01h, 06h,02h, 0Ah,00h, 00h,00h
prog1_len EQU 6

prog2:  ; Memory store/fetch -> 30
  DB 01h,0Ah, 02h,00h, 01h,14h, 02h,01h, 03h,00h, 04h,00h
  DB 03h,01h, 04h,0Ah, 0Ah,00h, 00h,00h
prog2_len EQU 10

prog3:  ; Countdown loop with JNZ
  DB 01h,05h, 02h,00h, 03h,00h, 0Ah,00h, 05h,01h, 02h,00h, 09h,02h, 0Ah,00h, 00h,00h
prog3_len EQU 9

prog4:  ; CALL/RET: double subroutine called twice
  DB 01h,07h, 0Bh,06h, 0Ah,00h, 0Bh,06h, 0Ah,00h, 00h,00h, 06h,02h, 0Ch,00h
prog4_len EQU 8

.code

;  fetch_stage
; ============================================================
fetch_stage PROC
    push ax
    push bx
    push dx
    PRT str_fetch_hdr
    PRT str_fetch_pc
    mov ax, si
    call print_num

    ; Read opcode from bytecode[PC]
    mov bx, prog_base
    add bx, si
    mov al, [bx]
    mov current_opcode, al
    PRT str_fetch_op
    xor ah, ah                  ; AH=0 so AX = byte (used for hex print)
    mov al, current_opcode
    call print_hex_byte

    ; Read operand from bytecode[PC+1]
    inc bx
    mov al, [bx]
    mov current_operand, al
    PRT str_fetch_opd
    xor ah, ah
    mov al, current_operand
    call print_hex_byte

    PRT str_fetch_ok
    mov fetch_done, 1
    pop dx
    pop bx
    pop ax
    ret
fetch_stage ENDP

;  decode_stage
; ============================================================
decode_stage PROC
    push ax
    push bx
    push cx
    push dx
    PRT str_dec_hdr

    ; Linear search of IDT for current_opcode
    mov cx, IDT_SIZE
    mov bx, OFFSET idt
idt_search:
    mov al, [bx]
    cmp al, current_opcode
    je  idt_found
    add bx, IDT_ENTRY_SIZE
    loop idt_search
    PRT str_err_op
    jmp decode_done

idt_found:
    ; Print opcode in hex
    PRT str_dec_op
    xor ah, ah
    mov al, current_opcode
    call print_hex_byte

    ; Print 6-char mnemonic (bytes 1..6 of IDT entry)
    PRT str_dec_mn
    push bx
    inc bx
    mov cx, 6
print_mnemonic:
    mov dl, [bx]
    mov ah, 02h
    int 21h
    inc bx
    loop print_mnemonic
    pop bx

    ; Print type (byte 7 of IDT entry)
    PRT str_dec_type
    mov al, [bx+7]
    call print_type

    ; Print operand value
    PRT str_dec_opd
    xor ax, ax
    mov al, current_operand
    call print_num

    ; Print operand role (immediate/address/target/unused)
    mov al, current_opcode
    call print_operand_meaning

    ; Print "will do" description
    PRT str_dec_will
    call print_will_desc

decode_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
decode_stage ENDP

;  execute_stage - jump table 
; ============================================================
execute_stage PROC
    push bx
    push cx
    push dx
    PRT str_exe_hdr
    mov acc_before, ax
    mov pc_before, si
    inc instr_count

    ; Dispatch: jump_table[opcode * 2]
    xor bx, bx
    mov bl, current_opcode
    cmp bx, 0Dh
    ja  exec_error_op
    shl bx, 1
    jmp jump_table[bx]

exec_after_handler:
    mov fetch_done, 0
    cmp trace_mode, 1
    jne exec_done
    call print_exec_state
exec_done:
    pop dx
    pop cx
    pop bx
    ret

exec_error_op:
    PRT str_err_op
    mov vm_halted, 1
    jmp exec_after_handler
execute_stage ENDP

; ============================================================

; LOAD: ACC = operand
handler_load:
    xor ah, ah
    mov al, current_operand
    call update_flags
    add si, 2
    jmp exec_after_handler

; ADD: ACC = ACC + operand
handler_add:
    PRT str_alu_eq
    mov ax, acc_before
    call print_num
    PRT str_alu_plus
    xor ax, ax
    mov al, current_operand
    call print_num
    PRT str_alu_res
    mov ax, acc_before
    xor bx, bx
    mov bl, current_operand
    add ax, bx
    mov saved_acc, ax           ; stash before PRT-style calls below
    call print_num
    mov ax, saved_acc
    call update_flags
    add si, 2
    jmp exec_after_handler

; SUB: ACC = ACC - operand. Sets ZF when result hits 0.
handler_sub:
    PRT str_alu_eq
    mov ax, acc_before
    call print_num
    PRT str_alu_minus
    xor ax, ax
    mov al, current_operand
    call print_num
    PRT str_alu_res
    mov ax, acc_before
    xor bx, bx
    mov bl, current_operand
    sub ax, bx
    mov saved_acc, ax
    call print_num
    mov ax, saved_acc
    call update_flags
    add si, 2
    jmp exec_after_handler

; MUL: ACC = ACC * operand. IMUL writes DX:AX, we keep AX.
handler_mul:
    PRT str_alu_eq
    mov ax, acc_before
    call print_num
    PRT str_alu_mul
    xor ax, ax
    mov al, current_operand
    call print_num
    PRT str_alu_res
    push dx
    mov ax, acc_before
    xor bx, bx
    mov bl, current_operand
    imul bx                     ; DX:AX = AX * BX, keep AX only
    pop dx
    mov saved_acc, ax
    call print_num
    mov ax, saved_acc
    call update_flags
    add si, 2
    jmp exec_after_handler

; STORE: vm_memory[operand] = ACC
handler_store:
    push bx
    mov saved_acc, ax           ; preserve ACC across PRT
    PRT str_store_wr
    xor bx, bx
    mov bl, current_operand
    PRT str_mem_chg
    xor ax, ax
    mov al, current_operand
    call print_num
    PRT str_mem_was
    xor ax, ax
    mov al, vm_memory[bx]
    call print_num
    PRT str_arrow
    mov ax, saved_acc           ; restore ACC for the write + print
    mov vm_memory[bx], al
    call print_num
    pop bx
    add si, 2
    jmp exec_after_handler

; FETCH: ACC = vm_memory[operand]
handler_fetch:
    push bx
    PRT str_fetch_rd
    xor bx, bx
    mov bl, current_operand
    PRT str_mem_chg
    xor ax, ax
    mov al, current_operand
    call print_num
    PRT str_mem_was
    xor ax, ax
    mov al, vm_memory[bx]
    call print_num
    xor ax, ax
    mov al, vm_memory[bx]       ; final value into ACC (zero-extended)
    call update_flags
    pop bx
    add si, 2
    jmp exec_after_handler

; JMP: PC = operand * 2.
; SI has no addressable low half, so route through AX.
handler_jmp:
    PRT str_jmp_unc
    xor ax, ax
    mov al, current_operand
    shl ax, 1
    mov si, ax
    jmp exec_after_handler

; JZ: jump if ZF=1
handler_jz:
    PRT str_jz_chk
    xor ax, ax
    mov al, vm_flags
    and al, 01h
    call print_num
    test vm_flags, 01h
    jz  jz_not_taken
    PRT str_jz_tak
    xor ax, ax
    mov al, current_operand
    shl ax, 1
    mov si, ax
    jmp exec_after_handler
jz_not_taken:
    PRT str_jz_not
    add si, 2
    jmp exec_after_handler

; JNZ: jump if ZF=0
handler_jnz:
    PRT str_jz_chk
    xor ax, ax
    mov al, vm_flags
    and al, 01h
    call print_num
    test vm_flags, 01h
    jnz jnz_not_taken
    PRT str_jnz_tak
    xor ax, ax
    mov al, current_operand
    shl ax, 1
    mov si, ax
    jmp exec_after_handler
jnz_not_taken:
    PRT str_jnz_not
    add si, 2
    jmp exec_after_handler

; CMP: ACC vs operand. Sets flags only, ACC unchanged.
handler_cmp:
    push ax
    PRT str_cmp_cmp
    mov ax, acc_before
    xor bx, bx
    mov bl, current_operand
    cmp ax, bx
    je  cmp_equal
    jl  cmp_less
    and vm_flags, 0FCh          ; clear ZF, SF
    PRT str_cmp_gt
    jmp cmp_done
cmp_equal:
    or vm_flags, 01h            ; set ZF
    and vm_flags, 0FDh          ; clear SF
    PRT str_cmp_eq
    jmp cmp_done
cmp_less:
    and vm_flags, 0FEh          ; clear ZF
    or vm_flags, 02h            ; set SF
    PRT str_cmp_lt
cmp_done:
    pop ax
    add si, 2
    jmp exec_after_handler

; PRINT: output ACC
handler_print:
    mov saved_acc, ax           ; preserve ACC across PRT
    PRT str_prt_out
    mov ax, saved_acc           ; restore before print_num
    call print_num
    PRT str_nl
    mov ax, saved_acc           ; restore for trace display
    add si, 2
    jmp exec_after_handler

; CALL: push return addr (PC+2), then PC = operand*2
handler_call:
    push bx
    PRT str_call_push
    cmp vm_sp, 2
    jb  call_overflow

    mov ax, si
    add ax, 2                   ; AX = return address
    sub vm_sp, 2
    xor bx, bx
    mov bl, vm_sp
    mov vm_stack[bx], al
    inc bx
    mov vm_stack[bx], ah

    PRT str_stk_push
    xor ax, ax
    mov al, vm_sp
    add al, 2                   ; old SP
    call print_num
    PRT str_arrow
    xor ax, ax
    mov al, vm_sp
    call print_num

    PRT str_call_ret
    mov ax, si
    add ax, 2
    shr ax, 1                   ; byte offset -> instruction #
    call print_num
    PRT str_call_jmp
    xor ax, ax
    mov al, current_operand
    call print_num

    xor ax, ax
    mov al, current_operand
    shl ax, 1
    mov si, ax                  ; new PC

    pop bx
    jmp exec_after_handler
call_overflow:
    PRT str_err_sof
    mov vm_halted, 1
    pop bx
    jmp exec_after_handler

; RET: pop return addr from software stack, restore PC
handler_ret:
    push bx
    PRT str_ret_pop
    cmp vm_sp, 18
    jae ret_underflow

    xor bx, bx
    mov bl, vm_sp
    mov al, vm_stack[bx]        ; low byte
    inc bx
    mov ah, vm_stack[bx]        ; high byte
    add vm_sp, 2
    mov saved_acc, ax           ; saved_acc = return address

    PRT str_stk_pop
    xor ax, ax
    mov al, vm_sp
    sub al, 2                   ; old SP
    call print_num
    PRT str_arrow
    xor ax, ax
    mov al, vm_sp
    call print_num

    PRT str_ret_addr
    mov ax, saved_acc
    shr ax, 1                   ; byte offset -> instruction #
    call print_num

    mov si, saved_acc           ; restore PC
    pop bx
    jmp exec_after_handler
ret_underflow:
    PRT str_err_suf
    mov vm_halted, 1
    pop bx
    jmp exec_after_handler

; HALT: stop the VM
handler_halt:
    PRT str_halt_msg
    mov vm_halted, 1
    call print_end_summary
    jmp exec_after_handler

;  reset_vm
; ============================================================
reset_vm PROC
    push ax
    push bx
    push cx
    xor ax, ax
    xor si, si
    mov vm_flags, 0
    mov vm_sp, 18
    mov instr_count, 0
    mov fetch_done, 0
    mov vm_halted, 0

    ; Zero vm_memory
    xor bx, bx
    mov cx, 256
zero_memory:
    mov vm_memory[bx], 0
    inc bx
    loop zero_memory

    ; Zero vm_stack
    xor bx, bx
    mov cx, 20
zero_stack:
    mov vm_stack[bx], 0
    inc bx
    loop zero_stack

    ; Re-inject user_value into first LOAD's operand byte
    mov bx, prog_base
    inc bx
    mov al, user_value
    mov [bx], al
    pop cx
    pop bx
    pop ax
    ret
reset_vm ENDP

;  update_flags
; ============================================================
update_flags PROC
    push ax
    test ax, ax
    jnz  flag_not_zero
    or vm_flags, 01h            ; ZF = 1
    jmp  flag_check_sign
flag_not_zero:
    and vm_flags, 0FEh          ; ZF = 0
flag_check_sign:
    test ax, 8000h
    jz   flag_positive
    or vm_flags, 02h            ; SF = 1
    jmp  flag_done
flag_positive:
    and vm_flags, 0FDh          ; SF = 0
flag_done:
    pop ax
    ret
update_flags ENDP

