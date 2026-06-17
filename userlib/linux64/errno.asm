; errno.asm - <errno.h> helpers, process-local fast errno slot
default rel
section .data
_errno_value dd 0
section .text
global errno_location, _errno, __errno, get_errno, set_errno, clear_errno
errno_location: lea rax, [_errno_value]
    ret
_errno: lea rax, [_errno_value]
    ret
__errno: lea rax, [_errno_value]
    ret
get_errno: mov eax, [_errno_value]
    ret
set_errno: mov [_errno_value], edi
    mov eax, edi
    ret
clear_errno: xor eax, eax
    mov [_errno_value], eax
    ret