; userlib/mac64/time.asm
default rel

section .bss
_tm resb 64

section .text
global time, clock, difftime, gmtime, localtime, mktime, asctime, ctime, strftime

time:
    mov r8, rdi
    xor edi, edi
    mov eax, 0x2000074
    syscall
    test r8, r8
    jz .done
    mov [r8], rax
.done:
    ret

clock:
    xor eax, eax
    ret

difftime:
    sub rdi, rsi
    cvtsi2sd xmm0, rdi
    ret

gmtime:
localtime:
    lea rax, [_tm]
    ret

mktime:
    mov rax, -1
    ret

asctime:
ctime:
    xor eax, eax
    ret

strftime:
    xor eax, eax
    ret
