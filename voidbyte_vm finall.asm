.model small
.stack 200h

; PRT macro: print a $-terminated string (note: clobbers AH and DX)
PRT MACRO s
    mov ah, 09h
    mov dx, OFFSET s
    int 21h
ENDM

.data

; --- VM state ---
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
user_value      DB 5            ; user-injected starting value
vm_acc          DW 0            ; canonical ACC storage (survives menu/PRT clobber)
tmp_word        DW 0            ; scratch slot for handler_ret return address
vm_memory       DB 256 DUP(0)
vm_stack        DB 20 DUP(0)
prog_base       DW OFFSET prog1
prog_len        DB prog1_len

; --- Jump table: dispatch via BX = opcode*2 ---
jump_table  DW OFFSET handler_halt,  OFFSET handler_load
            DW OFFSET handler_store, OFFSET handler_fetch
            DW OFFSET handler_add,   OFFSET handler_sub
            DW OFFSET handler_mul,   OFFSET handler_jmp
            DW OFFSET handler_jz,    OFFSET handler_jnz
            DW OFFSET handler_print, OFFSET handler_call
            DW OFFSET handler_ret,   OFFSET handler_cmp

; --- IDT: opcode(1) + mnemonic(6) + type(1)   type:0=data 1=arith 2=ctrl 3=io 4=sys
idt:
  DB 01h,"LOAD  ",0,  04h,"ADD   ",1,  05h,"SUB   ",1,  06h,"MUL   ",1
  DB 02h,"STORE ",0,  03h,"FETCH ",0,  07h,"JMP   ",2,  08h,"JZ    ",2
  DB 09h,"JNZ   ",2,  0Dh,"CMP   ",2,  0Bh,"CALL  ",2,  0Ch,"RET   ",2
  DB 0Ah,"PRINT ",3,  00h,"HALT  ",4
IDT_SIZE EQU 14
IDT_ENTRY_SIZE EQU 8

; --- Demo programs (each instruction = opcode byte, operand byte) ---
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

; --- Strings (DOS int 21h/AH=09h, terminated by '$') ---
str_cls       DB 27,"[2J",27,"[H$"
str_border    DB "============================================$"
str_title1    DB "         VoidByte VM  v2.0                 $"
str_title2    DB "    Interactive CPU Simulator (Emu8086)     $"
str_border2   DB "--------------------------------------------$"
str_nl        DB 13,10,"$"
str_arrow     DB " -> $"
str_0h        DB "h$"

str_sel_hdr   DB 13,10,"  SELECT PROGRAM:",13,10,"$"
str_prog1     DB "  [1] Arithmetic - LOAD ADD SUB MUL PRINT",13,10,"$"
str_prog2     DB "  [2] Memory     - LOAD STORE FETCH ADD",13,10,"$"
str_prog3     DB "  [3] Loop       - SUB JNZ countdown",13,10,"$"
str_prog4     DB "  [4] Subroutine - CALL RET demo",13,10,"$"
str_prog_q    DB "  [Q] Quit",13,10,"$"
str_sel_prompt DB 13,10,"  Choice (1-4 or Q): $"
str_goodbye   DB 13,10,"  Goodbye!",13,10,"$"

str_val_prompt DB 13,10,"  Enter starting value (1-9): $"
str_val_bad    DB 13,10,"  [!] Invalid. Enter 1-9: $"

str_list_hdr  DB 13,10,"  PROGRAM LISTING:",13,10
              DB "  Instr  Opcode  Operand",13,10,"$"
str_list_row  DB "  #$"
str_list_sep  DB "     $"

str_menu_hdr  DB 13,10,"  CONTROLS:",13,10,"$"
str_menu_f    DB "  [F] Fetch    [D] Decode    [E] Execute$"
str_menu_a    DB 13,10,"  [A] Auto     [R] Regs      [M] Memory$"
str_menu_s    DB 13,10,"  [S] Stack    [T] Trace     [X] Reset$"
str_menu_q    DB 13,10,"  [Q] Quit$"
str_prompt    DB 13,10,13,10,"  > $"

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

