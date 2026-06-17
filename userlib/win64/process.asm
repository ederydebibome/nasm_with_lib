; userlib/win64/process.asm
; Windows x64 - Microsoft calling convention
default rel

extern ExitProcess
extern GetCurrentProcessId
extern CreateProcessA
extern WaitForSingleObject
extern GetExitCodeProcess
extern CloseHandle
extern Sleep
extern TerminateProcess

extern malloc
extern free
extern strlen
extern strcpy
extern memset

section .data
_process_info   times 64  db 0     ; PROCESS_INFORMATION
_startup_info   times 104 db 0     ; STARTUPINFO

section .text

;----------------------------------------------------------
; exit - terminate process
; rcx = exit code
;----------------------------------------------------------
global exit
exit:
    sub rsp, 40
    call ExitProcess
    add rsp, 40
    ret

;----------------------------------------------------------
; abort - terminate process with code 3
;----------------------------------------------------------
global abort
abort:
    sub rsp, 40
    mov ecx, 3
    call ExitProcess
    add rsp, 40
    ret

;----------------------------------------------------------
; getpid - get current process ID
; returns rax = PID
;----------------------------------------------------------
global getpid
getpid:
    sub rsp, 40
    call GetCurrentProcessId
    add rsp, 40
    ret

;----------------------------------------------------------
; sleep - suspend execution
; rcx = milliseconds
;----------------------------------------------------------
global sleep
sleep:
    sub rsp, 40
    call Sleep
    add rsp, 40
    ret

;----------------------------------------------------------
; system - execute shell command
; rcx = command string
; returns rax = exit code or -1 on failure
;----------------------------------------------------------
global system
system:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    sub rsp, 104

    test rcx, rcx
    jz  .fail
    mov r12, rcx

    ; zero structs
    lea rcx, [_startup_info]
    xor rdx, rdx
    mov r8, 104
    call memset

    lea rcx, [_process_info]
    xor rdx, rdx
    mov r8, 64
    call memset

    ; _startup_info.cb = 104
    mov dword [_startup_info], 104

    ; allocate "cmd.exe /C <command>"
    mov rcx, r12
    call strlen
    add rax, 12
    mov rcx, rax
    call malloc
    test rax, rax
    jz  .fail
    mov rbx, rax

    mov byte [rbx + 0],  'c'
    mov byte [rbx + 1],  'm'
    mov byte [rbx + 2],  'd'
    mov byte [rbx + 3],  '.'
    mov byte [rbx + 4],  'e'
    mov byte [rbx + 5],  'x'
    mov byte [rbx + 6],  'e'
    mov byte [rbx + 7],  ' '
    mov byte [rbx + 8],  '/'
    mov byte [rbx + 9],  'C'
    mov byte [rbx + 10], ' '
    mov byte [rbx + 11], 0

    lea rcx, [rbx + 11]
    mov rdx, r12
    call strcpy

    ; CreateProcessA
    xor rcx, rcx
    mov rdx, rbx
    xor r8, r8
    xor r9, r9
    mov qword [rsp + 32], 0
    mov qword [rsp + 40], 0
    mov qword [rsp + 48], 0
    mov qword [rsp + 56], 0
    lea rax, [_startup_info]
    mov [rsp + 64], rax
    lea rax, [_process_info]
    mov [rsp + 72], rax
    call CreateProcessA
    test rax, rax
    jz  .fail_free

    ; wait
    mov rcx, [_process_info]
    mov rdx, -1
    call WaitForSingleObject

    ; get exit code
    mov rcx, [_process_info]
    lea rdx, [rsp + 88]
    call GetExitCodeProcess
    mov r13d, [rsp + 88]

    ; close handles
    mov rcx, [_process_info]
    call CloseHandle
    mov rcx, [_process_info + 8]
    call CloseHandle

    mov rcx, rbx
    call free

    mov rax, r13
    add rsp, 104
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.fail_free:
    mov rcx, rbx
    call free
.fail:
    or rax, -1
    add rsp, 104
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

;----------------------------------------------------------
; spawnl - create child process
; rcx = mode (0=wait, 1=nowait)
; rdx = path to executable
; r8  = arg0, r9 = arg1, [rsp+32]... = rest, NULL terminated
; returns rax = exit code or -1 on failure
;----------------------------------------------------------
global spawnl
spawnl:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 96

    mov r12, rcx        ; mode
    mov r13, rdx        ; path

    ; zero structs
    lea rcx, [_startup_info]
    xor rdx, rdx
    mov r8, 104
    call memset

    lea rcx, [_process_info]
    xor rdx, rdx
    mov r8, 64
    call memset

    mov dword [_startup_info], 104

    ; CreateProcessA with path as both app and cmdline
    mov rcx, r13
    mov rdx, r13
    xor r8, r8
    xor r9, r9
    mov qword [rsp + 32], 0
    mov qword [rsp + 40], 0
    mov qword [rsp + 48], 0
    mov qword [rsp + 56], 0
    lea rax, [_startup_info]
    mov [rsp + 64], rax
    lea rax, [_process_info]
    mov [rsp + 72], rax
    call CreateProcessA
    test rax, rax
    jz  .fail

    ; if mode = 0, wait
    test r12, r12
    jnz .nowait

    mov rcx, [_process_info]
    mov rdx, -1
    call WaitForSingleObject

    mov rcx, [_process_info]
    lea rdx, [rsp + 88]
    call GetExitCodeProcess
    mov r14d, [rsp + 88]

    mov rcx, [_process_info]
    call CloseHandle
    mov rcx, [_process_info + 8]
    call CloseHandle

    mov rax, r14
    add rsp, 96
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.nowait:
    ; return PID
    mov rax, [_process_info + 4]    ; dwProcessId
    add rsp, 96
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.fail:
    or rax, -1
    add rsp, 96
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
