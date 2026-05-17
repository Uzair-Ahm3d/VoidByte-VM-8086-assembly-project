.data

; --- IDT: opcode(1) + mnemonic(6) + type(1)   type:0=data 1=arith 2=ctrl 3=io 4=sys
idt:
  DB 01h,"LOAD  ",0,  04h,"ADD   ",1,  05h,"SUB   ",1,  06h,"MUL   ",1
  DB 02h,"STORE ",0,  03h,"FETCH ",0,  07h,"JMP   ",2,  08h,"JZ    ",2
  DB 09h,"JNZ   ",2,  0Dh,"CMP   ",2,  0Bh,"CALL  ",2,  0Ch,"RET   ",2
  DB 0Ah,"PRINT ",3,  00h,"HALT  ",4
IDT_SIZE EQU 14
IDT_ENTRY_SIZE EQU 8

; --- "Will do" descriptions (must be in IDT order to match desc_table lookup) ---
desc_load     DB "ACC = operand$"
desc_add      DB "ACC = ACC + operand$"
desc_sub      DB "ACC = ACC - operand$"
desc_mul      DB "ACC = ACC x operand$"
desc_store    DB "MEM[operand] = ACC$"
desc_fetch    DB "ACC = MEM[operand]$"
desc_jmp      DB "PC = operand*2$"
desc_jz       DB "If ZF=1: PC = operand*2$"
desc_jnz      DB "If ZF=0: PC = operand*2$"
desc_cmp      DB "Compare, set flags only$"
desc_call     DB "Push PC, jump to operand*2$"
desc_ret      DB "Pop PC from stack$"
desc_print    DB "Output ACC$"
desc_halt     DB "Stop VM$"

desc_table  DW OFFSET desc_load,  OFFSET desc_add,   OFFSET desc_sub,  OFFSET desc_mul
            DW OFFSET desc_store, OFFSET desc_fetch, OFFSET desc_jmp,  OFFSET desc_jz
            DW OFFSET desc_jnz,   OFFSET desc_cmp,   OFFSET desc_call, OFFSET desc_ret
            DW OFFSET desc_print, OFFSET desc_halt

str_arrow     DB " -> $"
str_0h        DB "h$"
str_list_hdr  DB 13,10,"  PROGRAM LISTING:",13,10
              DB "  Instr  Opcode  Operand",13,10,"$"