str_trace_on  DB 13,10,"  [Trace ON]",13,10,"$"
str_trace_off DB 13,10,"  [Trace OFF]",13,10,"$"
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
str_any_key   DB 13,10,"  [Press any key...]",13,10,"$"
str_fetch_nd  DB 13,10,"  [!] Press F first.",13,10,"$"
str_already_h DB 13,10,"  [!] HALTed. Press X to reset.",13,10,"$"

.code

start:
    mov ax, @data
    mov ds, ax
    PRT str_cls
    call print_banner
    jmp program_select_loop

; ============================================================
;  Program selection
; ============================================================
program_select_loop:
    call print_banner
    call print_program_menu
    mov ah, 07h
    int 21h
    cmp al, '1'
    je  load_prog1
    cmp al, '2'
    je  load_prog2
    cmp al, '3'
    je  load_prog3
    cmp al, '4'
    je  load_prog4
    cmp al, 'Q'
    je  quit_program
    cmp al, 'q'
    je  quit_program
    jmp program_select_loop

quit_program:
    PRT str_goodbye
    mov ax, 4C00h
    int 21h

load_prog1:
    mov prog_base, OFFSET prog1
    mov prog_len, prog1_len
    jmp ask_user_value
load_prog2:
    mov prog_base, OFFSET prog2
    mov prog_len, prog2_len
    jmp ask_user_value
load_prog3:
    mov prog_base, OFFSET prog3
    mov prog_len, prog3_len
    jmp ask_user_value
load_prog4:
    mov prog_base, OFFSET prog4
    mov prog_len, prog4_len
    jmp inject_and_start

ask_user_value:
    PRT str_val_prompt
get_value_loop:
    mov ah, 07h
    int 21h
    cmp al, '1'
    jb  bad_value
    cmp al, '9'
    ja  bad_value
    sub al, '0'
    mov user_value, al
    jmp inject_and_start
bad_value:
    PRT str_val_bad
    jmp get_value_loop

; Inject user_value into the operand of the program's first LOAD
inject_and_start:
    mov bx, prog_base
    inc bx
    mov al, user_value
    mov [bx], al
    call reset_vm
    call print_listing
    jmp execution_menu_loop

; ============================================================
;  Main execution menu
; ============================================================
execution_menu_loop:
    call print_exec_menu
    mov ah, 07h
    int 21h
    cmp al, 'a'
    jb  check_key
    cmp al, 'z'
    ja  check_key
    sub al, 20h                 ; lowercase -> uppercase
check_key:
    cmp al, 'F'
    je  do_fetch
    cmp al, 'D'
    je  do_decode
    cmp al, 'E'
    je  do_execute
    cmp al, 'A'
    je  do_auto
    cmp al, 'R'
    je  do_regs
    cmp al, 'M'
    je  do_mem
    cmp al, 'S'
    je  do_stack
    cmp al, 'T'
    je  do_trace_toggle
    cmp al, 'X'
    je  do_reset
    cmp al, 'Q'
    je  do_quit
    jmp execution_menu_loop

do_fetch:
    cmp vm_halted, 1
    je  exec_halted_msg
    call fetch_stage
    jmp exec_wait_key
do_decode:
    cmp fetch_done, 0
    je  exec_no_fetch_msg
    call decode_stage
    jmp exec_wait_key
do_execute:
    cmp fetch_done, 0
    je  exec_no_fetch_msg
    cmp vm_halted, 1
    je  exec_halted_msg
    call execute_stage
    jmp exec_wait_key
do_auto:
    cmp vm_halted, 1
    je  exec_halted_msg
    call fetch_stage
    call decode_stage
    call execute_stage
    jmp exec_wait_key
do_regs:
    call print_registers
    jmp exec_wait_key
do_mem:
    call print_memory
    jmp exec_wait_key
do_stack:
    call print_stack
    jmp exec_wait_key
do_trace_toggle:
    xor trace_mode, 1
    cmp trace_mode, 1
    je  trace_now_on
    PRT str_trace_off
    jmp exec_wait_key
trace_now_on:
    PRT str_trace_on
    jmp exec_wait_key
do_reset:
    call reset_vm
    call print_listing
    jmp execution_menu_loop
