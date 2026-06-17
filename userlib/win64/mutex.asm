; userlib/win64/mutex.asm
; Windows x64 - <mutex>-style helpers optimized for uncontended speed.
; Uses SRWLOCK exclusive mode: smaller and faster than kernel mutex / CriticalSection wrapper.
default rel

extern malloc
extern free
extern InitializeSRWLock
extern AcquireSRWLockExclusive
extern ReleaseSRWLockExclusive
extern TryAcquireSRWLockExclusive

SRWLOCK_SIZE equ 8

section .text

; mutex_create() -> pointer to SRWLOCK or 0
global mutex_create
mutex_create:
    sub rsp, 40
    mov ecx, SRWLOCK_SIZE
    call malloc
    test rax, rax
    jz .done
    mov [rsp + 32], rax
    mov rcx, rax
    call InitializeSRWLock
    mov rax, [rsp + 32]
.done:
    add rsp, 40
    ret

; mutex_lock(mutex) -> 0 success
global mutex_lock
mutex_lock:
    sub rsp, 40
    call AcquireSRWLockExclusive
    xor eax, eax
    add rsp, 40
    ret

; mutex_unlock(mutex) -> 0 success
global mutex_unlock
mutex_unlock:
    sub rsp, 40
    call ReleaseSRWLockExclusive
    xor eax, eax
    add rsp, 40
    ret

; mutex_destroy(mutex) -> 0 success, -1 on null
global mutex_destroy
mutex_destroy:
    test rcx, rcx
    jz .fail
    sub rsp, 40
    call free
    xor eax, eax
    add rsp, 40
    ret
.fail:
    or rax, -1
    ret
; mutex_try_lock(mutex) -> 1 if locked, 0 if busy
global mutex_try_lock
mutex_try_lock:
    sub rsp, 40
    call TryAcquireSRWLockExclusive
    add rsp, 40
    ret
; spin_mutex_*: ultra-light user-space mutex for very short uncontended regions.
; Storage: qword initialized to 0. Faster than kernel/SRW wrappers, but spins under contention.
global spin_mutex_init
spin_mutex_init:
    mov qword [rcx], 0
    xor eax, eax
    ret

global spin_mutex_try_lock
spin_mutex_try_lock:
    mov eax, 1
    xchg eax, [rcx]
    test eax, eax
    setz al
    movzx eax, al
    ret

global spin_mutex_lock
spin_mutex_lock:
.acquire:
    mov eax, 1
    xchg eax, [rcx]
    test eax, eax
    jz .ok
.wait:
    pause
    cmp dword [rcx], 0
    jne .wait
    jmp .acquire
.ok:
    xor eax, eax
    ret

global spin_mutex_unlock
spin_mutex_unlock:
    mov dword [rcx], 0
    xor eax, eax
    ret

global spin_mutex_destroy
spin_mutex_destroy:
    xor eax, eax
    ret

%macro SPIN_MUTEX_LOCK_MEM 1
%%acquire:
    mov eax, 1
    xchg eax, [%1]
    test eax, eax
    jz %%ok
%%wait:
    pause
    cmp dword [%1], 0
    jne %%wait
    jmp %%acquire
%%ok:
%endmacro

%macro SPIN_MUTEX_UNLOCK_MEM 1
    mov dword [%1], 0
%endmacro