str_list_row  DB "  #$"
str_list_sep  DB "     $"
str_fetch_hdr DB 13,10,"  -- FETCH --",13,10,"$"
str_fetch_pc  DB "  PC: $"
str_fetch_op  DB 13,10,"  byte[PC]   = $"
str_fetch_opd DB 13,10,"  byte[PC+1] = $"
str_fetch_ok  DB 13,10,"  Fetched. PC advances on Execute.",13,10,"$"
str_dec_hdr   DB 13,10,"  -- DECODE --",13,10,"$"
str_dec_op    DB "  Opcode    : $"
str_dec_mn    DB 13,10,"  Mnemonic  : $"
str_dec_type  DB 13,10,"  Type      : $"
str_dec_opd   DB 13,10,"  Operand   : $"
str_dec_imm   DB " (immediate)$"
str_dec_addr  DB " (address)$"
str_dec_tgt   DB " (target instr#)$"
str_dec_none  DB " (unused)$"
str_dec_will  DB 13,10,"  Will do   : $"
str_exe_hdr   DB 13,10,"  -- EXECUTE --",13,10,"$"
str_exe_bef   DB 13,10,"  ACC before: $"
str_exe_pc_b  DB 13,10,"  PC before : $"
str_exe_zf    DB 13,10,"  ZF: $"
str_exe_sf    DB 13,10,"  SF: $"
str_alu_eq    DB 13,10,"  ALU: $"
str_alu_plus  DB " + $"
str_alu_minus DB " - $"
str_alu_mul   DB " x $"
str_alu_res   DB " = $"
str_mem_hdr   DB 13,10,"  MEM[00-0F]:",13,10,"$"
str_mem_row   DB "  [$"
str_mem_sep   DB "]: $"
str_mem_col   DB "  $"
str_mem_chg   DB 13,10,"  MEM[$"
str_mem_was   DB "] : $"
str_reg_hdr   DB 13,10,"  REGISTERS:",13,10,"$"
str_reg_acc   DB "  ACC : $"
str_reg_pc    DB 13,10,"  PC  : $"
str_reg_sp    DB 13,10,"  SP  : $"
str_reg_tr    DB 13,10,"  TR  : $"
str_reg_on    DB "ON$"
str_reg_off   DB "OFF$"
str_stk_hdr   DB 13,10,"  STACK:",13,10,"$"
str_stk_top   DB "  SP = $"
str_stk_emp   DB 13,10,"  empty",13,10,"$"
str_stk_entr  DB 13,10,"  ret#: $"
str_stk_push  DB 13,10,"  PUSH: SP $"
str_stk_pop   DB 13,10,"  POP : SP $"
str_call_push DB 13,10,"  Saving return address...",13,10,"$"
str_call_ret  DB "  Return: instr#$"
str_call_jmp  DB 13,10,"  Jump to: instr#$"
str_ret_pop   DB 13,10,"  Restoring PC...",13,10,"$"
str_ret_addr  DB "  Return to: instr#$"
str_jmp_unc   DB 13,10,"  Unconditional jump",13,10,"$"
str_jz_chk    DB 13,10,"  ZF: $"
str_jz_tak    DB 13,10,"  ZF=1 -> JUMP",13,10,"$"
str_jz_not    DB 13,10,"  ZF=0 -> no jump",13,10,"$"
str_jnz_tak   DB 13,10,"  ZF=0 -> JUMP",13,10,"$"
str_jnz_not   DB 13,10,"  ZF=1 -> no jump",13,10,"$"
str_cmp_cmp   DB 13,10,"  CMP ACC vs operand:",13,10,"$"
str_cmp_eq    DB "  EQUAL   -> ZF=1 SF=0",13,10,"$"
str_cmp_gt    DB "  GREATER -> ZF=0 SF=0",13,10,"$"
str_cmp_lt    DB "  LESS    -> ZF=0 SF=1",13,10,"$"
str_store_wr  DB 13,10,"  Store ACC to memory",13,10,"$"
str_fetch_rd  DB 13,10,"  Fetch memory to ACC",13,10,"$"
str_type0     DB "Data$"
str_type1     DB "Arithmetic$"
str_type2     DB "Control$"
str_type3     DB "I/O$"
str_type4     DB "System$"
str_cycle_hdr DB 13,10,"  -- Cycle #$"
str_cycle_of  DB " --",13,10,"$"
str_err_op    DB 13,10,"  [ERR] Unknown opcode!",13,10,"$"
str_err_sof   DB 13,10,"  [ERR] Stack overflow!",13,10,"$"
str_err_suf   DB 13,10,"  [ERR] Stack underflow!",13,10,"$"
str_sum_hdr   DB 13,10,"  ===== PROGRAM COMPLETE =====",13,10,"$"
str_sum_cnt   DB "  Instructions: $"
str_sum_acc   DB 13,10,"  Final ACC   : $"
str_sum_pc    DB 13,10,"  Final PC    : $"
str_sum_mem   DB 13,10,"  MEM[0..3]   : $"
str_sum_end   DB 13,10,"  ============================",13,10,13,10,"$"
str_prt_out   DB 13,10,"  >> OUTPUT: $"
str_halt_msg  DB 13,10,"  *** HALT ***",13,10,"$"

.code

; ============================================================
;  Module 3 code: Display and formatting procedures
; ============================================================

; ============================================================

; Print trace info after each execute: cycle#, ACC/PC before->after, ZF, SF
print_exec_state PROC
    push ax
    push dx
    mov saved_acc, ax           ; AX at entry = ACC after execute
    PRT str_cycle_hdr
    mov ax, instr_count
    call print_num
    PRT str_cycle_of
    PRT str_exe_bef
    mov ax, acc_before
    call print_num
    PRT str_arrow
    mov ax, saved_acc           ; ACC after (was clobbered by PRTs)
    call print_num
    PRT str_exe_pc_b
    mov ax, pc_before
    call print_num
    PRT str_arrow
    mov ax, si
    call print_num
    PRT str_exe_zf
    xor ax, ax
    mov al, vm_flags
    and al, 01h
    call print_num
    PRT str_exe_sf
    xor ax, ax
    mov al, vm_flags
    shr al, 1
    and al, 01h
    call print_num
    PRT str_nl
    pop dx
    pop ax
    ret
