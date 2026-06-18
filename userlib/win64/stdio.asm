; userlib/win64/io.asm
; Windows x64 - Microsoft calling convention
default rel

extern GetStdHandle
extern WriteFile
extern ReadFile
extern strlen

section .data
io_written      dd 0
io_read         dd 0
io_buf          times 64 db 0
printf_buf      times 32 db 0
printf_f_half   dq 0.5
printf_f_zero   dq 0.0
printf_f_sign   dq 0x8000000000000000
io_newline      db 0x0A

section .text

;----------------------------------------------------------
; puts - write string to stdout followed by newline
; rcx = pointer to null-terminated string
; returns rax = 0 on success, -1 on failure
;----------------------------------------------------------
global puts
puts:
    push rbx
    push r12
    push r13
    sub rsp, 48
    mov r12, rcx
    ; get string length
    call strlen
    mov r13, rax
    ; get stdout handle
    mov rcx, -11
    call GetStdHandle
    mov rbx, rax
    mov rcx, rbx
    mov rdx, r12
    mov r8, r13
    lea r9, [io_written]
    mov qword [rsp + 32], 0
    call WriteFile
    test rax, rax
    jz  .fail
    ; write newline
    mov rcx, rbx
    lea rdx, [io_newline]
    mov r8, 1
    lea r9, [io_written]
    mov qword [rsp + 32], 0
    call WriteFile
    xor rax, rax
    add rsp, 48
    pop r13
    pop r12
    pop rbx
    ret
.fail:
    or rax, -1
    add rsp, 48
    pop r13
    pop r12
    pop rbx
    ret

;----------------------------------------------------------
; putchar - write single character to stdout
; rcx = character (byte)
; returns rax = character written or -1 on failure
;----------------------------------------------------------
global putchar
putchar:
    push rbx
    sub rsp, 48
    mov byte [rsp + 40], cl
    mov rcx, -11
    call GetStdHandle
    mov rbx, rax
    mov rcx, rbx
    lea rdx, [rsp + 40]
    mov r8, 1
    lea r9, [io_written]
    mov qword [rsp + 32], 0
    call WriteFile
    test rax, rax
    jz .fail
    movzx rax, byte [rsp + 40]
    add rsp, 48
    pop rbx
    ret
.fail:
    or rax, -1
    add rsp, 48
    pop rbx
    ret

;----------------------------------------------------------
; getchar - read single character from stdin
; returns rax = character or -1 on failure
;----------------------------------------------------------
global getchar
getchar:
    push rbx
    sub rsp, 48
    mov rcx, -10
    call GetStdHandle
    mov rbx, rax
    mov rcx, rbx
    lea rdx, [rsp + 40]
    mov r8, 1
    lea r9, [io_read]
    mov qword [rsp + 32], 0
    call ReadFile
    test rax, rax
    jz  .fail
    movzx rax, byte [rsp + 40]
    add rsp, 48
    pop rbx
    ret
.fail:
    or rax, -1
    add rsp, 48
    pop rbx
    ret

;----------------------------------------------------------
; gets - read line from stdin into buffer (no bounds check)
; rcx = buffer
; returns rax = buffer or 0 on failure
;----------------------------------------------------------
global gets
gets:
    push rbx
    push r12
    push r13
    sub rsp, 48
    mov r12, rcx
    xor r13, r13
    mov rcx, -10
    call GetStdHandle
    mov rbx, rax
.loop:
    mov rcx, rbx
    lea rdx, [rsp + 40]
    mov r8, 1
    lea r9, [io_read]
    mov qword [rsp + 32], 0
    call ReadFile
    test rax, rax
    jz  .fail
    movzx rax, byte [rsp + 40]
    cmp al, 0x0A
    je  .done
    cmp al, 0x0D
    je  .loop
    mov byte [r12 + r13], al
    inc r13
    jmp .loop
.done:
    mov byte [r12 + r13], 0
    mov rax, r12
    add rsp, 48
    pop r13
    pop r12
    pop rbx
    ret
.fail:
    xor rax, rax
    add rsp, 48
    pop r13
    pop r12
    pop rbx
    ret

;----------------------------------------------------------
; gets_s - read line with bounds
; rcx = buffer, rdx = buffer size
; returns rax = buffer or 0 on failure
;----------------------------------------------------------
global gets_s
gets_s:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 48
    test rcx, rcx
    jz .fail
    cmp rdx, 1
    jb .fail
    mov r12, rcx
    mov r14, rdx
    dec r14
    xor r13, r13
    mov rcx, -10
    call GetStdHandle
    mov rbx, rax
.loop:
    cmp r13, r14
    jae .done
    mov rcx, rbx
    lea rdx, [rsp + 40]
    mov r8, 1
    lea r9, [io_read]
    mov qword [rsp + 32], 0
    call ReadFile
    test rax, rax
    jz .fail
    movzx eax, byte [rsp + 40]
    cmp al, 0x0A
    je .done
    cmp al, 0x0D
    je .loop
    mov [r12 + r13], al
    inc r13
    jmp .loop
