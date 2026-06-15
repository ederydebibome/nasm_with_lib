; userlib/mac64/string.asm
; macOS x86-64 - System V ABI
default rel

section .data
strtok_saved dq 0

section .text
global strlen, strcpy, strncpy, strcat, strncat
global strcmp, strncmp, strchr, strrchr, strstr
global strspn, strcspn, strpbrk, strtok
global memcpy, memmove, memset, memcmp, memchr
global strdup, strndup

extern malloc

strlen:
    mov rcx, -1
    xor eax, eax
    repne scasb
    mov rax, -2
    sub rax, rcx
    ret

strcpy:
    mov rax, rdi
.loop:
    mov r8b, [rsi]
    mov [rdi], r8b
    inc rdi
    inc rsi
    test r8b, r8b
    jnz .loop
    ret

strncpy:
    mov rax, rdi
    test rdx, rdx
    jz .done
.copy:
    mov r8b, [rsi]
    mov [rdi], r8b
    inc rdi
    test r8b, r8b
    jz .pad
    inc rsi
    dec rdx
    jnz .copy
    ret
.pad:
    dec rdx
    jz .done
    mov byte [rdi], 0
    inc rdi
    jmp .pad
.done:
    ret

strcat:
    mov rax, rdi
.end:
    cmp byte [rdi], 0
    je .copy
    inc rdi
    jmp .end
.copy:
    mov r8b, [rsi]
    mov [rdi], r8b
    inc rdi
    inc rsi
    test r8b, r8b
    jnz .copy
    ret

strncat:
    mov rax, rdi
.end:
    cmp byte [rdi], 0
    je .copy
    inc rdi
    jmp .end
.copy:
    test rdx, rdx
    jz .term
    mov r8b, [rsi]
    test r8b, r8b
    jz .term
    mov [rdi], r8b
    inc rdi
    inc rsi
    dec rdx
    jmp .copy
.term:
    mov byte [rdi], 0
    ret

strcmp:
.loop:
    movzx eax, byte [rdi]
    movzx r8d, byte [rsi]
    cmp al, r8b
    jne .diff
    test al, al
    jz .eq
    inc rdi
    inc rsi
    jmp .loop
.diff:
    sub eax, r8d
    ret
.eq:
    xor eax, eax
    ret

strncmp:
    test rdx, rdx
    jz strcmp.eq
.loop:
    movzx eax, byte [rdi]
    movzx r8d, byte [rsi]
    cmp al, r8b
    jne .diff
    test al, al
    jz .eq
    inc rdi
    inc rsi
    dec rdx
    jnz .loop
.eq:
    xor eax, eax
    ret
.diff:
    sub eax, r8d
    ret

strchr:
.loop:
    mov al, [rdi]
    cmp al, sil
    je .found
    test al, al
    jz .none
    inc rdi
    jmp .loop
.found:
    mov rax, rdi
    ret
.none:
    xor eax, eax
    ret

strrchr:
    xor eax, eax
.loop:
    mov r8b, [rdi]
    cmp r8b, sil
    jne .next
    mov rax, rdi
.next:
    test r8b, r8b
    jz .done
    inc rdi
    jmp .loop
.done:
    ret

strstr:
    cmp byte [rsi], 0
    jne .outer
    mov rax, rdi
    ret
.outer:
    cmp byte [rdi], 0
    je .none
    mov r8, rdi
    mov r9, rsi
.inner:
    mov al, [r9]
    test al, al
    jz .found
    cmp [r8], al
    jne .advance
    inc r8
    inc r9
    jmp .inner
.advance:
    inc rdi
    jmp .outer
.found:
    mov rax, rdi
    ret
.none:
    xor eax, eax
    ret

strspn:
    xor rax, rax
.outer:
    mov r8b, [rdi + rax]
    test r8b, r8b
    jz .done
    mov r9, rsi
.inner:
    mov r10b, [r9]
    test r10b, r10b
    jz .done
    cmp r10b, r8b
    je .ok
    inc r9
    jmp .inner
.ok:
    inc rax
    jmp .outer
.done:
    ret

strcspn:
    xor rax, rax
