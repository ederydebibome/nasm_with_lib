; thread.asm - <thread>-style pthread helpers, SysV x86-64 ABI
default rel
extern malloc
extern free
extern pthread_create
extern pthread_join
extern pthread_detach
extern pthread_exit
extern sched_yield
extern pthread_self
extern sysconf
PTHREAD_T_SIZE equ 8
_SC_NPROCESSORS_ONLN equ 84
section .text
global thread_create, thread_join, thread_detach, thread_exit, thread_yield, this_thread_id, hardware_concurrency
thread_create:
    push rbx
    push r12
    push r13
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov edi, PTHREAD_T_SIZE
    call malloc
    test rax, rax
    jz .done
    mov r13, rax
    mov rdi, rax
    xor esi, esi
    mov rdx, rbx
    mov rcx, r12
    call pthread_create
    test eax, eax
    jnz .fail
    mov rax, r13
.done: add rsp, 8
    pop r13
    pop r12
    pop rbx
    ret
.fail:
    mov rdi, r13
    call free
    xor eax, eax
    add rsp, 8
    pop r13
    pop r12
    pop rbx
    ret
thread_join:
    push rbx
    sub rsp, 8
    mov rbx, rdi
    mov rdi, [rdi]
    xor esi, esi
    call pthread_join
    test eax, eax
    jnz .fail
    mov rdi, rbx
    call free
    xor eax, eax
    add rsp, 8
    pop rbx
    ret
.fail: or rax, -1
    add rsp, 8
    pop rbx
    ret
thread_detach:
    push rbx
    sub rsp, 8
    mov rbx, rdi
    mov rdi, [rdi]
    call pthread_detach
    mov rdi, rbx
    call free
    xor eax, eax
    add rsp, 8
    pop rbx
    ret
thread_exit:
    call pthread_exit
    ret
thread_yield:
    sub rsp, 8
    call sched_yield
    xor eax, eax
    add rsp, 8
    ret
this_thread_id:
    sub rsp, 8
    call pthread_self
    add rsp, 8
    ret
hardware_concurrency:
    sub rsp, 8
    mov edi, _SC_NPROCESSORS_ONLN
    call sysconf
    test rax, rax
    jg .ok
    mov eax, 1
.ok: add rsp, 8
    ret