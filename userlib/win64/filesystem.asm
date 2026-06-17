; userlib/win64/filesystem.asm
; Windows x64 - <filesystem>-style helpers for ASM code
default rel

; Fast path parsing macros for ASM callers.
; FILESYSTEM_FILENAME_PTR out, path, tmp
; out = pointer to filename portion. Does not copy.
%macro FILESYSTEM_FILENAME_PTR 3
    mov %2, %2
    mov %1, %2
%%scan:
    mov al, [%2]
    test al, al
    jz %%done
    cmp al, '/'
    je %%sep
    cmp al, '\'
    je %%sep
    inc %2
    jmp %%scan
%%sep:
    lea %1, [%2 + 1]
    inc %2
    jmp %%scan
%%done:
%endmacro

; FILESYSTEM_EXTENSION_PTR out, path, scan
; out = pointer to extension including '.', or 0 if none.
%macro FILESYSTEM_EXTENSION_PTR 3
    xor %1, %1
    mov %3, %2
%%scan:
    mov al, [%3]
    test al, al
    jz %%done
    cmp al, '/'
    je %%reset
    cmp al, '\'
    je %%reset
    cmp al, '.'
    jne %%next
    mov %1, %3
%%next:
    inc %3
    jmp %%scan
%%reset:
    xor %1, %1
    inc %3
    jmp %%scan
%%done:
%endmacro

extern GetFileAttributesA
extern CreateDirectoryA
extern RemoveDirectoryA
extern DeleteFileA
extern MoveFileA
extern CopyFileA
extern CreateFileA
extern GetFileSizeEx
extern CloseHandle
extern GetCurrentDirectoryA
extern GetFullPathNameA
extern GetTempPathA
extern GetFileTime
extern SetCurrentDirectoryA

INVALID_FILE_ATTRIBUTES equ 0FFFFFFFFh
FILE_ATTRIBUTE_DIRECTORY equ 10h

section .text

; filesystem_exists(path) -> eax 1/0
global filesystem_exists
filesystem_exists:
    sub rsp, 40
    call GetFileAttributesA
    cmp eax, INVALID_FILE_ATTRIBUTES
    setne al
    movzx eax, al
    add rsp, 40
    ret

; filesystem_is_directory(path) -> eax 1/0
global filesystem_is_directory
filesystem_is_directory:
    sub rsp, 40
    call GetFileAttributesA
    cmp eax, INVALID_FILE_ATTRIBUTES
    je .no
    test eax, FILE_ATTRIBUTE_DIRECTORY
    setnz al
    movzx eax, al
    add rsp, 40
    ret
.no:
    xor eax, eax
    add rsp, 40
    ret

; filesystem_is_regular_file(path) -> eax 1/0
global filesystem_is_regular_file
filesystem_is_regular_file:
    sub rsp, 40
    call GetFileAttributesA
    cmp eax, INVALID_FILE_ATTRIBUTES
    je .no
    test eax, FILE_ATTRIBUTE_DIRECTORY
    setz al
    movzx eax, al
    add rsp, 40
    ret
.no:
    xor eax, eax
    add rsp, 40
    ret

; filesystem_create_directory(path) -> eax 0 success, -1 failure
global filesystem_create_directory
filesystem_create_directory:
    sub rsp, 40
    xor edx, edx
    call CreateDirectoryA
    test eax, eax
    jz .fail
    xor eax, eax
    add rsp, 40
    ret
.fail:
    or rax, -1
    add rsp, 40
    ret

; filesystem_remove_file(path) -> eax 0 success, -1 failure
global filesystem_remove_file
filesystem_remove_file:
    sub rsp, 40
    call DeleteFileA
    test eax, eax
    jz .fail
    xor eax, eax
    add rsp, 40
    ret
.fail:
    or rax, -1
    add rsp, 40
    ret

; filesystem_remove_directory(path) -> eax 0 success, -1 failure
global filesystem_remove_directory
filesystem_remove_directory:
    sub rsp, 40
    call RemoveDirectoryA
    test eax, eax
    jz .fail
    xor eax, eax
    add rsp, 40
    ret
.fail:
    or rax, -1
    add rsp, 40
    ret

; filesystem_rename(old_path, new_path) -> eax 0 success, -1 failure
global filesystem_rename
filesystem_rename:
    sub rsp, 40
    call MoveFileA
    test eax, eax
    jz .fail
    xor eax, eax
    add rsp, 40
    ret
