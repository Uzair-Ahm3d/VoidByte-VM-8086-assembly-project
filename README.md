# VoidByte VM

An interactive 8086 CPU simulator written entirely in assembly language. VoidByte VM is a tiny virtual machine running inside a real 8086. It executes its own custom 14 instruction bytecode and lets you step through fetch, decode, and execute one keypress at a time, turning the idea of "how a CPU works" into something you can actually watch.

## Features

- **14-instruction ISA** with arithmetic, memory, control flow, and subroutine support
- **Step by step execution**  press F for Fetch, D for Decode, E for Execute, or A for a full cycle
- **Live inspection** of registers, memory, and the software call stack
- **Trace mode** showing before and after state on every instruction
- **Four demo programs** covering arithmetic, memory addressing, loops, and subroutines
- **User injected starting value**  same program behaves differently depending on input
- **Jump table dispatch** for opcodes
- **Self contained software stack** for CALL/RET

## The 14 opcodes

| Hex | Name   | Action |
|-----|------  |--------|
| 00 | HALT    | Stop the VM |
| 01 | LOAD n  | ACC = n |
| 02 | STORE n | MEM[n] = ACC |
| 03 | FETCH n | ACC = MEM[n] |
| 04 | ADD n   | ACC = ACC + n |
| 05 | SUB n   | ACC = ACC − n |
| 06 | MUL n   | ACC = ACC × n |
| 07 | JMP n   | PC = instruction n |
| 08 | JZ n    | PC = n if Zero Flag set |
| 09 | JNZ n   | PC = n if Zero Flag clear |
| 0A | PRINT   | Output ACC |
| 0B | CALL n  | Push return addr, jump to n |
| 0C | RET     | Pop return addr, restore PC |
| 0D | CMP n   | Compare ACC with n (flags only) |

## Running

1. Pick a demo program (1–4) or press Q to quit
2. Enter a starting value (1–9) — gets injected into the program's first LOAD
3. Use the menu keys to step through execution:

| Key | Action |
|-----|--------|
| F   | Fetch next instruction |
| D   | Decode it |
| E   | Execute it |
| A   | All three at once |
| R   | Show registers |
| M   | Show memory |
| S   | Show call stack |
| T   | Toggle trace mode |
| X   | Reset |
| Q   | Back to program menu |

## Module structure

The project is divided into three modules:

### `voidbyte_module1_core.asm`  VM Core & Instruction Set
The CPU itself. VM state, jump table, the four demo programs, fetch/decode/execute stages, all 14 instruction handlers, reset and flag update helpers.

### `voidbyte_module2_ui.asm` — UI, Menus & Input Handling
The user facing layer. File header, PRT macro, menu strings, entry point, program selection, value injection, main key dispatch.

### `voidbyte_module3_display.asm`  Decoder, Display & Formatting
The output layer. IDT, will-do descriptions, all stage display strings, register/memory/stack dumps, formatting helpers.

## Architecture

Two CPUs run together: the real 8086 runs the assembly, and the assembly simulates a VM that runs bytecode. The mapping:

| Virtual | Physical |
|---------|----------|
| ACC    | AX register |
| PC     | SI register |
| SP     | `vm_sp` variable |
| FLAGS  | `vm_flags` variable (bit 0 = ZF, bit 1 = SF) |
| Memory | `vm_memory[256]` array |
| Stack  | `vm_stack[20]` array |

Every instruction is 2 bytes (opcode + operand).
