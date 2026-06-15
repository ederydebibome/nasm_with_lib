; userlib/linux64/stdio.asm
; Linux x86-64 - System V ABI, syscall based stdio subset.
default rel

extern strlen

section .bss
io_ch resb 1
printf_buf resb 32

section .text
global puts, putchar, getchar, gets, printf, sprintf, snprintf
global scanf, fopen, fclose, fread, fwrite, fgetc, fputc, fgets, fputs
global ungetc, fseek, ftell, rewind, feof, ferror, fflush, remove, rename, tmpfile

puts:
    push rbp
    mov rbp, rsp
    push rdi
    call strlen
    mov rdx, rax
    mov rsi, [rbp - 8]
    mov eax, 1
    mov edi, 1
    syscall
    mov byte [io_ch], 10
    mov eax, 1
    mov edi, 1
    lea rsi, [io_ch]
    mov edx, 1
    syscall
    xor eax, eax
    leave
    ret

putchar:
    mov [io_ch], dil
    mov eax, 1
    mov edi, 1
    lea rsi, [io_ch]
    mov edx, 1
    syscall
    cmp rax, 1
    jne .fail
    movzx eax, byte [io_ch]
    ret
.fail:
    mov rax, -1
    ret

getchar:
    xor eax, eax
    xor edi, edi
    lea rsi, [io_ch]
    mov edx, 1
    syscall
    cmp rax, 1
    jne .fail
    movzx eax, byte [io_ch]
    ret
.fail:
    mov rax, -1
    ret

gets:
    push rbx
    mov rbx, rdi
.loop:
    call getchar
    cmp rax, -1
    je .fail
    cmp al, 10
    je .done
    cmp al, 13
    je .loop
    mov [rdi], al
    inc rdi
    jmp .loop
.done:
    mov byte [rdi], 0
    mov rax, rbx
    pop rbx
    ret
.fail:
    xor eax, eax
    pop rbx
    ret

printf:
    ; Minimal, reliable subset: writes the format string literally.
    push rbp
    mov rbp, rsp
    push rdi
    call strlen
    mov rdx, rax
    mov rsi, [rbp - 8]
    mov eax, 1
    mov edi, 1
    syscall
    leave
    ret

sprintf:
    ; dst, fmt: copies fmt literally and returns length.
    push rbp
    mov rbp, rsp
    push rdi
    mov rdi, rsi
    call strlen
    mov rcx, rax
    mov rdi, [rbp - 8]
    rep movsb
    mov byte [rdi], 0
    leave
    ret

snprintf:
    push rbp
    mov rbp, rsp
    push rdi
    mov rdi, rdx
    call strlen
    mov rcx, rax
    mov rdi, [rbp - 8]
    test rsi, rsi
    jz .done
    dec rsi
    cmp rcx, rsi
    cmova rcx, rsi
    rep movsb
.done:
    mov byte [rdi], 0
    leave
    ret

scanf:
    xor eax, eax
    ret

fopen:   xor eax, eax  ; file API stubs return failure unless backed by libc.
         ret
fclose:  mov eax, -1
         ret
fread:   xor eax, eax
         ret
fwrite:  xor eax, eax
         ret
fgetc:   mov eax, -1
         ret
fputc:   mov eax, -1
         ret
fgets:   xor eax, eax
         ret
fputs:   mov eax, -1
         ret
ungetc:  mov eax, -1
         ret
fseek:   mov eax, -1
         ret
ftell:   mov eax, -1
         ret
rewind:  ret
feof:    xor eax, eax
         ret
ferror:  xor eax, eax
         ret
fflush:  xor eax, eax
         ret
remove:  mov eax, 87
         syscall
         ret
rename:  mov eax, 82
         syscall
         ret
tmpfile: xor eax, eax
         ret