.done:
    mov byte [r12 + r13], 0
    mov rax, r12
    add rsp, 48
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.fail:
    xor eax, eax
    add rsp, 48
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

;----------------------------------------------------------
; printf - formatted output to stdout
; supports: %s %d %u %x %c %%
; rcx = format string
; rdx, r8, r9, [rsp+32]... = arguments
; returns rax = number of chars written
;----------------------------------------------------------
global printf
printf:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64

    mov r12, rcx
    mov [rbp - 64], rdx
    mov [rbp - 56], r8
    mov [rbp - 48], r9
    xor r13, r13
    xor r14, r14
    mov rcx, -11
    call GetStdHandle
    mov rbx, rax

.next_char:
    movzx rax, byte [r12]
    test al, al
    jz  .done
    cmp al, '%'
    je  .format
    mov r15, r12
.literal_scan:
    inc r12
    movzx eax, byte [r12]
    test al, al
    jz .literal_write
    cmp al, '%'
    jne .literal_scan
.literal_write:
    mov r8, r12
    sub r8, r15
    add r14, r8
    mov rcx, rbx
    mov rdx, r15
    lea r9, [io_written]
    mov qword [rsp + 32], 0
    call WriteFile
    jmp .next_char

.format:inc r12
    mov qword [rbp - 40], 6
    movzx rax, byte [r12]
    cmp al, '.'
    jne .format_spec
    inc r12
    xor r10d, r10d
.precision_loop:
    movzx eax, byte [r12]
    cmp al, '0'
    jb .precision_done
    cmp al, '9'
    ja .precision_done
    imul r10d, r10d, 10
    sub al, '0'
    movzx eax, al
    add r10d, eax
    inc r12
    jmp .precision_loop
.precision_done:
    cmp r10d, 15
    jbe .precision_store
    mov r10d, 15
.precision_store:
    mov [rbp - 40], r10
.format_spec:
    movzx rax, byte [r12]
    inc r12
    cmp al, '%'
    je  .print_percent
    cmp al, 'c'
    je  .print_char
    cmp al, 's'
    je  .print_string
    cmp al, 'd'
    je  .print_int
    cmp al, 'u'
    je  .print_uint
    cmp al, 'x'
    je  .print_hex
    cmp al, 'f'
    je  .print_float
    jmp .next_char

.print_percent:
    mov rcx, '%'
    call putchar
    inc r14
    jmp .next_char

.print_char:
    call .get_arg
    mov rcx, rax
    call putchar
    inc r14
    jmp .next_char

.print_string:
    call .get_arg
    mov r15, rax
    mov rcx, rax
    call strlen
    add r14, rax
    mov r8, rax
    mov rcx, rbx
    mov rdx, r15
    lea r9, [io_written]
    mov qword [rsp + 32], 0
    call WriteFile
    jmp .next_char

.print_int:
    call .get_arg
    movsxd rcx, eax
    call .write_signed
    jmp .next_char

.print_uint:
    call .get_arg
    mov ecx, eax
    call .write_unsigned
    jmp .next_char

.print_hex:
    call .get_arg
    mov rcx, rax
    call .write_hex
    jmp .next_char

.print_float:
    call .get_arg
    movq xmm0, rax
    call .write_float
    jmp .next_char

.done:
    mov rax, r14
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.get_arg:
    cmp r13, 0
    je  .a0
    cmp r13, 1
    je  .a1
    cmp r13, 2
    je  .a2
    mov rax, r13
    sub rax, 3
    imul rax, 8
    add rax, 48
    mov rax, [rbp + rax]
    inc r13
    ret
.a0:
    mov rax, [rbp - 64]
    inc r13
    ret
.a1:
    mov rax, [rbp - 56]
    inc r13
    ret
.a2:
    mov rax, [rbp - 48]
    inc r13
    ret

.write_signed:
    test rcx, rcx
    jns .write_unsigned
    push rcx
    mov rcx, '-'
    call putchar
    inc r14
    pop rcx
    neg rcx

.write_unsigned:
    sub rsp, 40
    lea rdi, [printf_buf + 31]
    mov byte [rdi], 0
    mov rax, rcx
    mov rcx, 10
.udiv_loop:
    xor rdx, rdx
    div rcx
    add dl, '0'
    dec rdi
    mov byte [rdi], dl
    test rax, rax
    jnz .udiv_loop
    mov rcx, rdi
    call strlen
    add r14, rax
    mov r8, rax
    mov r15, rdi
    mov rcx, rbx
    mov rdx, r15
    lea r9, [io_written]
    mov qword [rsp + 32], 0
    call WriteFile
    add rsp, 40
    ret

.write_hex:
    sub rsp, 40
    lea rdi, [printf_buf + 31]
    mov byte [rdi], 0
    mov rax, rcx
.hex_loop:
    mov rcx, rax
    and rcx, 0xF
    cmp rcx, 9
    jle .hex_num
    add rcx, 'a' - 10
    jmp .hex_put
