; ctype.asm - <ctype.h> helpers, SysV x86-64 ABI
default rel
section .text
global isdigit, islower, isupper, isalpha, isalnum, isxdigit, isspace, iscntrl, isprint, isgraph, isblank, ispunct, tolower, toupper
isdigit: mov eax, edi
    sub eax, '0'
    cmp eax, 9
    setbe al
    movzx eax, al
    ret
islower: mov eax, edi
    sub eax, 'a'
    cmp eax, 25
    setbe al
    movzx eax, al
    ret
isupper: mov eax, edi
    sub eax, 'A'
    cmp eax, 25
    setbe al
    movzx eax, al
    ret
isalpha: mov eax, edi
    or al, 20h
    sub eax, 'a'
    cmp eax, 25
    setbe al
    movzx eax, al
    ret
isalnum: mov eax, edi
    sub eax, '0'
    cmp eax, 9
    jbe .yes
    mov eax, edi
    or al, 20h
    sub eax, 'a'
    cmp eax, 25
    jbe .yes
    xor eax, eax
    ret
.yes: mov eax, 1
    ret
isxdigit: mov eax, edi
    sub eax, '0'
    cmp eax, 9
    jbe .yes
    mov eax, edi
    or al, 20h
    sub eax, 'a'
    cmp eax, 5
    jbe .yes
    xor eax, eax
    ret
.yes: mov eax, 1
    ret
isspace: cmp edi, ' '
    je .yes
    mov eax, edi
    sub eax, 9
    cmp eax, 4
    jbe .yes
    xor eax, eax
    ret
.yes: mov eax, 1
    ret
iscntrl: cmp edi, 31
    jbe .yes
    cmp edi, 127
    je .yes
    xor eax, eax
    ret
.yes: mov eax, 1
    ret
isprint: mov eax, edi
    sub eax, 32
    cmp eax, 94
    setbe al
    movzx eax, al
    ret
isgraph: mov eax, edi
    sub eax, 33
    cmp eax, 93
    setbe al
    movzx eax, al
    ret
isblank: cmp edi, ' '
    je .yes
    cmp edi, 9
    je .yes
    xor eax, eax
    ret
.yes: mov eax, 1
    ret
ispunct: mov eax, edi
    sub eax, 33
    cmp eax, 93
    ja .no
    mov eax, edi
    sub eax, '0'
    cmp eax, 9
    jbe .no
    mov eax, edi
    or al, 20h
    sub eax, 'a'
    cmp eax, 25
    jbe .no
    mov eax, 1
    ret
.no: xor eax, eax
    ret
tolower: mov eax, edi
    sub eax, 'A'
    cmp eax, 25
    ja .unchanged
    lea eax, [rdi + 32]
    ret
.unchanged: mov eax, edi
    ret
toupper: mov eax, edi
    sub eax, 'a'
    cmp eax, 25
    ja .unchanged
    lea eax, [rdi - 32]
    ret
.unchanged: mov eax, edi
    ret