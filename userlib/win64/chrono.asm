; userlib/win64/chrono.asm
; Windows x64 - <chrono>-style timing helpers for ASM code
default rel

extern QueryPerformanceCounter
extern QueryPerformanceFrequency
extern GetTickCount64

section .data
_qpc_freq dq 0
_qpc_init db 0

section .text

; chrono_tick_ms() -> rax milliseconds since system start
global chrono_tick_ms
chrono_tick_ms:
    sub rsp, 40
    call GetTickCount64
    add rsp, 40
    ret

; chrono_counter() -> rax raw performance counter
global chrono_counter
chrono_counter:
    sub rsp, 40
    lea rcx, [rsp + 32]
    call QueryPerformanceCounter
    mov rax, [rsp + 32]
    add rsp, 40
    ret

; chrono_frequency() -> rax performance counter ticks per second
global chrono_frequency
chrono_frequency:
    cmp byte [_qpc_init], 0
    jne .cached
    sub rsp, 40
    lea rcx, [rsp + 32]
    call QueryPerformanceFrequency
    mov rax, [rsp + 32]
    mov [_qpc_freq], rax
    mov byte [_qpc_init], 1
    add rsp, 40
.cached:
    mov rax, [_qpc_freq]
    ret

; chrono_elapsed_ns(start_counter, end_counter) -> rax nanoseconds
global chrono_elapsed_ns
chrono_elapsed_ns:
    sub rdx, rcx
    mov r8, rdx
    call chrono_frequency
    mov rcx, rax
    mov rax, r8
    mov r8, 1000000000
    mul r8
    div rcx
    ret

; chrono_elapsed_us(start_counter, end_counter) -> rax microseconds
global chrono_elapsed_us
chrono_elapsed_us:
    sub rdx, rcx
    mov r8, rdx
    call chrono_frequency
    mov rcx, rax
    mov rax, r8
    mov r8, 1000000
    mul r8
    div rcx
    ret

; chrono_elapsed_ms(start_counter, end_counter) -> rax milliseconds
global chrono_elapsed_ms
chrono_elapsed_ms:
    sub rdx, rcx
    mov r8, rdx
    call chrono_frequency
    mov rcx, rax
    mov rax, r8
    mov r8, 1000
    mul r8
    div rcx
    ret
; chrono_elapsed_sec(start_counter, end_counter) -> rax seconds
global chrono_elapsed_sec
chrono_elapsed_sec:
    sub rsp, 40
    sub rdx, rcx
    mov [rsp + 32], rdx
    call chrono_frequency
    mov rcx, rax
    mov rax, [rsp + 32]
    xor edx, edx
    div rcx
    add rsp, 40
    ret

; chrono_now_ns() -> rax nanoseconds based on QPC
global chrono_now_ns
chrono_now_ns:
    sub rsp, 40
    call chrono_counter
    xor edx, edx
    mov rcx, 1000000000
    mul rcx
    mov [rsp + 32], rax
    call chrono_frequency
    mov rcx, rax
    mov rax, [rsp + 32]
    xor edx, edx
    div rcx
    add rsp, 40
    ret
; chrono_cycles() -> rax raw TSC cycles. Extremely fast, not wall-clock stable across all systems.
global chrono_cycles
chrono_cycles:
    rdtsc
    shl rdx, 32
    or rax, rdx
    ret

; chrono_cycles_ordered() -> rax serialized TSC cycles via RDTSCP
global chrono_cycles_ordered
chrono_cycles_ordered:
    rdtscp
    shl rdx, 32
    or rax, rdx
    ret

%macro CHRONO_RDTSC 1
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov %1, rax
%endmacro