.hex_num:
    add rcx, '0'
.hex_put:
    dec rdi
    mov byte [rdi], cl
    shr rax, 4
    jnz .hex_loop
    mov rcx, rdi
    call strlen
    add r14, rax
    mov r8, rax
    mov r15, rdi
    mov rcx, rbx
    mov rdx, r15
    lea r9, [io_written]
    mov qword [rsp + 32], 0
    call WriteFile
    add rsp, 40
    ret

;----------------------------------------------------------
.write_float:
    sub rsp, 72
    ucomisd xmm0, [printf_f_zero]
    jae .float_abs
    xorpd xmm0, [printf_f_sign]
    mov rcx, '-'
    call putchar
    inc r14
.float_abs:
    mov r9, [rbp - 40]
    mov [rsp + 48], r9
    mov r10, 1
    mov rcx, r9
.float_scale_loop:
    test rcx, rcx
    jz .float_scale_done
    imul r10, r10, 10
    dec rcx
    jmp .float_scale_loop
.float_scale_done:
    cvtsi2sd xmm2, r10
    movsd xmm1, [printf_f_half]
    divsd xmm1, xmm2
    addsd xmm0, xmm1
    cvttsd2si rcx, xmm0
    mov [rsp + 40], rcx
    cvtsi2sd xmm1, rcx
    subsd xmm0, xmm1
    mulsd xmm0, xmm2
    cvttsd2si r8, xmm0
    mov [rsp + 56], r8
    mov rcx, [rsp + 40]
    call .write_unsigned
    mov r9, [rsp + 48]
    test r9, r9
    jz .float_done
    mov rcx, '.'
    call putchar
    inc r14
    mov r9, [rsp + 48]
    lea r11, [printf_buf + 31]
    mov byte [r11], 0
    mov rax, [rsp + 56]
    mov rcx, r9
.float_frac_loop:
    xor rdx, rdx
    mov r8, 10
    div r8
    add dl, '0'
    dec r11
    mov [r11], dl
    dec rcx
    jnz .float_frac_loop
    mov rcx, rbx
    mov rdx, r11
    mov r8, [rsp + 48]
    lea r9, [io_written]
    mov qword [rsp + 32], 0
    call WriteFile
    add r14, [rsp + 48]
.float_done:
    add rsp, 72
    ret
; printf_s - secure CRT compatible alias for printf subset
; rcx = format string
;----------------------------------------------------------
global printf_s
printf_s:
    jmp printf

;----------------------------------------------------------
; sprintf - formatted output to string
; rcx = buffer
; rdx = format string
; r8, r9, [rsp+32]... = arguments
; returns rax = number of chars written
;----------------------------------------------------------
global sprintf
sprintf:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64

    mov r15, rcx        ; output buffer
    mov r12, rdx        ; format string
    mov [rbp - 64], r8
    mov [rbp - 56], r9
    xor r13, r13
    xor r14, r14        ; chars written

.sp_next:
    movzx rax, byte [r12]
    test al, al
    jz  .sp_done
    cmp al, '%'
    je  .sp_format
    mov byte [r15], al
    inc r15
    inc r14
    inc r12
    jmp .sp_next

.sp_format:
    inc r12
    movzx rax, byte [r12]
    inc r12
    cmp al, '%'
    je  .sp_percent
    cmp al, 'c'
    je  .sp_char
    cmp al, 's'
    je  .sp_string
    cmp al, 'd'
    je  .sp_int
    cmp al, 'u'
    je  .sp_uint
    cmp al, 'x'
    je  .sp_hex
    jmp .sp_next

.sp_percent:
    mov byte [r15], '%'
    inc r15
    inc r14
    jmp .sp_next

.sp_char:
    call .sp_get_arg
    mov byte [r15], al
    inc r15
    inc r14
    jmp .sp_next

.sp_string:
    call .sp_get_arg
    mov rbx, rax
.sp_str_loop:
    mov cl, byte [rbx]
    test cl, cl
    jz  .sp_next
    mov byte [r15], cl
    inc r15
    inc r14
    inc rbx
    jmp .sp_str_loop

.sp_int:
    call .sp_get_arg
    movsxd rcx, eax
    test rcx, rcx
    jns .sp_write_uint
    mov byte [r15], '-'
    inc r15
    inc r14
    neg rcx
    jmp .sp_write_uint

.sp_uint:
    call .sp_get_arg
    mov ecx, eax

.sp_write_uint:
    lea rdi, [printf_buf + 31]
    mov byte [rdi], 0
    mov rax, rcx
    mov rcx, 10
.sp_udiv:
    xor rdx, rdx
    div rcx
    add dl, '0'
    dec rdi
    mov byte [rdi], dl
    test rax, rax
    jnz .sp_udiv
.sp_copy_num:
    mov cl, byte [rdi]
    test cl, cl
    jz  .sp_next
    mov byte [r15], cl
    inc r15
    inc r14
    inc rdi
    jmp .sp_copy_num

.sp_hex:
    call .sp_get_arg
    lea rdi, [printf_buf + 31]
    mov byte [rdi], 0
