; complex.asm - complex helpers, SysV x86-64 ABI
; complex double layout: [real: qword][imag: qword]
default rel
%macro COMPLEX_MUL_XMM 7
    movapd %7, %3
    mulsd %7, %5
    movapd %1, %4
    mulsd %1, %6
    subsd %7, %1
    movapd %1, %3
    mulsd %1, %6
    movapd %2, %4
    mulsd %2, %5
    addsd %2, %1
    movapd %1, %7
%endmacro
%macro COMPLEX_MUL_MEM 3
    movsd xmm0, [%2]
    movsd xmm1, [%2+8]
    movsd xmm2, [%3]
    movsd xmm3, [%3+8]
    COMPLEX_MUL_XMM xmm4, xmm0, xmm0, xmm1, xmm2, xmm3, xmm5
    movsd [%1], xmm4
    movsd [%1+8], xmm0
%endmacro
section .data
_neg_mask dq 0x8000000000000000,0
section .text
global complex_set, complex_real, complex_imag, complex_add, complex_sub, complex_mul, complex_div, complex_conj, complex_norm, complex_equal
complex_set:
    movsd [rdi], xmm0
    movsd [rdi+8], xmm1
    mov rax, rdi
    ret
complex_real: movsd xmm0, [rdi]
    ret
complex_imag: movsd xmm0, [rdi+8]
    ret
complex_add:
    movsd xmm0, [rsi]
    addsd xmm0, [rdx]
    movsd [rdi], xmm0
    movsd xmm1, [rsi+8]
    addsd xmm1, [rdx+8]
    movsd [rdi+8], xmm1
    mov rax, rdi
    ret
complex_sub:
    movsd xmm0, [rsi]
    subsd xmm0, [rdx]
    movsd [rdi], xmm0
    movsd xmm1, [rsi+8]
    subsd xmm1, [rdx+8]
    movsd [rdi+8], xmm1
    mov rax, rdi
    ret
complex_mul:
    COMPLEX_MUL_MEM rdi, rsi, rdx
    mov rax, rdi
    ret
complex_div:
    movsd xmm0, [rsi]
    movsd xmm1, [rsi+8]
    movsd xmm2, [rdx]
    movsd xmm3, [rdx+8]
    movapd xmm4, xmm2
    mulsd xmm4, xmm2
    movapd xmm5, xmm3
    mulsd xmm5, xmm3
    addsd xmm4, xmm5
    movapd xmm5, xmm0
    mulsd xmm5, xmm2
    movapd xmm6, xmm1
    mulsd xmm6, xmm3
    addsd xmm5, xmm6
    divsd xmm5, xmm4
    movsd [rdi], xmm5
    mulsd xmm1, xmm2
    mulsd xmm0, xmm3
    subsd xmm1, xmm0
    divsd xmm1, xmm4
    movsd [rdi+8], xmm1
    mov rax, rdi
    ret
complex_conj:
    movsd xmm0, [rsi]
    movsd [rdi], xmm0
    movsd xmm0, [rsi+8]
    xorpd xmm0, [_neg_mask]
    movsd [rdi+8], xmm0
    mov rax, rdi
    ret
complex_norm:
    movsd xmm0, [rdi]
    movsd xmm1, [rdi+8]
    mulsd xmm0, xmm0
    mulsd xmm1, xmm1
    addsd xmm0, xmm1
    ret
complex_equal:
    movsd xmm0, [rdi]
    ucomisd xmm0, [rsi]
    jne .no
    jp .no
    movsd xmm0, [rdi+8]
    ucomisd xmm0, [rsi+8]
    jne .no
    jp .no
    mov eax, 1
    ret
.no: xor eax, eax
    ret