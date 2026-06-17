; userlib/win64/atomic.asm
; Windows x64 - <atomic>-style integer atomics for ASM code
default rel

; Fast NASM macros for ASM callers. These avoid function-call overhead.
%macro ATOMIC_LOAD64_MEM 2
    mov %1, [%2]
%endmacro
%macro ATOMIC_STORE64_MEM 2
    mov [%1], %2
%endmacro
%macro ATOMIC_FETCH_ADD64_MEM 3
    mov %1, %3
    lock xadd [%2], %1
%endmacro
%macro ATOMIC_INC64_MEM 2
    mov %1, 1
    lock xadd [%2], %1
    inc %1
%endmacro
%macro ATOMIC_DEC64_MEM 2
    mov %1, -1
    lock xadd [%2], %1
    dec %1
%endmacro
%macro ATOMIC_CAS64_MEM 5
    mov rax, %3
    lock cmpxchg [%2], %4
    sete %5
    movzx %1, %5
%endmacro
%macro ATOMIC_PAUSE 0
    pause
%endmacro


%macro ATOMIC_ADD64_MEM 2
    lock add qword [%1], %2
%endmacro
%macro ATOMIC_SUB64_MEM 2
    lock sub qword [%1], %2
%endmacro
%macro ATOMIC_ADD32_MEM 2
    lock add dword [%1], %2
%endmacro
%macro ATOMIC_SUB32_MEM 2
    lock sub dword [%1], %2
%endmacro
section .text

; atomic_load64(ptr) -> rax
global atomic_load64
atomic_load64:
    mov rax, [rcx]
    ret

; atomic_store64(ptr, value)
global atomic_store64
atomic_store64:
    mov [rcx], rdx
    ret

; atomic_exchange64(ptr, value) -> old
global atomic_exchange64
atomic_exchange64:
    mov rax, rdx
    xchg [rcx], rax
    ret

; atomic_fetch_add64(ptr, value) -> old
global atomic_fetch_add64
atomic_fetch_add64:
    mov rax, rdx
    lock xadd [rcx], rax
    ret

; atomic_fetch_sub64(ptr, value) -> old
global atomic_fetch_sub64
atomic_fetch_sub64:
    mov rax, rdx
    neg rax
    lock xadd [rcx], rax
    ret

; atomic_compare_exchange64(ptr, expected_ptr, desired) -> eax 1 success, 0 failure
; On failure, *expected_ptr receives the actual value.
global atomic_compare_exchange64
atomic_compare_exchange64:
    mov rax, [rdx]
    lock cmpxchg [rcx], r8
    jne .fail
    mov eax, 1
    ret
.fail:
    mov [rdx], rax
    xor eax, eax
    ret

; atomic_load32(ptr) -> eax
global atomic_load32
atomic_load32:
    mov eax, [rcx]
    ret

; atomic_store32(ptr, value)
global atomic_store32
atomic_store32:
    mov [rcx], edx
    ret

; atomic_exchange32(ptr, value) -> old
global atomic_exchange32
atomic_exchange32:
    mov eax, edx
    xchg [rcx], eax
    ret

; atomic_fetch_add32(ptr, value) -> old
global atomic_fetch_add32
atomic_fetch_add32:
    mov eax, edx
    lock xadd [rcx], eax
    ret

; atomic_compare_exchange32(ptr, expected_ptr, desired) -> eax 1 success, 0 failure
global atomic_compare_exchange32
atomic_compare_exchange32:
    mov eax, [rdx]
    lock cmpxchg [rcx], r8d
    jne .fail
    mov eax, 1
    ret
.fail:
    mov [rdx], eax
    xor eax, eax
    ret

; atomic_thread_fence_seq_cst()
global atomic_thread_fence_seq_cst
atomic_thread_fence_seq_cst:
    mfence
    ret

; atomic_pause() - spin-wait hint
global atomic_pause
atomic_pause:
    pause
    ret
; atomic_fetch_or64(ptr, value) -> old
global atomic_fetch_or64
atomic_fetch_or64:
.retry:
    mov rax, [rcx]
    mov r9, rax
    or r9, rdx
    lock cmpxchg [rcx], r9
    jne .retry
    ret

; atomic_fetch_and64(ptr, value) -> old
global atomic_fetch_and64
atomic_fetch_and64:
.retry:
    mov rax, [rcx]
    mov r9, rax
    and r9, rdx
    lock cmpxchg [rcx], r9
    jne .retry
    ret

; atomic_fetch_xor64(ptr, value) -> old
global atomic_fetch_xor64
atomic_fetch_xor64:
.retry:
    mov rax, [rcx]
    mov r9, rax
    xor r9, rdx
    lock cmpxchg [rcx], r9
    jne .retry
    ret

; atomic_inc64(ptr) -> new value
global atomic_inc64
atomic_inc64:
    mov eax, 1
    lock xadd [rcx], rax
    inc rax
    ret

; atomic_dec64(ptr) -> new value
global atomic_dec64
atomic_dec64:
    mov rax, -1
    lock xadd [rcx], rax
    dec rax
    ret

; atomic_fetch_or32(ptr, value) -> old
global atomic_fetch_or32
atomic_fetch_or32:
.retry:
    mov eax, [rcx]
    mov r9d, eax
    or r9d, edx
    lock cmpxchg [rcx], r9d
    jne .retry
    ret

; atomic_fetch_and32(ptr, value) -> old
global atomic_fetch_and32
atomic_fetch_and32:
.retry:
    mov eax, [rcx]
    mov r9d, eax
    and r9d, edx
    lock cmpxchg [rcx], r9d
    jne .retry
    ret

; atomic_fetch_xor32(ptr, value) -> old
global atomic_fetch_xor32
atomic_fetch_xor32:
.retry:
    mov eax, [rcx]
    mov r9d, eax
    xor r9d, edx
    lock cmpxchg [rcx], r9d
    jne .retry
    ret

; atomic_inc32(ptr) -> new value
global atomic_inc32
atomic_inc32:
    mov eax, 1
    lock xadd [rcx], eax
    inc eax
    ret

; atomic_dec32(ptr) -> new value
global atomic_dec32
atomic_dec32:
    mov eax, -1
    lock xadd [rcx], eax
    dec eax
    ret
; atomic_add64(ptr, value) -> void, fastest when old value is not needed
global atomic_add64
atomic_add64:
    lock add [rcx], rdx
    ret

; atomic_sub64(ptr, value) -> void
global atomic_sub64
atomic_sub64:
    lock sub [rcx], rdx
    ret

; atomic_add32(ptr, value) -> void
global atomic_add32
atomic_add32:
    lock add [rcx], edx
    ret

; atomic_sub32(ptr, value) -> void
global atomic_sub32
atomic_sub32:
    lock sub [rcx], edx
    ret