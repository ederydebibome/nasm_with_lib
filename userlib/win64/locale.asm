; userlib/win64/locale.asm
; Windows x64 - Microsoft calling convention
; minimal C/POSIX locale support for <locale.h>
default rel

LC_ALL       equ 0
LC_COLLATE   equ 1
LC_CTYPE     equ 2
LC_MONETARY  equ 3
LC_NUMERIC   equ 4
LC_TIME      equ 5

section .data
_locale_c       db 'C', 0
_locale_posix   db 'POSIX', 0
_decimal_point  db '.', 0
_empty          db 0
_grouping       db 0

; struct lconv, pointer fields then char fields, enough for C/POSIX locale users.
_lconv:
    dq _decimal_point       ; decimal_point
    dq _empty               ; thousands_sep
    dq _grouping            ; grouping
    dq _empty               ; int_curr_symbol
    dq _empty               ; currency_symbol
    dq _empty               ; mon_decimal_point
    dq _empty               ; mon_thousands_sep
    dq _grouping            ; mon_grouping
    dq _empty               ; positive_sign
    dq _empty               ; negative_sign
    db 127                  ; int_frac_digits = CHAR_MAX
    db 127                  ; frac_digits
    db 127                  ; p_cs_precedes
    db 127                  ; p_sep_by_space
    db 127                  ; n_cs_precedes
    db 127                  ; n_sep_by_space
    db 127                  ; p_sign_posn
    db 127                  ; n_sign_posn
    db 127                  ; int_p_cs_precedes
    db 127                  ; int_p_sep_by_space
    db 127                  ; int_n_cs_precedes
    db 127                  ; int_n_sep_by_space
    db 127                  ; int_p_sign_posn
    db 127                  ; int_n_sign_posn
    times 2 db 0

section .text

global setlocale
setlocale:
    ; rcx = category, rdx = locale string or NULL
    cmp ecx, LC_TIME
    ja .fail
    test rdx, rdx
    jz .ok
    mov al, [rdx]
    test al, al
    jz .ok              ; empty string: use default C locale in this minimal libc
    cmp al, 'C'
    jne .check_posix
    cmp byte [rdx + 1], 0
    je .ok
    jmp .fail
.check_posix:
    cmp al, 'P'
    jne .fail
    cmp byte [rdx + 1], 'O'
    jne .fail
    cmp byte [rdx + 2], 'S'
    jne .fail
    cmp byte [rdx + 3], 'I'
    jne .fail
    cmp byte [rdx + 4], 'X'
    jne .fail
    cmp byte [rdx + 5], 0
    jne .fail
.ok:
    lea rax, [_locale_c]
    ret
.fail:
    xor eax, eax
    ret

global localeconv
localeconv:
    lea rax, [_lconv]
    ret