.sp_hex_loop:
    mov rcx, rax
    and rcx, 0xF
    cmp rcx, 9
    jle .sp_hex_num
    add rcx, 'a' - 10
    jmp .sp_hex_put
.sp_hex_num:
    add rcx, '0'
.sp_hex_put:
    dec rdi
    mov byte [rdi], cl
    shr rax, 4
    jnz .sp_hex_loop
.sp_copy_hex:
    mov cl, byte [rdi]
    test cl, cl
    jz  .sp_next
    mov byte [r15], cl
    inc r15
    inc r14
    inc rdi
    jmp .sp_copy_hex

.sp_done:
    mov byte [r15], 0
    mov rax, r14
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.sp_get_arg:
    cmp r13, 0
    je  .sp_a0
    cmp r13, 1
    je  .sp_a1
    mov rax, r13
    sub rax, 2
    imul rax, 8
    add rax, 48
    mov rax, [rbp + rax]
    inc r13
    ret
.sp_a0:
    mov rax, [rbp - 64]
    inc r13
    ret
.sp_a1:
    mov rax, [rbp - 56]
    inc r13
    ret

;----------------------------------------------------------
; sprintf_s - bounded sprintf
; rcx = buffer, rdx = buffer size, r8 = format, r9... = args
; returns rax = chars written, -1 on invalid buffer/size
;----------------------------------------------------------
global sprintf_s
sprintf_s:
    test rcx, rcx
    jz .fail
    test rdx, rdx
    jz .fail
    mov rdx, r8
    mov r8, r9
    mov r9, [rsp + 40]
    jmp sprintf
.fail:
    or rax, -1
    ret

; snprintf_s: for this library, same bounded behavior as sprintf_s.
global snprintf_s
snprintf_s:
    jmp snprintf

;----------------------------------------------------------
; snprintf - sprintf with size limit
; rcx = buffer
; rdx = max size
; r8  = format string
; r9, [rsp+32]... = arguments
; returns rax = number of chars written
;----------------------------------------------------------
global snprintf
snprintf:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64

    mov r15, rcx        ; output buffer
    mov rbx, rdx        ; max size
    mov r12, r8         ; format string
    mov [rbp - 64], r9
    xor r13, r13
    xor r14, r14

.sn_next:
    movzx rax, byte [r12]
    test al, al
    jz  .sn_done
    cmp r14, rbx
    jge .sn_done
    cmp al, '%'
    je  .sn_format
    mov byte [r15], al
    inc r15
    inc r14
    inc r12
    jmp .sn_next

.sn_format:
    inc r12
    movzx rax, byte [r12]
    inc r12
    cmp al, 's'
    je  .sn_string
    cmp al, 'd'
    je  .sn_int
    cmp al, 'c'
    je  .sn_char
    jmp .sn_next

.sn_char:
    call .sn_get_arg
    cmp r14, rbx
    jge .sn_done
    mov byte [r15], al
    inc r15
    inc r14
    jmp .sn_next

.sn_string:
    call .sn_get_arg
    mov r11, rax
.sn_str_loop:
    cmp r14, rbx
    jge .sn_done
    mov cl, byte [r11]
    test cl, cl
    jz  .sn_next
    mov byte [r15], cl
    inc r15
    inc r14
    inc r11
    jmp .sn_str_loop

.sn_int:
    call .sn_get_arg
    mov rcx, rax
    test rcx, rcx
    jns .sn_uint
    cmp r14, rbx
    jge .sn_done
    mov byte [r15], '-'
    inc r15
    inc r14
    neg rcx

.sn_uint:
    lea rdi, [printf_buf + 31]
    mov byte [rdi], 0
    mov rax, rcx
    mov rcx, 10
.sn_udiv:
    xor rdx, rdx
    div rcx
    add dl, '0'
    dec rdi
    mov byte [rdi], dl
    test rax, rax
    jnz .sn_udiv
.sn_copy:
    cmp r14, rbx
    jge .sn_done
    mov cl, byte [rdi]
    test cl, cl
    jz  .sn_next
    mov byte [r15], cl
    inc r15
    inc r14
    inc rdi
    jmp .sn_copy

.sn_done:
    mov byte [r15], 0
    mov rax, r14
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.sn_get_arg:
    cmp r13, 0
    je  .sn_a0
    mov rax, r13
    sub rax, 1
    imul rax, 8
    add rax, 48
    mov rax, [rbp + rax]
    inc r13
    ret
.sn_a0:
    mov rax, [rbp - 64]
    inc r13
    ret