do_quit:
    jmp program_select_loop
exec_halted_msg:
    PRT str_already_h
    jmp exec_wait_key
exec_no_fetch_msg:
    PRT str_fetch_nd
    jmp exec_wait_key
exec_wait_key:
    PRT str_any_key
    mov ah, 07h
    int 21h
    jmp execution_menu_loop

; ============================================================
;  fetch_stage - read opcode+operand from bytecode[PC]
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

; ============================================================
;  decode_stage - look up opcode in IDT, print info
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

; ============================================================
;  execute_stage - jump-table dispatch
; ============================================================
execute_stage PROC
    push bx
    push cx
    push dx
    PRT str_exe_hdr
    mov ax, vm_acc              ; load ACC from canonical storage
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
    mov vm_acc, ax              ; save new ACC to canonical storage
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
;  Instruction handlers - all use AX=ACC, SI=PC
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
    mov vm_acc, ax           ; stash before PRT-style calls below
    call print_num
    mov ax, vm_acc
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
    mov vm_acc, ax
    call print_num
    mov ax, vm_acc
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
    mov vm_acc, ax
    call print_num
    mov ax, vm_acc
    call update_flags
    add si, 2
    jmp exec_after_handler

; STORE: vm_memory[operand] = ACC
handler_store:
    push bx
    mov vm_acc, ax           ; preserve ACC across PRT
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
    mov ax, vm_acc           ; restore ACC for the write + print
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
    mov vm_acc, ax           ; preserve ACC across PRT
    PRT str_prt_out
    mov ax, vm_acc           ; restore before print_num
    call print_num
    PRT str_nl
    mov ax, vm_acc           ; restore for trace display
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
    mov tmp_word, ax            ; tmp_word = return address

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
    mov ax, tmp_word
    shr ax, 1                   ; byte offset -> instruction #
    call print_num

    mov si, tmp_word            ; restore PC
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

; ============================================================
;  Display procedures
; ============================================================

; Print trace info after each execute: cycle#, ACC/PC before->after, ZF, SF
print_exec_state PROC
    push ax
    push dx
    PRT str_cycle_hdr
    mov ax, instr_count
    call print_num
    PRT str_cycle_of
    PRT str_exe_bef
    mov ax, acc_before
    call print_num
    PRT str_arrow
    mov ax, vm_acc              ; ACC after (from canonical storage)
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
    PRT str_reg_hdr
    PRT str_reg_acc
    mov ax, vm_acc              ; read canonical ACC
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
    PRT str_sum_hdr
    PRT str_sum_cnt
    mov ax, instr_count
    call print_num
    PRT str_sum_acc
    mov ax, vm_acc              ; read canonical ACC
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
;  reset_vm - clear VM state, re-inject user_value
; ============================================================
reset_vm PROC
    push bx
    push cx
    xor si, si                  ; PC = 0
    mov vm_flags, 0
    mov vm_sp, 18
    mov instr_count, 0
    mov fetch_done, 0
    mov vm_halted, 0
    mov vm_acc, 0               ; ACC = 0 (canonical storage)

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
    xor ax, ax                  ; ACC = 0 (do NOT preserve caller's AX)
    ret
reset_vm ENDP

; ============================================================
;  update_flags - set ZF/SF in vm_flags from AX
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
;  Banner and menu printers
; ============================================================
print_banner PROC
    push dx
    PRT str_border
    PRT str_nl
    PRT str_title1
    PRT str_nl
    PRT str_title2
    PRT str_nl
    PRT str_border
    PRT str_nl
    pop dx
    ret
print_banner ENDP

print_program_menu PROC
    push dx
    PRT str_sel_hdr
    PRT str_prog1
    PRT str_prog2
    PRT str_prog3
    PRT str_prog4
    PRT str_prog_q
    PRT str_sel_prompt
    pop dx
    ret
print_program_menu ENDP

print_exec_menu PROC
    push dx
    PRT str_border2
    PRT str_menu_hdr
    PRT str_menu_f
    PRT str_menu_a
    PRT str_menu_s
    PRT str_menu_q
    PRT str_prompt
    pop dx
    ret
print_exec_menu ENDP

end start