.fail:
    or rax, -1
    add rsp, 40
    ret

; filesystem_copy_file(src, dst, fail_if_exists) -> eax 0 success, -1 failure
global filesystem_copy_file
filesystem_copy_file:
    sub rsp, 40
    call CopyFileA
    test eax, eax
    jz .fail
    xor eax, eax
    add rsp, 40
    ret
.fail:
    or rax, -1
    add rsp, 40
    ret

; filesystem_file_size(path, uint64_out) -> eax 0 success, -1 failure
; opens path read-only, queries size, closes handle.
global filesystem_file_size
filesystem_file_size:
    sub rsp, 88
    mov [rsp + 72], rdx
    xor edx, edx                    ; desired access = 0 (metadata)
    mov r8d, 1                      ; FILE_SHARE_READ
    xor r9d, r9d                    ; security attrs = NULL
    mov qword [rsp + 32], 3         ; OPEN_EXISTING
    mov qword [rsp + 40], 80h       ; FILE_ATTRIBUTE_NORMAL
    mov qword [rsp + 48], 0         ; template = NULL
    call CreateFileA
    cmp rax, -1
    je .fail
    mov [rsp + 80], rax
    mov rcx, rax
    lea rdx, [rsp + 64]
    call GetFileSizeEx
    test eax, eax
    jz .close_fail
    mov rcx, [rsp + 80]
    call CloseHandle
    mov rdx, [rsp + 72]
    mov rax, [rsp + 64]
    mov [rdx], rax
    xor eax, eax
    add rsp, 88
    ret
.close_fail:
    mov rcx, [rsp + 80]
    call CloseHandle
.fail:
    or rax, -1
    add rsp, 88
    ret

; filesystem_current_path(buffer, size) -> eax length, 0 failure
global filesystem_current_path
filesystem_current_path:
    sub rsp, 40
    mov r8, rcx
    mov ecx, edx
    mov rdx, r8
    call GetCurrentDirectoryA
    add rsp, 40
    ret

; filesystem_set_current_path(path) -> eax 0 success, -1 failure
global filesystem_set_current_path
filesystem_set_current_path:
    sub rsp, 40
    call SetCurrentDirectoryA
    test eax, eax
    jz .fail
    xor eax, eax
    add rsp, 40
    ret
.fail:
    or rax, -1
    add rsp, 40
    ret
; filesystem_absolute(path, buffer, size) -> eax length, 0 failure
; rcx = path, rdx = buffer, r8 = buffer size
global filesystem_absolute
filesystem_absolute:
    sub rsp, 40
    mov r9, rdx
    mov edx, r8d
    mov r8, r9
    xor r9d, r9d
    call GetFullPathNameA
    add rsp, 40
    ret

; filesystem_temp_directory_path(buffer, size) -> eax length, 0 failure
; rcx = buffer, rdx = size
global filesystem_temp_directory_path
filesystem_temp_directory_path:
    sub rsp, 40
    mov r8, rcx
    mov ecx, edx
    mov rdx, r8
    call GetTempPathA
    add rsp, 40
    ret

; filesystem_last_write_time(path, FILETIME_out) -> eax 0 success, -1 failure
; FILETIME_out receives 64-bit Windows FILETIME.
global filesystem_last_write_time
filesystem_last_write_time:
    sub rsp, 88
    mov [rsp + 64], rdx
    xor edx, edx                    ; desired access = metadata only
    mov r8d, 7                      ; share read/write/delete
    xor r9d, r9d
    mov qword [rsp + 32], 3         ; OPEN_EXISTING
    mov qword [rsp + 40], 80h       ; FILE_ATTRIBUTE_NORMAL
    mov qword [rsp + 48], 0
    call CreateFileA
    cmp rax, -1
    je .fail
    mov [rsp + 72], rax
    mov rcx, rax
    xor edx, edx
    xor r8d, r8d
    mov r9, [rsp + 64]
    call GetFileTime
    test eax, eax
    jz .close_fail
    mov rcx, [rsp + 72]
    call CloseHandle
    xor eax, eax
    add rsp, 88
    ret
.close_fail:
    mov rcx, [rsp + 72]
    call CloseHandle
.fail:
    or rax, -1
    add rsp, 88
    ret

; filesystem_filename(path, buffer, size) -> eax length, -1 if too small
; Copies the filename portion after the last slash/backslash.
global filesystem_filename
filesystem_filename:
    mov r9, rcx                     ; scan
    mov r10, rcx                    ; start of filename
