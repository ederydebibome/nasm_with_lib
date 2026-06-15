; userlib/mac64/stdlib.asm
; macOS x86-64 - System V ABI
default rel

section .data
_rand_seed dq 12345678
_rand_hw_checked db 0
_rand_hw_supported db 0
_atexit_table times 32 dq 0
_atexit_count dq 0

section .text
global malloc, calloc, realloc, free
global atoi, atol, atof, itoa, _abs, labs
global rand, srand, qsort, bsearch, getenv, setenv, atexit, _run_atexit

extern strlen

malloc:
    ; mmap anonymous memory. Stores the requested size in a 16-byte header.
    push rdi
    add rdi, 16
    mov rsi, rdi
    xor rdi, rdi
    mov edx, 3
    mov r10d, 0x22
    mov r8, -1
    xor r9d, r9d
    mov eax, 0x20000c5
    syscall
    cmp rax, -4095
    jae .fail
    pop rcx
    mov [rax], rcx
    add rax, 16
    ret
.fail:
    pop rcx
    xor eax, eax
    ret

calloc:
    imul rdi, rsi
    jmp malloc

free:
    test rdi, rdi
    jz .done
    sub rdi, 16
    mov rsi, [rdi]
    add rsi, 16
    mov eax, 0x2000049
    syscall
.done:
    ret

realloc:
    test rdi, rdi
    jz .new
    test rsi, rsi
    jz .free_old
    mov r8, rdi
    mov rdi, rsi
    call malloc
    test rax, rax
    jz .done
    mov rcx, [r8 - 16]
    cmp rcx, rsi
    cmova rcx, rsi
    mov rdi, rax
    mov rsi, r8
    rep movsb
    mov rdi, r8
    call free
.done:
    ret
.new:
    mov rdi, rsi
    jmp malloc
.free_old:
    call free
    xor eax, eax
    ret

atoi:
    xor eax, eax
    xor r8d, r8d
.ws:
    movzx edx, byte [rdi]
    cmp dl, ' '
    je .nextws
    cmp dl, 9
    jne .sign
.nextws:
    inc rdi
    jmp .ws
.sign:
    cmp dl, '-'
    jne .plus
    mov r8d, 1
    inc rdi
    jmp .digits
.plus:
    cmp dl, '+'
    jne .digits
    inc rdi
.digits:
    movzx edx, byte [rdi]
    cmp dl, '0'
    jb .done
    cmp dl, '9'
    ja .done
    imul rax, rax, 10
    sub dl, '0'
    add rax, rdx
    inc rdi
    jmp .digits
.done:
    test r8d, r8d
    jz .ret
    neg rax
.ret:
    ret

atol: jmp atoi

atof:
    xorpd xmm0, xmm0
    ret

itoa:
    mov r9, rsi
    mov rax, rdi
    mov r10, rdx
    cmp r10, 2
    jb .bad
    cmp r10, 36
    ja .bad
    test rax, rax
    jns .pos
    cmp r10, 10
    jne .pos
    mov byte [rsi], '-'
    inc rsi
    neg rax
.pos:
    lea r8, [rsi + 65]
    mov byte [r8], 0
.div:
    xor edx, edx
    div r10
    cmp dl, 9
    jbe .num
    add dl, 'a' - 10
    jmp .put
.num:
    add dl, '0'
.put:
    dec r8
    mov [r8], dl
    test rax, rax
    jnz .div
.copy:
    mov al, [r8]
    mov [rsi], al
    inc r8
    inc rsi
    test al, al
    jnz .copy
    mov rax, r9
    ret
.bad:
    mov byte [rsi], 0
    mov rax, r9
    ret

_abs:
labs:
    mov rax, rdi
    test rax, rax
    jns .done
    neg rax
.done:
    ret

rand:
    push rbx
    cmp byte [_rand_hw_checked], 0
    jne .checked
    mov eax, 1
    cpuid
    bt ecx, 30
    setc [_rand_hw_supported]
    mov byte [_rand_hw_checked], 1
.checked:
    cmp byte [_rand_hw_supported], 0
    je .fallback
    mov ecx, 10
.retry:
    rdrand eax
    jc .done
    loop .retry
.fallback:
    rdtsc
    xor eax, edx
    xor eax, esp
    xor eax, [_rand_seed]
    imul eax, eax, 1103515245
    add eax, 12345
    mov [_rand_seed], rax
.done:
    and eax, 0x7fff
    pop rbx
    ret

srand:
    mov [_rand_seed], rdi
    ret

qsort:
    ret

bsearch:
    xor eax, eax
    ret

getenv:
    xor eax, eax
    ret

setenv:
    mov eax, -1
    ret

atexit:
    mov rax, [_atexit_count]
    cmp rax, 32
    jae .fail
    lea rdx, [_atexit_table]
    mov [rdx + rax * 8], rdi
    inc qword [_atexit_count]
    xor eax, eax
    ret
.fail:
    mov eax, -1
    ret

_run_atexit:
    mov rcx, [_atexit_count]
.loop:
    test rcx, rcx
    jz .done
    dec rcx
    lea rdx, [_atexit_table]
    call qword [rdx + rcx * 8]
    jmp .loop
.done:
    ret