;----------------------------------------------------------
; scanf - read formatted input from stdin
; supports: %s %d %c
; rcx = format string
; rdx, r8, r9... = pointers to store results
; returns rax = number of items read
;----------------------------------------------------------
global scanf
scanf:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64

    mov r12, rcx
    mov [rbp - 64], rdx
    mov [rbp - 56], r8
    mov [rbp - 48], r9
    xor r13, r13        ; arg index
    xor r14, r14        ; items read

    mov rcx, -10
    call GetStdHandle
    mov rbx, rax        ; stdin handle

    mov rcx, rbx
    lea rdx, [io_buf]
    mov r8, 63
    lea r9, [io_read]
    mov qword [rsp + 32], 0
    call ReadFile
    test rax, rax
    jz .sc_done
    mov eax, [io_read]
    cmp eax, 63
    jbe .sc_len_ok
    mov eax, 63
.sc_len_ok:
    lea r15, [io_buf]
    mov byte [r15 + rax], 0

.sc_next:
    movzx rax, byte [r12]
    test al, al
    jz  .sc_done
    cmp al, '%'
    jne .sc_skip_fmt
    inc r12
    movzx rax, byte [r12]
    inc r12

    cmp al, 'd'
    je  .sc_int
    cmp al, 's'
    je  .sc_string
    cmp al, 'c'
    je  .sc_char
    jmp .sc_next

.sc_skip_fmt:
    cmp al, ' '
    je .sc_skip_input_ws
    cmp al, 9
    je .sc_skip_input_ws
    cmp al, 10
    je .sc_skip_input_ws
    cmp al, 13
    je .sc_skip_input_ws
    inc r12
    jmp .sc_next
.sc_skip_input_ws:
    inc r12
.sc_skip_input_loop:
    mov al, [r15]
    cmp al, ' '
    je .sc_skip_input_one
    cmp al, 9
    je .sc_skip_input_one
    cmp al, 10
    je .sc_skip_input_one
    cmp al, 13
    jne .sc_next
.sc_skip_input_one:
    inc r15
    jmp .sc_skip_input_loop

.sc_char:
    call .sc_get_arg
    mov r11, rax
    mov al, [r15]
    test al, al
    jz .sc_done
    mov [r11], al
    inc r15
    inc r14
    jmp .sc_next

.sc_string:
    call .sc_get_arg
    mov r11, rax
    xor r10, r10
.sc_str_skip:
    mov al, [r15]
    cmp al, ' '
    je .sc_str_skip_one
    cmp al, 9
    je .sc_str_skip_one
    cmp al, 10
    je .sc_str_skip_one
    cmp al, 13
    jne .sc_str_loop
.sc_str_skip_one:
    inc r15
    jmp .sc_str_skip
.sc_str_loop:
    mov al, [r15]
    test al, al
    jz .sc_str_done
    cmp al, ' '
    je  .sc_str_done
    cmp al, 9
    je  .sc_str_done
    cmp al, 0x0A
    je  .sc_str_done
    cmp al, 0x0D
    je  .sc_str_done
    mov byte [r11 + r10], al
    inc r10
    inc r15
    jmp .sc_str_loop
.sc_str_done:
    mov byte [r11 + r10], 0
    inc r14
    jmp .sc_next

.sc_int:
    call .sc_get_arg
    mov r11, rax
    xor r10, r10        ; result
    xor rbx, rbx        ; negative flag
.sc_int_skip:
    mov al, [r15]
    cmp al, ' '
    je .sc_int_skip_one
    cmp al, 9
    je .sc_int_skip_one
    cmp al, 10
    je .sc_int_skip_one
    cmp al, 13
    jne .sc_int_sign
.sc_int_skip_one:
    inc r15
    jmp .sc_int_skip
.sc_int_sign:
    cmp al, '-'
    jne .sc_int_loop
    mov rbx, 1
    inc r15
.sc_int_loop:
    movzx rax, byte [r15]
    cmp al, '0'
    jl  .sc_int_done
    cmp al, '9'
    jg  .sc_int_done
    sub al, '0'
    imul r10, 10
    add r10, rax
    inc r15
    jmp .sc_int_loop
.sc_int_done:
    test rbx, rbx
    jz  .sc_int_store
    neg r10
.sc_int_store:
    mov [r11], r10d
    inc r14
    jmp .sc_next

.sc_done:
    mov rax, r14
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.sc_get_arg:
    cmp r13, 0
    je  .sc_a0
    cmp r13, 1
    je  .sc_a1
    cmp r13, 2
    je  .sc_a2
    mov rax, r13
    sub rax, 3
    imul rax, 8
    add rax, 48
    mov rax, [rbp + rax]
    inc r13
    ret
.sc_a0:
    mov rax, [rbp - 64]
    inc r13
    ret
.sc_a1:
    mov rax, [rbp - 56]
    inc r13
    ret
.sc_a2:
    mov rax, [rbp - 48]
    inc r13
    ret

;----------------------------------------------------------
; scanf_s - currently compatible with scanf for %d and simple %s/%c.
; NOTE: Microsoft scanf_s size arguments for %s/%c are not consumed yet.
;----------------------------------------------------------
global scanf_s
scanf_s:
    jmp scanf

; userlib/win64/file.asm
; Windows x64 - Microsoft calling convention

extern CreateFileA
extern CloseHandle
extern ReadFile
extern WriteFile
extern SetFilePointer
extern GetFileSize
extern DeleteFileA
extern MoveFileA
extern GetTempFileNameA
extern GetTempPathA
extern FlushFileBuffers

