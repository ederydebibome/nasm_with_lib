; userlib/win64/assert.asm
; Windows x64 - <assert.h>-style assertion helpers for ASM code
default rel

extern printf
extern abort

section .data
_assert_fmt db 'Assertion failed: %s, file %s, line %d', 10, 0
_assert_fmt_func db 'Assertion failed: %s, file %s, line %d, function %s', 10, 0
_assert_unknown db '<unknown>', 0
_assert_msg_fmt db 'Assertion failed: %s, message: %s, file %s, line %d', 10, 0

section .text

; assert_fail(expr, file, line, func) -> aborts
; rcx = expression string, rdx = file string, r8 = line, r9 = function string or NULL
global assert_fail
assert_fail:
    sub rsp, 56
    test rcx, rcx
    jnz .expr_ok
    lea rcx, [_assert_unknown]
.expr_ok:
    test rdx, rdx
    jnz .file_ok
    lea rdx, [_assert_unknown]
.file_ok:
    test r9, r9
    jz .no_func
    mov [rsp + 32], r9
    mov r9, r8
    mov r8, rdx
    mov rdx, rcx
    lea rcx, [_assert_fmt_func]
    call printf
    jmp .die
.no_func:
    mov r9, r8
    mov r8, rdx
    mov rdx, rcx
    lea rcx, [_assert_fmt]
    call printf
.die:
    call abort
    add rsp, 56
    ret

; assert_true(condition, expr, file, line) -> returns 0 if true, aborts if false
; rcx = condition, rdx = expression string, r8 = file string, r9 = line
global assert_true
assert_true:
    test rcx, rcx
    jz .fail
    xor eax, eax
    ret
.fail:
    sub rsp, 40
    mov rcx, rdx
    mov rdx, r8
    mov r8, r9
    xor r9d, r9d
    call assert_fail
    add rsp, 40
    ret
; assert_msg(condition, expr, message, file, line) -> returns 0 if true, aborts if false
; rcx = condition, rdx = expr, r8 = message, r9 = file, [rsp+40] = line
global assert_msg
assert_msg:
    test rcx, rcx
    jz .fail
    xor eax, eax
    ret
.fail:
    sub rsp, 56
    mov rax, [rsp + 96]
    mov [rsp + 32], rax
    mov rcx, _assert_msg_fmt
    ; after first arg: rdx expr, r8 message, r9 file, stack line already placed
    call printf
    call abort
    add rsp, 56
    ret