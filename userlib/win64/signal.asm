; userlib/win64/signal.asm
; Windows x64 - <signal.h>-style minimal signal table for ASM code
default rel

extern abort

SIG_DFL equ 0
SIG_IGN equ 1
SIG_ERR equ -1
SIGNAL_MAX equ 32

section .data
_signal_handlers times SIGNAL_MAX dq 0

section .text

; signal(sig, handler) -> previous handler, or SIG_ERR (-1)
; rcx = sig, rdx = handler
global signal
signal:
    test ecx, ecx
    jl .fail
    cmp ecx, SIGNAL_MAX
    jae .fail
    lea r8, [_signal_handlers]
    mov rax, [r8 + rcx * 8]
    mov [r8 + rcx * 8], rdx
    ret
.fail:
    or rax, -1
    ret

; raise(sig) -> 0 on handled/default, -1 invalid
; rcx = sig
global raise
raise:
    test ecx, ecx
    jl .fail
    cmp ecx, SIGNAL_MAX
    jae .fail
    lea r8, [_signal_handlers]
    mov rax, [r8 + rcx * 8]
    cmp rax, SIG_IGN
    je .ok
    test rax, rax
    jz .default
    sub rsp, 40
    mov [rsp + 32], rcx
    call rax
    add rsp, 40
.ok:
    xor eax, eax
    ret
.default:
    cmp ecx, 22                 ; SIGABRT on common MS/MinGW setups
    jne .ok
    sub rsp, 40
    call abort
    add rsp, 40
    xor eax, eax
    ret
.fail:
    or rax, -1
    ret

; signal_clear() -> void
global signal_clear
signal_clear:
    lea rdx, [_signal_handlers]
    xor eax, eax
    mov ecx, SIGNAL_MAX
.loop:
    mov [rdx], rax
    add rdx, 8
    dec ecx
    jnz .loop
    ret
; signal_ignore(sig) -> previous handler or -1
global signal_ignore
signal_ignore:
    mov rdx, SIG_IGN
    jmp signal

; signal_default(sig) -> previous handler or -1
global signal_default
signal_default:
    xor edx, edx
    jmp signal

; signal_get(sig) -> current handler or -1
global signal_get
signal_get:
    test ecx, ecx
    jl .fail
    cmp ecx, SIGNAL_MAX
    jae .fail
    lea r8, [_signal_handlers]
    mov rax, [r8 + rcx * 8]
    ret
.fail:
    or rax, -1
    ret