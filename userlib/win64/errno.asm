; userlib/win64/errno.asm
; Windows x64 - <errno.h>-style helpers
; Fast path uses one process-local errno slot. This keeps access extremely cheap.
default rel

extern puts

section .data
_errno_value dd 0
_err_unknown db 'Unknown error',0
_err_perm db 'Operation not permitted',0
_err_noent db 'No such file or directory',0
_err_intr db 'Interrupted function',0
_err_io db 'I/O error',0
_err_nomem db 'Not enough memory',0
_err_acces db 'Permission denied',0
_err_exist db 'File exists',0
_err_inval db 'Invalid argument',0
_err_range db 'Result too large',0

section .text

; errno_location() -> int*
global errno_location
errno_location:
    lea rax, [_errno_value]
    ret

; Common CRT spellings for errno address helpers.
global _errno
_errno:
    lea rax, [_errno_value]
    ret

global __errno
__errno:
    lea rax, [_errno_value]
    ret

; get_errno() -> eax
global get_errno
get_errno:
    mov eax, [_errno_value]
    ret

; set_errno(value) -> eax = value
global set_errno
set_errno:
    mov [_errno_value], ecx
    mov eax, ecx
    ret

; clear_errno() -> eax = 0
global clear_errno
clear_errno:
    xor eax, eax
    mov [_errno_value], eax
    ret
; strerror(errno) -> char*
global strerror
strerror:
    cmp ecx, 1
    je .perm
    cmp ecx, 2
    je .noent
    cmp ecx, 4
    je .intr
    cmp ecx, 5
    je .io
    cmp ecx, 12
    je .nomem
    cmp ecx, 13
    je .acces
    cmp ecx, 17
    je .exist
    cmp ecx, 22
    je .inval
    cmp ecx, 34
    je .range
    lea rax, [_err_unknown]
    ret
.perm: lea rax, [_err_perm]
    ret
.noent: lea rax, [_err_noent]
    ret
.intr: lea rax, [_err_intr]
    ret
.io: lea rax, [_err_io]
    ret
.nomem: lea rax, [_err_nomem]
    ret
.acces: lea rax, [_err_acces]
    ret
.exist: lea rax, [_err_exist]
    ret
.inval: lea rax, [_err_inval]
    ret
.range: lea rax, [_err_range]
    ret

; perror(prefix) -> prints strerror(errno). Prefix kept minimal for speed for now.
global perror
perror:
    sub rsp, 40
    mov ecx, [_errno_value]
    call strerror
    mov rcx, rax
    call puts
    add rsp, 40
    ret