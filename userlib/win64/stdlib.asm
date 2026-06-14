; userlib/win64/stdlib.asm
; Windows x64 - Microsoft calling convention
; mirrors <stdlib.h>

extern GetProcessHeap
extern HeapAlloc
extern HeapFree
extern HeapReAlloc
extern GetEnvironmentVariableA
extern SetEnvironmentVariableA

section .data
_rand_seed      dq 12345678
_atexit_table   times 32 dq 0      ; max 32 atexit handlers
_atexit_count   dq 0

section .text

;----------------------------------------------------------
; malloc - allocate n bytes
; rcx = size
; returns rax = pointer or 0 on failure
;----------------------------------------------------------
global malloc
malloc:
    push rcx
    call GetProcessHeap
    pop r8
    mov rcx, rax
    xor rdx, rdx
    call HeapAlloc
    ret

;----------------------------------------------------------
; calloc - allocate n*size bytes zeroed
; rcx = count
; rdx = size
; returns rax = pointer or 0 on failure
;----------------------------------------------------------
global calloc
calloc:
    imul rcx, rdx
    push rcx
    call GetProcessHeap
    pop r8
    mov rcx, rax
    mov rdx, 8
    call HeapAlloc
    ret

;----------------------------------------------------------
; realloc - resize allocated block
; rcx = ptr
; rdx = new size
; returns rax = new pointer or 0 on failure
;----------------------------------------------------------
global realloc
realloc:
    test rcx, rcx
    jz  .alloc_new
    push rcx
    push rdx
    call GetProcessHeap
    pop r9
    mov r8, rcx
    mov rcx, rax
    xor rdx, rdx
    call HeapReAlloc
    ret
.alloc_new:
    call malloc
    ret

;----------------------------------------------------------
; free - free allocated block
; rcx = ptr
;----------------------------------------------------------
global free
free:
    test rcx, rcx
    jz  .done
    push rcx
    call GetProcessHeap
    pop r8
    mov rcx, rax
    xor rdx, rdx
    call HeapFree
.done:
    ret

;----------------------------------------------------------
; atoi - string to integer
; rcx = string
; returns rax = integer
;----------------------------------------------------------
global atoi
atoi:
    push rbx
    xor rax, rax
    xor rbx, rbx        ; negative flag
    ; skip whitespace
.skip_ws:
    movzx rdx, byte [rcx]
    cmp dl, ' '
    je  .ws_next
    cmp dl, 0x09
    je  .ws_next
    jmp .check_sign
.ws_next:
    inc rcx
    jmp .skip_ws
.check_sign:
    cmp dl, '-'
    jne .check_plus
    mov rbx, 1
    inc rcx
    jmp .digits
.check_plus:
    cmp dl, '+'
    jne .digits
    inc rcx
.digits:
    movzx rdx, byte [rcx]
    cmp dl, '0'
    jl  .done
    cmp dl, '9'
    jg  .done
    sub dl, '0'
    imul rax, 10
    add rax, rdx
    inc rcx
    jmp .digits
.done:
    test rbx, rbx
    jz  .positive
    neg rax
.positive:
    pop rbx
    ret

;----------------------------------------------------------
; atol - string to long (same as atoi on x64)
; rcx = string
; returns rax = long
;----------------------------------------------------------
global atol
atol:
    jmp atoi

;----------------------------------------------------------
; atof - string to double
; rcx = string
; returns xmm0 = double
;----------------------------------------------------------
global atof
atof:
    push rbx
    push r12
    push r13
    xorpd xmm0, xmm0
    xorpd xmm1, xmm1
    xor rbx, rbx        ; negative flag
    xor r12, r12        ; decimal seen
    xor r13, r13        ; decimal divisor

.af_skip_ws:
    movzx rax, byte [rcx]
    cmp al, ' '
    je  .af_ws_next
    cmp al, 0x09
    je  .af_ws_next
    jmp .af_sign
.af_ws_next:
    inc rcx
    jmp .af_skip_ws

.af_sign:
    cmp al, '-'
    jne .af_plus
    mov rbx, 1
    inc rcx
    jmp .af_digits
.af_plus:
    cmp al, '+'
    jne .af_digits
    inc rcx

.af_digits:
    movzx rax, byte [rcx]
    cmp al, '.'
    je  .af_dot
    cmp al, '0'
    jl  .af_done
    cmp al, '9'
    jg  .af_done
    sub al, '0'
    cvtsi2sd xmm2, rax
    mulsd xmm0, [.ten]
    addsd xmm0, xmm2
    test r12, r12
    jz  .af_no_dec
    mulsd xmm1, [.ten]