print_exec_state ENDP

; Display all VM register values
print_registers PROC
    push ax
    push dx
    mov saved_acc, ax           ; preserve ACC across PRT
    PRT str_reg_hdr
    PRT str_reg_acc
    mov ax, saved_acc
    call print_num
    PRT str_reg_pc
    mov ax, si
    call print_num
    PRT str_reg_sp
    xor ax, ax
    mov al, vm_sp
    call print_num
    PRT str_exe_zf
    xor ax, ax
    mov al, vm_flags
    and al, 01h
    call print_num
    PRT str_exe_sf
    xor ax, ax
    mov al, vm_flags
    shr al, 1
    and al, 01h
    call print_num
    PRT str_reg_tr
    cmp trace_mode, 1
    je  regs_trace_on
    PRT str_reg_off
    jmp regs_done
regs_trace_on:
    PRT str_reg_on
regs_done:
    PRT str_nl
    pop dx
    pop ax
    ret
print_registers ENDP

; Dump vm_memory[0..15] in hex
print_memory PROC
    push ax
    push bx
    push cx
    push dx
    PRT str_mem_hdr
    xor bx, bx
    mov cx, 16
mem_loop:
    PRT str_mem_row
    mov ax, bx
    call print_hex_byte
    PRT str_mem_sep
    xor ax, ax
    mov al, vm_memory[bx]
    call print_hex_byte
    PRT str_mem_col
    inc bx
    loop mem_loop
    PRT str_nl
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_memory ENDP

; Show software call stack contents
print_stack PROC
    push ax
    push bx
    push dx
    PRT str_stk_hdr
    PRT str_stk_top
    xor ax, ax
    mov al, vm_sp
    call print_num
    cmp vm_sp, 18
    jae stack_is_empty
    xor bx, bx
    mov bl, vm_sp
stack_show_entry:
    cmp bx, 18
    jae stack_done
    PRT str_stk_entr
    xor ax, ax
    mov al, vm_stack[bx]
    inc bx
    mov ah, vm_stack[bx]
    shr ax, 1                   ; byte offset -> instruction #
    call print_num
    inc bx
    cmp bx, 18
    jb  stack_show_entry
    jmp stack_done
stack_is_empty:
    PRT str_stk_emp
stack_done:
    PRT str_nl
    pop dx
    pop bx
    pop ax
    ret
print_stack ENDP

; Print final summary when HALT runs
print_end_summary PROC
    push ax
    push bx
    push cx
    push dx
    mov saved_acc, ax           ; preserve ACC for final display
    PRT str_sum_hdr
    PRT str_sum_cnt
    mov ax, instr_count
    call print_num
    PRT str_sum_acc
    mov ax, saved_acc
    call print_num
    PRT str_sum_pc
    mov ax, si
    call print_num
    PRT str_sum_mem
    xor bx, bx
    mov cx, 4
sum_loop:
    xor ax, ax
    mov al, vm_memory[bx]
    call print_hex_byte
    PRT str_mem_col
    inc bx
    loop sum_loop
    PRT str_sum_end
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_end_summary ENDP

; ============================================================
;  print_num - print AX as unsigned decimal
; ============================================================
print_num PROC
    push ax
    push bx
    push cx
    push dx
    xor cx, cx
    mov bx, 10
    test ax, ax
    jnz  num_divide
    ; Special case: AX = 0
    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp num_done
num_divide:
    test ax, ax
    jz   num_output
    xor dx, dx
    div bx                      ; AX = AX/10, DX = AX%10
    push dx                     ; digits pushed in reverse
    inc cx
    jmp num_divide
num_output:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop num_output
num_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_num ENDP

