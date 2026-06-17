; userlib/win64/ctype.asm
; Windows x64 - Microsoft calling convention
; mirrors <ctype.h> for unsigned char / EOF-style int inputs
default rel

; Fast NASM macros for ASM callers. Result goes to an 8/32/64-bit register as 0/1.
%macro CTYPE_ISDIGIT_REG 2
    mov %1, %2
    sub %1, '0'
    cmp %1, 9
    setbe al
    movzx %1, al
%endmacro

%macro CTYPE_ISALPHA_REG 2
    mov %1, %2
    or %1, 20h
    sub %1, 'a'
    cmp %1, 25
    setbe al
    movzx %1, al
%endmacro

%macro CTYPE_TOUPPER_REG 2
    mov %1, %2
    cmp %1, 'a'
    jb %%done
    cmp %1, 'z'
    ja %%done
    sub %1, 32
%%done:
%endmacro

%macro CTYPE_TOLOWER_REG 2
    mov %1, %2
    cmp %1, 'A'
    jb %%done
    cmp %1, 'Z'
    ja %%done
    add %1, 32
%%done:
%endmacro

section .text

global isdigit
isdigit:
    mov eax, ecx
    sub eax, '0'
    cmp eax, 9
    setbe al
    movzx eax, al
    ret

global islower
islower:
    mov eax, ecx
    sub eax, 'a'
    cmp eax, 25
    setbe al
    movzx eax, al
    ret

global isupper
isupper:
    mov eax, ecx
    sub eax, 'A'
    cmp eax, 25
    setbe al
    movzx eax, al
    ret

global isalpha
isalpha:
    mov eax, ecx
    or al, 0x20
    sub eax, 'a'
    cmp eax, 25
    setbe al
    movzx eax, al
    ret

global isalnum
isalnum:
    mov eax, ecx
    sub eax, '0'
    cmp eax, 9
    jbe .yes
    mov eax, ecx
    or al, 0x20
    sub eax, 'a'
    cmp eax, 25
    jbe .yes
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret

global isxdigit
isxdigit:
    mov eax, ecx
    sub eax, '0'
    cmp eax, 9
    jbe .yes
    mov eax, ecx
    or al, 0x20
    sub eax, 'a'
    cmp eax, 5
    jbe .yes
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret

global isspace
isspace:
    cmp ecx, ' '
    je .yes
    mov eax, ecx
    sub eax, 9
    cmp eax, 4          ; \t..\r
    jbe .yes
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret

global iscntrl
iscntrl:
    cmp ecx, 31
    jbe .yes
    cmp ecx, 127
    je .yes
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret

global isprint
isprint:
    mov eax, ecx
    sub eax, 32
    cmp eax, 94
    setbe al
    movzx eax, al
    ret

global isgraph
isgraph:
    mov eax, ecx
    sub eax, 33
    cmp eax, 93
    setbe al
    movzx eax, al
    ret

global isblank
isblank:
    cmp ecx, ' '
    je .yes
    cmp ecx, 9
    je .yes
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret

global ispunct
ispunct:
    mov eax, ecx
    sub eax, 33
    cmp eax, 93
    ja .no
    mov eax, ecx
    sub eax, '0'
    cmp eax, 9
    jbe .no
    mov eax, ecx
    or al, 0x20
    sub eax, 'a'
    cmp eax, 25
    jbe .no
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

global tolower
tolower:
    mov eax, ecx
    sub eax, 'A'
    cmp eax, 25
    ja .unchanged
    lea eax, [rcx + 32]
    ret
.unchanged:
    mov eax, ecx
    ret

global toupper
toupper:
    mov eax, ecx
    sub eax, 'a'
    cmp eax, 25
    ja .unchanged
    lea eax, [rcx - 32]
    ret
.unchanged:
    mov eax, ecx
    ret