section .data
file_written    dd 0
file_read       dd 0

; FILE struct layout (64 bytes)
; offset 0  : handle (8 bytes)
; offset 8  : flags  (8 bytes) - 1=read 2=write 4=eof 8=error
; offset 16 : ungetc_buf (8 bytes) - -1 if empty
; offset 24 : reserved (40 bytes)

FILE_SIZE       equ 64
FLAG_READ       equ 1
FLAG_WRITE      equ 2
FLAG_EOF        equ 4
FLAG_ERROR      equ 8
INVALID_HANDLE  equ -1

section .text

;----------------------------------------------------------
; internal - allocate a FILE struct
; returns rax = pointer to FILE or 0 on failure
;----------------------------------------------------------
extern malloc
extern free
extern strcmp

_file_alloc:
    sub rsp, 40
    mov rcx, FILE_SIZE
    call malloc
    test rax, rax
    jz  .fail
    mov [rsp + 32], rax
    mov rcx, rax
    xor rdx, rdx
    mov r8, FILE_SIZE
    call memset
    mov rax, [rsp + 32]
    mov qword [rax + 16], -1
    add rsp, 40
    ret
.fail:
    xor rax, rax
    add rsp, 40
    ret

extern memset

;----------------------------------------------------------
; fopen - open a file
; rcx = filename
; rdx = mode ("r", "w", "a", "rb", "wb", "r+", "w+")
; returns rax = FILE* or 0 on failure
;----------------------------------------------------------
global fopen
fopen:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 72

    mov r12, rcx        ; filename
    mov r13, rdx        ; mode

    ; parse mode
    xor r14, r14        ; access flags
    xor r15, r15        ; file struct flags

    movzx rax, byte [r13]
    cmp al, 'r'
    je  .mode_read
    cmp al, 'w'
    je  .mode_write
    cmp al, 'a'
    je  .mode_append
    jmp .fail

.mode_read:
    mov r14, 0x80000000 ; GENERIC_READ
    or  r15, FLAG_READ
    jmp .open_file

.mode_write:
    mov r14, 0x40000000 ; GENERIC_WRITE
    or  r15, FLAG_WRITE
    jmp .open_file

.mode_append:
    mov r14, 0x40000000
    or  r15, FLAG_WRITE
    jmp .open_file

.open_file:
    ; check for r+ or w+
    movzx rax, byte [r13 + 1]
    cmp al, '+'
    jne .do_open
    or  r14d, 0x80000000
    or  r14, 0x40000000
    or  r15, FLAG_READ
    or  r15, FLAG_WRITE

.do_open:
    mov rcx, r12        ; filename
    mov rdx, r14        ; access
    xor r8, r8          ; share mode = 0
    xor r9, r9          ; security = NULL
    ; creation disposition
    test r15, FLAG_WRITE
    jnz .create_always
    mov [rsp + 32], dword 3     ; OPEN_EXISTING
    jmp .call_create
.create_always:
    mov [rsp + 32], dword 2     ; CREATE_ALWAYS
.call_create:
    mov [rsp + 40], dword 0x80  ; FILE_ATTRIBUTE_NORMAL
    mov qword [rsp + 48],  0     ; template = NULL
    call CreateFileA
    cmp rax, INVALID_HANDLE
    je  .fail

    push rax            ; save handle
    call _file_alloc
    test rax, rax
    jz  .fail_free_handle

    pop rbx             ; handle
    mov [rax], rbx      ; store handle
    mov [rax + 8], r15  ; store flags

    ; if append mode, seek to end
    movzx rcx, byte [r13]
    cmp cl, 'a'
    jne .done
    push rax
    mov rcx, rbx
    xor rdx, rdx
    xor r8, r8
    mov r9, 2           ; FILE_END
    call SetFilePointer
    pop rax

.done:
    add rsp, 72
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.fail_free_handle:
    pop rbx
    mov rcx, rbx
    call CloseHandle
.fail:
    xor rax, rax
    add rsp, 72
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

;----------------------------------------------------------
; fopen_s - open file and store FILE*
; rcx = FILE **out
; rdx = filename
; r8  = mode
; returns rax = 0 on success, -1 on failure
;----------------------------------------------------------
global fopen_s
fopen_s:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 40
    test rcx, rcx
    jz .fs_fail
    mov rbx, rcx
    mov rcx, rdx
    mov rdx, r8
    call fopen
    test rax, rax
    jz .fs_fail
    mov [rbx], rax
    xor eax, eax
    add rsp, 40
    pop rbx
    pop rbp
    ret
.fs_fail:
    mov rax, -1
    add rsp, 40
    pop rbx
    pop rbp
    ret

;----------------------------------------------------------
; fclose - close a file
; rcx = FILE*
; returns rax = 0 on success, -1 on failure
;----------------------------------------------------------
global fclose
fclose:
    push rbx
    mov rbx, rcx
    test rbx, rbx
    jz  .fail
    mov rcx, [rbx]      ; handle
    call CloseHandle
    test rax, rax
    jz  .fail
    mov rcx, rbx
    call free
    xor rax, rax
    pop rbx
    ret
