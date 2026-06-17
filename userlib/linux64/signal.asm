; signal.asm - minimal <signal.h>, SysV x86-64 ABI
default rel
extern abort
SIG_IGN equ 1
SIGNAL_MAX equ 32
section .data
_signal_handlers times SIGNAL_MAX dq 0
section .text
global signal, raise, signal_clear
signal:
    test edi, edi
    jl .fail
    cmp edi, SIGNAL_MAX
    jae .fail
    lea r8, [_signal_handlers]
    mov rax, [r8+rdi*8]
    mov [r8+rdi*8], rsi
    ret
.fail: or rax, -1
    ret
raise:
    test edi, edi
    jl .fail
    cmp edi, SIGNAL_MAX
    jae .fail
    lea r8, [_signal_handlers]
    mov rax, [r8+rdi*8]
    cmp rax, SIG_IGN
    je .ok
    test rax, rax
    jz .default
    sub rsp, 8
    call rax
    add rsp, 8
.ok: xor eax, eax
    ret
.default:
    cmp edi, 6
    jne .ok
    call abort
    xor eax, eax
    ret
.fail: or rax, -1
    ret
signal_clear:
    lea rdx, [_signal_handlers]
    xor eax, eax
    mov ecx, SIGNAL_MAX
.loop: mov [rdx], rax
    add rdx, 8
    dec ecx
    jnz .loop
    ret