; ============================================================
;  print_hex_byte - print AL as "XXh"
; ============================================================
print_hex_byte PROC
    push ax
    push bx
    push cx
    push dx
    mov bx, ax
    and bx, 0FFh
    mov al, bl
    shr al, 4
    call print_nibble
    mov al, bl
    and al, 0Fh
    call print_nibble
    PRT str_0h
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_nibble:
    cmp al, 9
    ja  hex_alpha
    add al, '0'
    jmp hex_print
hex_alpha:
    add al, 'A' - 10
hex_print:
    mov dl, al
    mov ah, 02h
    int 21h
    ret
print_hex_byte ENDP

; ============================================================
;  print_type - AL = type byte, prints type name string
; ============================================================
print_type PROC
    push ax
    push dx
    cmp al, 0
    je  type_data
    cmp al, 1
    je  type_arith
    cmp al, 2
    je  type_ctrl
    cmp al, 3
    je  type_io
    mov dx, OFFSET str_type4
    jmp type_print
type_data:
    mov dx, OFFSET str_type0
    jmp type_print
type_arith:
    mov dx, OFFSET str_type1
    jmp type_print
type_ctrl:
    mov dx, OFFSET str_type2
    jmp type_print
type_io:
    mov dx, OFFSET str_type3
type_print:
    mov ah, 09h
    int 21h
    pop dx
    pop ax
    ret
print_type ENDP

; ============================================================
;  print_operand_meaning - AL = opcode, prints operand role
; ============================================================
print_operand_meaning PROC
    push ax
    push dx
    cmp al, 07h                 ; JMP
    je  operand_target
    cmp al, 08h                 ; JZ
    je  operand_target
    cmp al, 09h                 ; JNZ
    je  operand_target
    cmp al, 0Bh                 ; CALL
    je  operand_target
    cmp al, 02h                 ; STORE
    je  operand_addr
    cmp al, 03h                 ; FETCH
    je  operand_addr
    cmp al, 00h                 ; HALT
    je  operand_none
    cmp al, 0Ch                 ; RET
    je  operand_none
    cmp al, 0Ah                 ; PRINT
    je  operand_none
    ; Default: immediate value
    mov dx, OFFSET str_dec_imm
    jmp operand_print
operand_target:
    mov dx, OFFSET str_dec_tgt
    jmp operand_print
operand_addr:
    mov dx, OFFSET str_dec_addr
    jmp operand_print
operand_none:
    mov dx, OFFSET str_dec_none
operand_print:
    mov ah, 09h
    int 21h
    pop dx
    pop ax
    ret
print_operand_meaning ENDP

; ============================================================
;  print_will_desc - find current_opcode in IDT, print desc[index]
; ============================================================
print_will_desc PROC
    push ax
    push bx
    push cx
    push dx
    mov cx, IDT_SIZE
    mov bx, OFFSET idt
    xor dx, dx                  ; DX = index counter
desc_search:
    mov al, [bx]
    cmp al, current_opcode
    je  desc_found
    add bx, IDT_ENTRY_SIZE
    inc dx
    loop desc_search
    jmp desc_done
desc_found:
    shl dx, 1                   ; index*2 (DW entries)
    mov bx, OFFSET desc_table
    add bx, dx
    mov dx, [bx]
    mov ah, 09h
    int 21h
desc_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_will_desc ENDP

; ============================================================
;  print_listing - print loaded program as a table
; ============================================================
print_listing PROC
    push ax
    push bx
    push cx
    push dx
    PRT str_list_hdr
    xor bx, bx                  ; BX = byte offset
    xor cx, cx                  ; CX = instruction number
    mov al, prog_len
    xor ah, ah
list_loop:
    push ax
    PRT str_list_row
    mov ax, cx
    call print_num
    PRT str_list_sep

    ; Print opcode byte (hex)
    push bx
    mov ax, prog_base
    add ax, bx
    mov bx, ax
    mov al, [bx]
    xor ah, ah
    call print_hex_byte
    PRT str_list_sep

    ; Print operand byte (hex)
    inc bx
    mov al, [bx]
    xor ah, ah
    call print_hex_byte
    pop bx

    PRT str_list_sep
    PRT str_nl
    add bx, 2
    inc cx
    pop ax
    dec ax
    jnz list_loop
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_listing ENDP

; ============================================================
;  END OF PROGRAM
; ============================================================
end start

