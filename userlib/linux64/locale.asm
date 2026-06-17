; locale.asm - minimal C/POSIX locale, SysV x86-64 ABI
default rel
section .data
_locale_c db 'C',0
_decimal_point db '.',0
_empty db 0
_grouping db 0
_lconv:
    dq _decimal_point, _empty, _grouping, _empty, _empty
    dq _empty, _empty, _grouping, _empty, _empty
    db 127,127,127,127,127,127,127,127,127,127,127,127,127,127
    times 2 db 0
section .text
global setlocale, localeconv
setlocale:
    cmp edi, 5
    ja .fail
    test rsi, rsi
    jz .ok
    mov al, [rsi]
    test al, al
    jz .ok
    cmp al, 'C'
    jne .posix
    cmp byte [rsi+1], 0
    je .ok
    jmp .fail
.posix:
    cmp dword [rsi], 'POSI'
    jne .fail
    cmp byte [rsi+4], 'X'
    jne .fail
    cmp byte [rsi+5], 0
    jne .fail
.ok: lea rax, [_locale_c]
    ret
.fail: xor eax, eax
    ret
localeconv: lea rax, [_lconv]
    ret