.scan_name:
    mov al, [r9]
    test al, al
    jz .copy_name
    cmp al, '/'
    je .after_sep
    cmp al, '\'
    je .after_sep
    inc r9
    jmp .scan_name
.after_sep:
    lea r10, [r9 + 1]
    inc r9
    jmp .scan_name
.copy_name:
    xor r11d, r11d
.name_loop:
    mov al, [r10 + r11]
    cmp r11, r8
    jae .small
    mov [rdx + r11], al
    test al, al
    jz .name_done
    inc r11
    jmp .name_loop
.name_done:
    mov rax, r11
    ret
.small:
    or rax, -1
    ret

; filesystem_extension(path, buffer, size) -> eax length, -1 if too small
; Copies extension including '.', or empty string if none.
global filesystem_extension
filesystem_extension:
    mov r9, rcx
    xor r10d, r10d                  ; last dot
.scan_ext:
    mov al, [r9]
    test al, al
    jz .choose_ext
    cmp al, '/'
    je .reset_ext
    cmp al, '\'
    je .reset_ext
    cmp al, '.'
    jne .next_ext
    mov r10, r9
.next_ext:
    inc r9
    jmp .scan_ext
.reset_ext:
    xor r10d, r10d
    inc r9
    jmp .scan_ext
.choose_ext:
    test r10, r10
    jnz .copy_ext
    cmp r8, 0
    je .small
    mov byte [rdx], 0
    xor eax, eax
    ret
.copy_ext:
    xor r11d, r11d
.ext_loop:
    mov al, [r10 + r11]
    cmp r11, r8
    jae .small
    mov [rdx + r11], al
    test al, al
    jz .ext_done
    inc r11
    jmp .ext_loop
.ext_done:
    mov rax, r11
    ret
.small:
    or rax, -1
    ret

; filesystem_parent_path(path, buffer, size) -> eax length, -1 if too small
; Copies everything before the last slash/backslash.
global filesystem_parent_path
filesystem_parent_path:
    mov r9, rcx
    xor r10d, r10d                  ; last separator
.scan_parent:
    mov al, [r9]
    test al, al
    jz .copy_parent
    cmp al, '/'
    je .mark_parent
    cmp al, '\'
    je .mark_parent
    inc r9
    jmp .scan_parent
.mark_parent:
    mov r10, r9
    inc r9
    jmp .scan_parent
.copy_parent:
    test r10, r10
    jnz .has_parent
    cmp r8, 0
    je .small
    mov byte [rdx], 0
    xor eax, eax
    ret
.has_parent:
    mov r11, r10
    sub r11, rcx                    ; length
    cmp r11, r8
    jae .small
    xor r9d, r9d
.parent_loop:
    cmp r9, r11
    jae .parent_null
    mov al, [rcx + r9]
    mov [rdx + r9], al
    inc r9
    jmp .parent_loop
.parent_null:
    mov byte [rdx + r9], 0
    mov rax, r11
    ret
.small:
    or rax, -1
    ret
; filesystem_filename_ptr(path) -> char* inside path, no copy
global filesystem_filename_ptr
filesystem_filename_ptr:
    mov rax, rcx
.scan:
    mov dl, [rcx]
    test dl, dl
    jz .done
    cmp dl, '/'
    je .sep
    cmp dl, '\'
    je .sep
    inc rcx
    jmp .scan
.sep:
    lea rax, [rcx + 1]
    inc rcx
    jmp .scan
.done:
    ret

; filesystem_extension_ptr(path) -> char* inside path or 0, no copy
global filesystem_extension_ptr
filesystem_extension_ptr:
    xor eax, eax
.scan:
    mov dl, [rcx]
    test dl, dl
    jz .done
    cmp dl, '/'
    je .reset
    cmp dl, '\'
    je .reset
    cmp dl, '.'
    jne .next
    mov rax, rcx
.next:
    inc rcx
    jmp .scan
.reset:
    xor eax, eax
    inc rcx
    jmp .scan
.done:
    ret

; filesystem_parent_length(path) -> length before last slash/backslash
global filesystem_parent_length
filesystem_parent_length:
    mov r8, rcx
    xor eax, eax
.scan:
    mov dl, [rcx]
    test dl, dl
    jz .done
    cmp dl, '/'
    je .mark
    cmp dl, '\'
    je .mark
    inc rcx
    jmp .scan
.mark:
    mov rax, rcx
    sub rax, r8
    inc rcx
    jmp .scan
.done:
    ret