.fail:
    or rax, -1
    pop rbx
    ret

;----------------------------------------------------------
; fread - read from file
; rcx = buffer
; rdx = element size
; r8  = count
; r9  = FILE*
; returns rax = number of elements read
;----------------------------------------------------------
global fread
fread:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rcx        ; buffer
    mov r13, rdx        ; element size
    mov r14, r8         ; count
    mov rbx, r9         ; FILE*

    ; check ungetc buffer
    mov rax, [rbx + 16]
    cmp rax, -1
    je  .no_ungetc
    mov byte [r12], al
    mov qword [rbx + 16], -1
    inc r12
    dec r14
    test r14, r14
    jz  .one_item
.no_ungetc:
    imul r14, r13       ; total bytes = count * size
    mov rcx, [rbx]      ; handle
    mov rdx, r12        ; buffer
    mov r8, r14         ; bytes to read
    lea r9, [file_read]
    sub rsp, 40
    mov qword [rsp + 32], 0
    call ReadFile
    add rsp, 40
    test rax, rax
    jz  .eof
    mov rax, [file_read]
    xor rdx, rdx
    div r13             ; rax = elements read
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.eof:
    or  qword [rbx + 8], FLAG_EOF
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.one_item:
    mov rax, 1
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

;----------------------------------------------------------
; fwrite - write to file
; rcx = buffer
; rdx = element size
; r8  = count
; r9  = FILE*
; returns rax = number of elements written
;----------------------------------------------------------
global fwrite
fwrite:
    push rbx
    push r12
    push r13
    mov r12, rcx        ; buffer
    mov r13, rdx        ; element size
    mov rbx, r9         ; FILE*

    imul r8, rdx        ; total bytes
    mov rcx, [rbx]      ; handle
    mov rdx, r12
    lea r9, [file_written]
    sub rsp, 48
    mov qword [rsp + 32], 0
    call WriteFile
    add rsp, 48
    test rax, rax
    jz  .fail
    mov rax, [file_written]
    xor rdx, rdx
    div r13
    pop r13
    pop r12
    pop rbx
    ret
.fail:
    or  qword [rbx + 8], FLAG_ERROR
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret

;----------------------------------------------------------
; fgetc - read single character from file
; rcx = FILE*
; returns rax = character or -1 on EOF/error
;----------------------------------------------------------
global fgetc
fgetc:
    push rbx
    mov rbx, rcx
    ; check ungetc buffer
    mov rax, [rbx + 16]
    cmp rax, -1
    je  .read_char
    mov qword [rbx + 16], -1
    pop rbx
    ret
.read_char:
    sub rsp, 8
    mov rcx, [rbx]
    lea rdx, [rsp]
    mov r8, 1
    lea r9, [file_read]
    sub rsp, 40
    mov qword [rsp + 32], 0
    call ReadFile
    add rsp, 40
    test rax, rax
    jz  .eof
    movzx rax, byte [rsp]
    add rsp, 8
    pop rbx
    ret
.eof:
    or  qword [rbx + 8], FLAG_EOF
    add rsp, 8
    or rax, -1
    pop rbx
    ret

;----------------------------------------------------------
; fputc - write single character to file
; rcx = character
; rdx = FILE*
; returns rax = character written or -1 on failure
;----------------------------------------------------------
global fputc
fputc:
    push rbx
    push r12
    mov r12, rcx
    mov rbx, rdx
    sub rsp, 8
    mov byte [rsp], r12b
    mov rcx, [rbx]
    lea rdx, [rsp]
    mov r8, 1
    lea r9, [file_written]
    sub rsp, 48
    mov qword [rsp + 32], 0
    call WriteFile
    add rsp, 48
    test rax, rax
    jz  .fail
    movzx rax, r12b
    add rsp, 8
    pop r12
    pop rbx
    ret
.fail:
    add rsp, 8
    or rax, -1
    pop r12
    pop rbx
    ret

;----------------------------------------------------------
; fgets - read line from file
; rcx = buffer
; rdx = max size
; r8  = FILE*
; returns rax = buffer or 0 on EOF/error
;----------------------------------------------------------
global fgets
fgets:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rcx        ; buffer
    mov r13, rdx        ; max size
    mov rbx, r8         ; FILE*
    xor r14, r14        ; chars read
    dec r13             ; leave room for null

.loop:
    cmp r14, r13
    jge .done
    mov rcx, rbx
    call fgetc
    cmp rax, -1
    je  .eof_check
    mov byte [r12 + r14], al
    inc r14
    cmp al, 0x0A
    je  .done
    jmp .loop

.done:
    mov byte [r12 + r14], 0
    mov rax, r12
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.eof_check:
    test r14, r14
    jz  .fail
    jmp .done

.fail:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