.outer:
    mov r8b, [rdi + rax]
    test r8b, r8b
    jz .done
    mov r9, rsi
.inner:
    mov r10b, [r9]
    test r10b, r10b
    jz .ok
    cmp r10b, r8b
    je .done
    inc r9
    jmp .inner
.ok:
    inc rax
    jmp .outer
.done:
    ret

strpbrk:
.outer:
    mov r8b, [rdi]
    test r8b, r8b
    jz .none
    mov r9, rsi
.inner:
    mov r10b, [r9]
    test r10b, r10b
    jz .next
    cmp r10b, r8b
    je .found
    inc r9
    jmp .inner
.next:
    inc rdi
    jmp .outer
.found:
    mov rax, rdi
    ret
.none:
    xor eax, eax
    ret

strtok:
    test rdi, rdi
    jnz .start
    mov rdi, [strtok_saved]
    test rdi, rdi
    jz .none
.start:
.skip:
    mov al, [rdi]
    test al, al
    jz .none
    mov r8, rsi
.is_delim:
    mov r9b, [r8]
    test r9b, r9b
    jz .token
    cmp r9b, al
    je .skip_one
    inc r8
    jmp .is_delim
.skip_one:
    inc rdi
    jmp .skip
.token:
    mov rax, rdi
.scan:
    mov r9b, [rdi]
    test r9b, r9b
    jz .eos
    mov r8, rsi
.end_check:
    mov r10b, [r8]
    test r10b, r10b
    jz .cont
    cmp r10b, r9b
    je .cut
    inc r8
    jmp .end_check
.cont:
    inc rdi
    jmp .scan
.cut:
    mov byte [rdi], 0
    inc rdi
    mov [strtok_saved], rdi
    ret
.eos:
    mov qword [strtok_saved], 0
    ret
.none:
    xor eax, eax
    ret

memcpy:
    mov rax, rdi
    test rdx, rdx
    jz .done
.loop:
    mov r8b, [rsi]
    mov [rdi], r8b
    inc rdi
    inc rsi
    dec rdx
    jnz .loop
.done:
    ret

memmove:
    mov rax, rdi
    cmp rdi, rsi
    jbe memcpy.loop
    lea rdi, [rdi + rdx - 1]
    lea rsi, [rsi + rdx - 1]
    test rdx, rdx
    jz .done
.back:
    mov r8b, [rsi]
    mov [rdi], r8b
    dec rdi
    dec rsi
    dec rdx
    jnz .back
.done:
    ret

memset:
    mov rax, rdi
    test rdx, rdx
    jz .done
.loop:
    mov [rdi], sil
    inc rdi
    dec rdx
    jnz .loop
.done:
    ret

memcmp:
    test rdx, rdx
    jz .eq
.loop:
    movzx eax, byte [rdi]
    movzx r8d, byte [rsi]
    cmp al, r8b
    jne .diff
    inc rdi
    inc rsi
    dec rdx
    jnz .loop
.eq:
    xor eax, eax
    ret
.diff:
    sub eax, r8d
    ret

memchr:
    test rdx, rdx
    jz .none
.loop:
    cmp [rdi], sil
    je .found
    inc rdi
    dec rdx
    jnz .loop
.none:
    xor eax, eax
    ret
.found:
    mov rax, rdi
    ret

strdup:
    push rbp
    mov rbp, rsp
    push rdi
    call strlen
    inc rax
    mov rdi, rax
    call malloc
    test rax, rax
    jz .out
    mov rdi, rax
    mov rsi, [rbp - 8]
    mov rdx, -1
.copy:
    inc rdx
    mov r8b, [rsi + rdx]
    mov [rdi + rdx], r8b
    test r8b, r8b
    jnz .copy
.out:
    leave
    ret

strndup:
    push rbp
    mov rbp, rsp
    push rdi
    push rsi
    lea rdi, [rsi + 1]
    call malloc
    test rax, rax
    jz .out
    mov rdi, rax
    mov rsi, [rbp - 8]
    mov rdx, [rbp - 16]
    call strncpy
    mov rdx, [rbp - 16]
    mov byte [rax + rdx], 0
.out:
    leave
    ret