.af_no_dec:
    inc rcx
    jmp .af_digits

.af_dot:
    mov r12, 1
    movsd xmm1, [.one]
    inc rcx
    jmp .af_digits

.af_done:
    test r12, r12
    jz  .af_sign_check
    divsd xmm0, xmm1

.af_sign_check:
    test rbx, rbx
    jz  .af_pos
    xorpd xmm0, [.neg]
.af_pos:
    pop r13
    pop r12
    pop rbx
    ret

section .data
.ten    dq 10.0
.one    dq 1.0
.neg    dq 0x8000000000000000, 0

section .text

;----------------------------------------------------------
; itoa - integer to string
; rcx = value
; rdx = buffer
; r8  = base (10, 16, 2...)
; returns rax = buffer
;----------------------------------------------------------
global itoa
itoa:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdx        ; buffer
    mov r13, r8         ; base
    mov r14, rcx        ; value
    mov rax, r12

    test r14, r14
    jns .positive
    mov byte [r12], '-'
    inc r12
    neg r14

.positive:
    ; write digits in reverse
    lea rbx, [r12 + 20]
    mov byte [rbx], 0
    dec rbx
    mov rax, r14

.div_loop:
    xor rdx, rdx
    div r13
    cmp rdx, 9
    jle .digit
    add rdx, 'a' - 10
    jmp .store
.digit:
    add rdx, '0'
.store:
    mov byte [rbx], dl
    dec rbx
    test rax, rax
    jnz .div_loop

    ; copy from temp to buffer
    inc rbx
.copy:
    mov cl, byte [rbx]
    mov byte [r12], cl
    inc r12
    inc rbx
    test cl, cl
    jnz .copy

    mov rax, rdx        ; return original buffer start
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

;----------------------------------------------------------
; abs - absolute value of integer
; rcx = value
; returns rax = absolute value
;----------------------------------------------------------
global abs
abs:
    mov rax, rcx
    test rax, rax
    jns .done
    neg rax
.done:
    ret

;----------------------------------------------------------
; labs - absolute value of long (same as abs on x64)
; rcx = value
; returns rax = absolute value
;----------------------------------------------------------
global labs
labs:
    jmp abs

;----------------------------------------------------------
; rand - generate pseudo random number
; returns rax = random number 0..32767
;----------------------------------------------------------
global rand
rand:
    mov rax, [_rand_seed]
    imul rax, 6364136223846793005
    add rax, 1442695040888963407
    mov [_rand_seed], rax
    shr rax, 33
    and rax, 0x7FFF
    ret

;----------------------------------------------------------
; srand - seed random number generator
; rcx = seed
;----------------------------------------------------------
global srand
srand:
    mov [_rand_seed], rcx
    ret

;----------------------------------------------------------
; qsort - sort array
; rcx = base pointer
; rdx = number of elements
; r8  = element size
; r9  = compare function pointer (rcx=a, rdx=b, returns rax)
;----------------------------------------------------------
global qsort
qsort:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rdi
    push rsi
    sub rsp, 48

    mov r12, rcx        ; base
    mov r13, rdx        ; count
    mov r14, r8         ; size
    mov r15, r9         ; compare fn

    ; base case
    cmp r13, 1
    jle .qs_done

    ; partition around last element as pivot
    ; pivot = base + (count-1) * size
    mov rax, r13
    dec rax
    imul rax, r14
    add rax, r12        ; pivot pointer
    mov rdi, rax

    xor rbx, rbx        ; i = -1 (store index)
    xor rsi, rsi        ; j = 0

.qs_loop:
    cmp rsi, r13
    jge .qs_place_pivot

    ; compare base[j] with pivot
    mov rax, rsi
    imul rax, r14
    add rax, r12
    cmp rax, rdi
    je  .qs_next_j

    mov rcx, rax
    mov rdx, rdi
    call r15
    test rax, rax
    jge .qs_next_j

    ; swap base[i+1] with base[j]
    inc rbx
    mov rax, rbx
    imul rax, r14
    add rax, r12        ; &base[i]
    mov rcx, rax
    mov rax, rsi
    imul rax, r14
    add rax, r12        ; &base[j]
    mov rdx, rax
    mov r8, r14
    call .swap

.qs_next_j:
    inc rsi
    jmp .qs_loop

