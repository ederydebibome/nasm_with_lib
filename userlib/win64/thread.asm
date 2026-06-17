; userlib/win64/thread.asm
; Windows x64 - <thread>-style helpers for ASM code
default rel

extern CreateThread
extern WaitForSingleObject
extern GetExitCodeThread
extern CloseHandle
extern ExitThread
extern Sleep
extern SwitchToThread
extern GetCurrentThreadId
extern GetActiveProcessorCount

INFINITE equ 0xFFFFFFFF
WAIT_OBJECT_0 equ 0

section .text

; thread_create(start, arg) -> handle or 0
global thread_create
thread_create:
    sub rsp, 56
    mov r8, rcx
    mov r9, rdx
    xor ecx, ecx
    xor edx, edx
    mov qword [rsp + 32], 0
    lea rax, [rsp + 48]
    mov [rsp + 40], rax
    call CreateThread
    add rsp, 56
    ret

; thread_join(handle, exit_code_ptr) -> 0 success, -1 failure
global thread_join
thread_join:
    sub rsp, 72
    mov [rsp + 40], rcx
    mov [rsp + 48], rdx
    mov rdx, INFINITE
    call WaitForSingleObject
    cmp eax, WAIT_OBJECT_0
    jne .fail
    mov rcx, [rsp + 40]
    lea rdx, [rsp + 56]
    call GetExitCodeThread
    test eax, eax
    jz .fail
    mov rdx, [rsp + 48]
    test rdx, rdx
    jz .close
    mov eax, [rsp + 56]
    mov [rdx], eax
.close:
    mov rcx, [rsp + 40]
    call CloseHandle
    xor eax, eax
    add rsp, 72
    ret
.fail:
    or rax, -1
    add rsp, 72
    ret

; thread_detach(handle) -> 0 success, -1 failure
global thread_detach
thread_detach:
    sub rsp, 40
    call CloseHandle
    test eax, eax
    jz .fail
    xor eax, eax
    add rsp, 40
    ret
.fail:
    or rax, -1
    add rsp, 40
    ret

; thread_exit(code)
global thread_exit
thread_exit:
    sub rsp, 40
    call ExitThread
    add rsp, 40
    ret

; thread_sleep(ms)
global thread_sleep
thread_sleep:
    sub rsp, 40
    call Sleep
    add rsp, 40
    ret

; thread_yield() -> nonzero if switched
global thread_yield
thread_yield:
    sub rsp, 40
    call SwitchToThread
    add rsp, 40
    ret

; this_thread_id() -> eax
global this_thread_id
this_thread_id:
    sub rsp, 40
    call GetCurrentThreadId
    add rsp, 40
    ret

; hardware_concurrency() -> eax logical processors
global hardware_concurrency
hardware_concurrency:
    sub rsp, 40
    mov ecx, 0FFFFh
    call GetActiveProcessorCount
    add rsp, 40
    ret