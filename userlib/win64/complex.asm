; userlib/win64/complex.asm
; Windows x64 - C/C++ style complex helpers for ASM code
; complex double layout: [real: qword][imag: qword]
default rel
; Fast NASM macros for ASM callers. These avoid function-call overhead.
; Usage: COMPLEX_MUL_MEM out, a, b where each operand is a memory address
; containing {double real, double imag}.
%macro COMPLEX_ADD_MEM 3
    movsd xmm0, [%2]
    addsd xmm0, [%3]
    movsd [%1], xmm0
    movsd xmm1, [%2 + 8]
    addsd xmm1, [%3 + 8]
    movsd [%1 + 8], xmm1
%endmacro

%macro COMPLEX_SUB_MEM 3
    movsd xmm0, [%2]
    subsd xmm0, [%3]
    movsd [%1], xmm0
    movsd xmm1, [%2 + 8]
    subsd xmm1, [%3 + 8]
    movsd [%1 + 8], xmm1
%endmacro

%macro COMPLEX_MUL_MEM 3
    movsd xmm0, [%2]
    movsd xmm1, [%2 + 8]
    movsd xmm2, [%3]
    movsd xmm3, [%3 + 8]
    movapd xmm4, xmm0
    mulsd xmm4, xmm2
    movapd xmm5, xmm1
    mulsd xmm5, xmm3
    subsd xmm4, xmm5
    mulsd xmm0, xmm3
    mulsd xmm1, xmm2
    addsd xmm0, xmm1
    movsd [%1], xmm4
    movsd [%1 + 8], xmm0
%endmacro


; COMPLEX_MUL_XMM rr, ri, ar, ai, br, bi, tmp
; Computes (ar+i*ai)*(br+i*bi) into rr/ri using only XMM registers.
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
%macro COMPLEX_NORM_MEM 1
    movsd xmm0, [%1]
    movsd xmm1, [%1 + 8]
    mulsd xmm0, xmm0
    mulsd xmm1, xmm1
    addsd xmm0, xmm1
%endmacro

extern atan2
extern hypot

section .data
_cx_neg_mask dq 0x8000000000000000, 0

section .text

; complex_set(out, real, imag)
; rcx = out, xmm1 = real, xmm2 = imag
global complex_set
complex_set:
    movsd [rcx], xmm1
    movsd [rcx + 8], xmm2
    mov rax, rcx
    ret

; complex_real(z) -> xmm0
global complex_real
complex_real:
    movsd xmm0, [rcx]
    ret

; complex_imag(z) -> xmm0
global complex_imag
complex_imag:
    movsd xmm0, [rcx + 8]
    ret

; complex_add(out, a, b)
global complex_add
complex_add:
    movsd xmm0, [rdx]
    addsd xmm0, [r8]
    movsd [rcx], xmm0
    movsd xmm1, [rdx + 8]
    addsd xmm1, [r8 + 8]
    movsd [rcx + 8], xmm1
    mov rax, rcx
    ret

; complex_sub(out, a, b)
global complex_sub
complex_sub:
    movsd xmm0, [rdx]
    subsd xmm0, [r8]
    movsd [rcx], xmm0
    movsd xmm1, [rdx + 8]
    subsd xmm1, [r8 + 8]
    movsd [rcx + 8], xmm1
    mov rax, rcx
    ret

; complex_mul(out, a, b): (ar*br-ai*bi, ar*bi+ai*br)
global complex_mul
complex_mul:
    movsd xmm0, [rdx]
    movsd xmm1, [rdx + 8]
    movsd xmm2, [r8]
    movsd xmm3, [r8 + 8]
    movapd xmm4, xmm0
    mulsd xmm4, xmm2
    movapd xmm5, xmm1
    mulsd xmm5, xmm3
    subsd xmm4, xmm5
    movsd [rcx], xmm4
    mulsd xmm0, xmm3
    mulsd xmm1, xmm2
    addsd xmm0, xmm1
    movsd [rcx + 8], xmm0
    mov rax, rcx
    ret

; complex_div(out, a, b): ((a*conj(b)) / |b|^2)
global complex_div
complex_div:
    movsd xmm0, [rdx]       ; ar
    movsd xmm1, [rdx + 8]   ; ai
    movsd xmm2, [r8]        ; br
    movsd xmm3, [r8 + 8]    ; bi
    movapd xmm4, xmm2
    mulsd xmm4, xmm2
    movapd xmm5, xmm3
    mulsd xmm5, xmm3
    addsd xmm4, xmm5        ; denom
    movapd xmm5, xmm0
    mulsd xmm5, xmm2
    movapd xmm6, xmm1
    mulsd xmm6, xmm3
    addsd xmm5, xmm6
    divsd xmm5, xmm4
    movsd [rcx], xmm5
    mulsd xmm1, xmm2
    mulsd xmm0, xmm3
    subsd xmm1, xmm0
    divsd xmm1, xmm4
    movsd [rcx + 8], xmm1
    mov rax, rcx
    ret

; complex_conj(out, z)
global complex_conj
complex_conj:
    movsd xmm0, [rdx]
    movsd [rcx], xmm0
    movsd xmm0, [rdx + 8]
    xorpd xmm0, [_cx_neg_mask]
    movsd [rcx + 8], xmm0
    mov rax, rcx
    ret

; complex_abs(z) -> xmm0
global complex_abs
complex_abs:
    sub rsp, 40
    movsd xmm0, [rcx]
    movsd xmm1, [rcx + 8]
    call hypot
    add rsp, 40
    ret

; complex_arg(z) -> xmm0
global complex_arg
complex_arg:
    sub rsp, 40
    movsd xmm0, [rcx + 8]
    movsd xmm1, [rcx]
    call atan2
    add rsp, 40
    ret

; complex_norm(z) -> xmm0 = real^2 + imag^2
global complex_norm
complex_norm:
    movsd xmm0, [rcx]
    movsd xmm1, [rcx + 8]
    mulsd xmm0, xmm0
    mulsd xmm1, xmm1
    addsd xmm0, xmm1
    ret

; complex_equal(a,b) -> eax 1/0 exact compare
global complex_equal
complex_equal:
    movsd xmm0, [rcx]
    ucomisd xmm0, [rdx]
    jne .no
    jp .no
    movsd xmm0, [rcx + 8]
    ucomisd xmm0, [rdx + 8]
    jne .no
    jp .no
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret