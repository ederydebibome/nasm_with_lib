; atomic.asm - <atomic>-style integer atomics, SysV x86-64 ABI
default rel
section .text
global atomic_load64, atomic_store64, atomic_exchange64, atomic_fetch_add64, atomic_fetch_sub64, atomic_compare_exchange64
global atomic_load32, atomic_store32, atomic_exchange32, atomic_fetch_add32, atomic_compare_exchange32, atomic_thread_fence_seq_cst, atomic_pause
atomic_load64: mov rax, [rdi]
    ret
atomic_store64: mov [rdi], rsi
    ret
atomic_exchange64: mov rax, rsi
    xchg [rdi], rax
    ret
atomic_fetch_add64: mov rax, rsi
    lock xadd [rdi], rax
    ret
atomic_fetch_sub64: mov rax, rsi
    neg rax
    lock xadd [rdi], rax
    ret
atomic_compare_exchange64: mov rax, [rsi]
    lock cmpxchg [rdi], rdx
    jne .fail64
    mov eax, 1
    ret
.fail64: mov [rsi], rax
    xor eax, eax
    ret
atomic_load32: mov eax, [rdi]
    ret
atomic_store32: mov [rdi], esi
    ret
atomic_exchange32: mov eax, esi
    xchg [rdi], eax
    ret
atomic_fetch_add32: mov eax, esi
    lock xadd [rdi], eax
    ret
atomic_compare_exchange32: mov eax, [rsi]
    lock cmpxchg [rdi], edx
    jne .fail32
    mov eax, 1
    ret
.fail32: mov [rsi], eax
    xor eax, eax
    ret
atomic_thread_fence_seq_cst: mfence
    ret
atomic_pause: pause
    ret