; mutex.asm - <mutex>-style pthread mutex wrapper, SysV x86-64 ABI
default rel
extern malloc
extern free
extern pthread_mutex_init
extern pthread_mutex_lock
extern pthread_mutex_unlock
extern pthread_mutex_destroy
PTHREAD_MUTEX_T_SIZE equ 64
section .text
global mutex_create, mutex_lock, mutex_unlock, mutex_destroy
mutex_create:
    push rbx
    sub rsp, 8
    mov edi, PTHREAD_MUTEX_T_SIZE
    call malloc
    test rax, rax
    jz .done
    mov rbx, rax
    mov rdi, rax
    xor esi, esi
    call pthread_mutex_init
    test eax, eax
    jnz .fail
    mov rax, rbx
.done: add rsp, 8
    pop rbx
    ret
.fail:
    mov rdi, rbx
    call free
    xor eax, eax
    add rsp, 8
    pop rbx
    ret
mutex_lock:
    sub rsp, 8
    call pthread_mutex_lock
    neg eax
    sbb eax, eax
    add rsp, 8
    ret
mutex_unlock:
    sub rsp, 8
    call pthread_mutex_unlock
    neg eax
    sbb eax, eax
    add rsp, 8
    ret
mutex_destroy:
    push rbx
    test rdi, rdi
    jz .fail
    sub rsp, 8
    mov rbx, rdi
    call pthread_mutex_destroy
    mov rdi, rbx
    call free
    xor eax, eax
    add rsp, 8
    pop rbx
    ret
.fail: or rax, -1
    pop rbx
    ret