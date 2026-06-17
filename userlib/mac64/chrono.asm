; chrono.asm - <chrono>-style helpers, macOS SysV x86-64 ABI
default rel
extern clock_gettime
CLOCK_MONOTONIC equ 6
section .text
global chrono_counter, chrono_frequency, chrono_elapsed_ns, chrono_elapsed_us, chrono_elapsed_ms, chrono_tick_ms
chrono_counter:
    sub rsp, 24
    mov edi, CLOCK_MONOTONIC
    mov rsi, rsp
    call clock_gettime
    mov rax, [rsp]
    mov rdx, 1000000000
    mul rdx
    add rax, [rsp+8]
    add rsp, 24
    ret
chrono_frequency:
    mov eax, 1000000000
    ret
chrono_elapsed_ns:
    mov rax, rsi
    sub rax, rdi
    ret
chrono_elapsed_us:
    mov rax, rsi
    sub rax, rdi
    xor edx, edx
    mov ecx, 1000
    div rcx
    ret
chrono_elapsed_ms:
    mov rax, rsi
    sub rax, rdi
    xor edx, edx
    mov ecx, 1000000
    div rcx
    ret
chrono_tick_ms:
    sub rsp, 8
    call chrono_counter
    xor edx, edx
    mov ecx, 1000000
    div rcx
    add rsp, 8
    ret