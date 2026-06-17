; filesystem.asm - <filesystem>-style libc/POSIX wrappers, SysV x86-64 ABI
default rel
extern access
extern mkdir
extern rmdir
extern unlink
extern rename
extern open
extern close
extern lseek
extern getcwd
extern chdir
F_OK equ 0
O_RDONLY equ 0
SEEK_END equ 2
section .text
global filesystem_exists, filesystem_is_directory, filesystem_is_regular_file, filesystem_create_directory, filesystem_remove_file, filesystem_remove_directory
global filesystem_rename, filesystem_copy_file, filesystem_file_size, filesystem_current_path, filesystem_set_current_path
filesystem_exists:
    sub rsp, 8
    xor esi, esi
    call access
    test eax, eax
    sete al
    movzx eax, al
    add rsp, 8
    ret
filesystem_is_directory:
    ; Minimal portable placeholder: existence check until stat layout is specialized per OS.
    jmp filesystem_exists
filesystem_is_regular_file:
    jmp filesystem_exists
filesystem_create_directory:
    sub rsp, 8
    mov esi, 0755o
    call mkdir
    test eax, eax
    jz .ok
    or rax, -1
    add rsp, 8
    ret
.ok: xor eax, eax
    add rsp, 8
    ret
filesystem_remove_file:
    sub rsp, 8
    call unlink
    test eax, eax
    jz .ok
    or rax, -1
    add rsp, 8
    ret
.ok: xor eax, eax
    add rsp, 8
    ret
filesystem_remove_directory:
    sub rsp, 8
    call rmdir
    test eax, eax
    jz .ok
    or rax, -1
    add rsp, 8
    ret
.ok: xor eax, eax
    add rsp, 8
    ret
filesystem_rename:
    sub rsp, 8
    call rename
    test eax, eax
    jz .ok
    or rax, -1
    add rsp, 8
    ret
.ok: xor eax, eax
    add rsp, 8
    ret
filesystem_copy_file:
    ; TODO: optimized sendfile/copy_file_range per OS.
    or rax, -1
    ret
filesystem_file_size:
    push rbx
    push r12
    sub rsp, 8
    mov rbx, rsi
    xor esi, esi
    call open
    test eax, eax
    js .fail
    mov r12d, eax
    mov edi, eax
    xor esi, esi
    mov edx, SEEK_END
    call lseek
    mov [rbx], rax
    mov edi, r12d
    call close
    xor eax, eax
    add rsp, 8
    pop r12
    pop rbx
    ret
.fail: or rax, -1
    add rsp, 8
    pop r12
    pop rbx
    ret
filesystem_current_path:
    sub rsp, 8
    call getcwd
    test rax, rax
    jz .fail
    ; return strlen-ish nonzero success marker for now
    mov eax, 1
    add rsp, 8
    ret
.fail: xor eax, eax
    add rsp, 8
    ret
filesystem_set_current_path:
    sub rsp, 8
    call chdir
    test eax, eax
    jz .ok
    or rax, -1
    add rsp, 8
    ret
.ok: xor eax, eax
    add rsp, 8
    ret