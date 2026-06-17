; assert.asm - <assert.h> helpers, SysV x86-64 ABI
default rel
extern printf
extern abort
section .data
_fmt db 'Assertion failed: %s, file %s, line %d',10,0
_unknown db '<unknown>',0
section .text
global assert_fail, assert_true
assert_fail:
    sub rsp, 8
    test rdi, rdi
    jnz .expr_ok
    lea rdi, [_unknown]
.expr_ok:
    test rsi, rsi
    jnz .file_ok
    lea rsi, [_unknown]
.file_ok:
    mov rcx, rdx
    mov rdx, rsi
    mov rsi, rdi
    lea rdi, [_fmt]
    xor eax, eax
    call printf
    call abort
    add rsp, 8
    ret
assert_true:
    test rdi, rdi
    jz .fail
    xor eax, eax
    ret
.fail:
    mov rdi, rsi
    mov rsi, rdx
    mov rdx, rcx
    jmp assert_fail