;----------------------------------------------------------
; fputs - write string to file
; rcx = string
; rdx = FILE*
; returns rax = 0 on success, -1 on failure
;----------------------------------------------------------
global fputs
fputs:
    push rbx
    push r12
    mov r12, rdx        ; FILE*
    push rcx
    call strlen
    mov r8, rax
    pop rdx
    mov rcx, rdx
    mov rdx, 1
    mov r9, r12
    call fwrite
    test rax, rax
    jz  .fail
    xor rax, rax
    pop r12
    pop rbx
    ret
.fail:
    or rax, -1
    pop r12
    pop rbx
    ret

;----------------------------------------------------------
; ungetc - push character back into file buffer
; rcx = character
; rdx = FILE*
; returns rax = character or -1 on failure
;----------------------------------------------------------
global ungetc
ungetc:
    cmp rcx, -1
    je  .fail
    mov [rdx + 16], rcx
    mov rax, rcx
    ret
.fail:
    or rax, -1
    ret

;----------------------------------------------------------
; fseek - move file pointer
; rcx = FILE*
; rdx = offset
; r8  = whence (0=begin 1=current 2=end)
; returns rax = 0 on success, -1 on failure
;----------------------------------------------------------
global fseek
fseek:
    push rbx
    mov rbx, rcx
    mov rcx, [rbx]
    ; clear ungetc buffer
    mov qword [rbx + 16], -1
    ; clear EOF flag
    and qword [rbx + 8], ~FLAG_EOF
    call SetFilePointer
    cmp rax, -1
    je  .fail
    xor rax, rax
    pop rbx
    ret
.fail:
    or rax, -1
    pop rbx
    ret

;----------------------------------------------------------
; ftell - get file pointer position
; rcx = FILE*
; returns rax = position or -1 on failure
;----------------------------------------------------------
global ftell
ftell:
    mov rcx, [rcx]
    xor rdx, rdx
    xor r8, r8
    mov r9, 1           ; FILE_CURRENT
    call SetFilePointer
    ret

;----------------------------------------------------------
; rewind - seek to beginning of file
; rcx = FILE*
;----------------------------------------------------------
global rewind
rewind:
    push rbx
    mov rbx, rcx
    xor rdx, rdx
    xor r8, r8
    call fseek
    and qword [rbx + 8], ~FLAG_EOF
    pop rbx
    ret

;----------------------------------------------------------
; feof - check end of file
; rcx = FILE*
; returns rax = nonzero if EOF
;----------------------------------------------------------
global feof
feof:
    mov rax, [rcx + 8]
    and rax, FLAG_EOF
    ret

;----------------------------------------------------------
; ferror - check file error flag
; rcx = FILE*
; returns rax = nonzero if error
;----------------------------------------------------------
global ferror
ferror:
    mov rax, [rcx + 8]
    and rax, FLAG_ERROR
    ret

;----------------------------------------------------------
; fflush - flush file buffer (no-op, WriteFile is unbuffered)
; rcx = FILE*
; returns rax = 0
;----------------------------------------------------------
global fflush
fflush:
    test rcx, rcx
    jz  .done
    mov rcx, [rcx]
    call FlushFileBuffers
.done:
    xor rax, rax
    ret

;----------------------------------------------------------
; remove - delete a file
; rcx = filename
; returns rax = 0 on success, -1 on failure
;----------------------------------------------------------
global remove
remove:
    call DeleteFileA
    test rax, rax
    jz  .fail
    xor rax, rax
    ret
.fail:
    or rax, -1
    ret

;----------------------------------------------------------
; rename - rename a file
; rcx = old name
; rdx = new name
; returns rax = 0 on success, -1 on failure
;----------------------------------------------------------
global rename
rename:
    call MoveFileA
    test rax, rax
    jz  .fail
    xor rax, rax
    ret
.fail:
    or rax, -1
    ret

;----------------------------------------------------------
; tmpfile - create and open a temporary file
; returns rax = FILE* or 0 on failure
;----------------------------------------------------------
global tmpfile
tmpfile:
    push rbx
    push r12
    sub rsp, 520        ; MAX_PATH * 2

    lea rcx, [rsp]
    mov rdx, 260
    call GetTempPathA

    lea rcx, [rsp]          ; path
    lea rdx, [rsp + 260]    ; prefix
    mov byte [rdx], 't'
    mov byte [rdx+1], 'm'
    mov byte [rdx+2], 'p'
    mov byte [rdx+3], 0
    xor r8, r8              ; unique = 0
    lea r9, [rsp + 264]     ; result buffer
    call GetTempFileNameA
    test rax, rax
    jz  .fail

    lea rcx, [rsp + 264]
    lea rdx, [rsp + 524]    ; mode string "w+b"
    mov byte [rdx],   'w'
    mov byte [rdx+1], '+'
    mov byte [rdx+2], 'b'
    mov byte [rdx+3], 0
    call fopen

    add rsp, 520
    pop r12
    pop rbx
    ret
.fail:
    xor rax, rax
    add rsp, 520
    pop r12
    pop rbx
    ret
