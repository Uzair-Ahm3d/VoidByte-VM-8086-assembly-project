.model small
.stack 200h

; PRT macro: print a $-terminated string (note: clobbers AH and DX)
PRT MACRO s
    mov ah, 09h
    mov dx, OFFSET s
    int 21h
ENDM

.data

str_cls       DB 27,"[2J",27,"[H$"
str_border    DB "============================================$"
str_title1    DB "         VoidByte VM  v2.0                 $"
str_title2    DB "    Interactive CPU Simulator (Emu8086)     $"
str_border2   DB "--------------------------------------------$"
str_nl        DB 13,10,"$"
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
str_menu_hdr  DB 13,10,"  CONTROLS:",13,10,"$"
str_menu_f    DB "  [F] Fetch    [D] Decode    [E] Execute$"
str_menu_a    DB 13,10,"  [A] Auto     [R] Regs      [M] Memory$"
str_menu_s    DB 13,10,"  [S] Stack    [T] Trace     [X] Reset$"
str_menu_q    DB 13,10,"  [Q] Quit$"
str_prompt    DB 13,10,13,10,"  > $"
str_trace_on  DB 13,10,"  [Trace ON]",13,10,"$"
str_trace_off DB 13,10,"  [Trace OFF]",13,10,"$"
str_any_key   DB 13,10,"  [Press any key...]",13,10,"$"
str_fetch_nd  DB 13,10,"  [!] Press F first.",13,10,"$"
str_already_h DB 13,10,"  [!] HALTed. Press X to reset.",13,10,"$"

.code

; ============================================================
;  Module 2 code: Entry point, menus, key dispatch
; ============================================================

start:
    mov ax, @data
    mov ds, ax
    PRT str_cls
    call print_banner
    jmp program_select_loop

; ----- Program selection -----
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

; ----- Banner and menu printers -----
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