.qs_place_pivot:
    ; swap base[i+1] with pivot
    inc rbx
    mov rax, rbx
    imul rax, r14
    add rax, r12
    mov rcx, rax
    mov rdx, rdi
    mov r8, r14
    call .swap

    ; recurse left
    mov rcx, r12
    mov rdx, rbx
    mov r8, r14
    mov r9, r15
    call qsort

    ; recurse right
    mov rax, rbx
    inc rax
    imul rax, r14
    add rax, r12
    mov rcx, rax
    mov rdx, r13
    sub rdx, rbx
    dec rdx
    mov r8, r14
    mov r9, r15
    call qsort

.qs_done:
    add rsp, 48
    pop rsi
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; swap rcx and rdx, r8 bytes
.swap:
    push rbx
    push r12
    mov r12, r8
.sw_loop:
    mov al, byte [rcx]
    mov bl, byte [rdx]
    mov byte [rcx], bl
    mov byte [rdx], al
    inc rcx
    inc rdx
    dec r12
    jnz .sw_loop
    pop r12
    pop rbx
    ret

;----------------------------------------------------------
; bsearch - binary search
; rcx = key pointer
; rdx = base pointer
; r8  = number of elements
; r9  = element size
; [rsp+32] = compare function pointer
; returns rax = pointer to match or 0
;----------------------------------------------------------
global bsearch
bsearch:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 48

    mov r12, rcx        ; key
    mov r13, rdx        ; base
    mov r14, r8         ; count
    mov r15, r9         ; size
    mov rbx, [rbp + 48] ; compare fn

    xor rdi, rdi        ; lo = 0

.bs_loop:
    cmp rdi, r14
    jge .bs_notfound

    mov rax, rdi
    add rax, r14
    shr rax, 1          ; mid = (lo + hi) / 2

    push rax
    imul rax, r15
    add rax, r13        ; &base[mid]
    mov rcx, r12
    mov rdx, rax
    call rbx
    pop rax

    test rax, rax
    jz  .bs_found
    jl  .bs_right

    ; go left: hi = mid
    mov r14, rax
    jmp .bs_loop

.bs_right:
    ; go right: lo = mid + 1
    mov rdi, rax
    inc rdi
    jmp .bs_loop

.bs_found:
    imul rax, r15
    add rax, r13
    add rsp, 48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.bs_notfound:
    xor rax, rax
    add rsp, 48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

;----------------------------------------------------------
; getenv - get environment variable
; rcx = name
; returns rax = pointer to value or 0
;----------------------------------------------------------
global getenv
getenv:
    push rbx
    push r12
    mov r12, rcx

    ; get required size
    xor rdx, rdx
    xor r8, r8
    call GetEnvironmentVariableA
    test rax, rax
    jz  .fail

    push rax
    mov rcx, rax
    call malloc
    test rax, rax
    jz  .fail_pop
    mov rbx, rax

    pop r8
    mov rcx, r12
    mov rdx, rbx
    call GetEnvironmentVariableA
    test rax, rax
    jz  .fail_free

    mov rax, rbx
    pop r12
    pop rbx
    ret

.fail_pop:
    pop rax
.fail:
    xor rax, rax
    pop r12
    pop rbx
    ret

.fail_free:
    mov rcx, rbx
    call free
    xor rax, rax
    pop r12
    pop rbx
    ret

;----------------------------------------------------------
; setenv - set environment variable
; rcx = name
; rdx = value
; returns rax = 0 on success, -1 on failure
;----------------------------------------------------------
global setenv
setenv:
    call SetEnvironmentVariableA
    test rax, rax
    jz  .fail
    xor rax, rax
    ret
.fail:
    or rax, -1
    ret

;----------------------------------------------------------
; atexit - register function to call at exit
; rcx = function pointer
; returns rax = 0 on success, -1 if table full
;----------------------------------------------------------
global atexit
atexit:
    mov rax, [_atexit_count]
    cmp rax, 32
    jge .fail
    lea rdx, [_atexit_table + rax * 8]
    mov [rdx], rcx
    inc qword [_atexit_count]
    xor rax, rax
    ret
.fail:
    or rax, -1
    ret

;----------------------------------------------------------
; _run_atexit - internal: call all atexit handlers
; called by exit before ExitProcess
;----------------------------------------------------------
global _run_atexit
_run_atexit:
    push rbx
    mov rbx, [_atexit_count]
.loop:
    test rbx, rbx
    jz  .done
    dec rbx
    mov rax, [_atexit_table + rbx * 8]
    call rax
    jmp .loop
.done:
    pop rbx
    ret