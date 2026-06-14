; userlib/win64/string.asm
; Windows x64 - Microsoft calling convention

section .text

;----------------------------------------------------------
; strlen - string length
; rcx = pointer to null-terminated string
; returns rax = length
;----------------------------------------------------------
global strlen
strlen:
    xor rax, rax
.loop:
    cmp byte [rcx + rax], 0
    je  .done
    inc rax
    jmp .loop
.done:
    ret

;----------------------------------------------------------
; strcpy - copy src into dst
; rcx = dst
; rdx = src
; returns rax = dst
;----------------------------------------------------------
global strcpy
strcpy:
    mov rax, rcx
.loop:
    mov bl, byte [rdx]
    mov byte [rcx], bl
    test bl, bl
    jz  .done
    inc rcx
    inc rdx
    jmp .loop
.done:
    ret

;----------------------------------------------------------
; strncpy - copy at most n chars from src into dst
; rcx = dst
; rdx = src
; r8  = n
; returns rax = dst
;----------------------------------------------------------
global strncpy
strncpy:
    mov rax, rcx
    test r8, r8
    jz  .done
.loop:
    mov bl, byte [rdx]
    mov byte [rcx], bl
    test bl, bl
    jz  .pad
    inc rcx
    inc rdx
    dec r8
    jnz .loop
    jmp .done
.pad:
    inc rcx
    dec r8
    jz  .done
    mov byte [rcx], 0
    jmp .pad
.done:
    ret

;----------------------------------------------------------
; strcat - append src to end of dst
; rcx = dst
; rdx = src
; returns rax = dst
;----------------------------------------------------------
global strcat
strcat:
    mov rax, rcx
.find_end:
    cmp byte [rcx], 0
    je  .copy
    inc rcx
    jmp .find_end
.copy:
    mov bl, byte [rdx]
    mov byte [rcx], bl
    test bl, bl
    jz  .done
    inc rcx
    inc rdx
    jmp .copy
.done:
    ret

;----------------------------------------------------------
; strncat - append at most n chars from src to dst
; rcx = dst
; rdx = src
; r8  = n
; returns rax = dst
;----------------------------------------------------------
global strncat
strncat:
    mov rax, rcx
.find_end:
    cmp byte [rcx], 0
    je  .copy
    inc rcx
    jmp .find_end
.copy:
    test r8, r8
    jz  .terminate
    mov bl, byte [rdx]
    test bl, bl
    jz  .terminate
    mov byte [rcx], bl
    inc rcx
    inc rdx
    dec r8
    jmp .copy
.terminate:
    mov byte [rcx], 0
    ret

;----------------------------------------------------------
; strcmp - compare two strings
; rcx = str1
; rdx = str2
; returns rax = 0 if equal, <0 or >0 otherwise
;----------------------------------------------------------
global strcmp
strcmp:
.loop:
    mov al, byte [rcx]
    mov bl, byte [rdx]
    cmp al, bl
    jne .diff
    test al, al
    jz  .equal
    inc rcx
    inc rdx
    jmp .loop
.equal:
    xor rax, rax
    ret
.diff:
    movzx rax, al
    movzx rbx, bl
    sub rax, rbx
    ret

;----------------------------------------------------------
; strncmp - compare at most n chars of two strings
; rcx = str1
; rdx = str2
; r8  = n
; returns rax = 0 if equal, <0 or >0 otherwise
;----------------------------------------------------------
global strncmp
strncmp:
    test r8, r8
    jz  .equal
.loop:
    mov al, byte [rcx]
    mov bl, byte [rdx]
    cmp al, bl
    jne .diff
    test al, al
    jz  .equal
    inc rcx
    inc rdx
    dec r8
    jnz .loop
.equal:
    xor rax, rax
    ret
.diff:
    movzx rax, al
    movzx rbx, bl
    sub rax, rbx
    ret

;----------------------------------------------------------
; strchr - find first occurrence of character in string
; rcx = str
; rdx = character (byte)
; returns rax = pointer to char or 0 if not found
;----------------------------------------------------------
global strchr
strchr:
.loop:
    mov al, byte [rcx]
    cmp al, dl
    je  .found
    test al, al
    jz  .notfound
    inc rcx
    jmp .loop
.found:
    mov rax, rcx
    ret
.notfound:
    xor rax, rax
    ret

;----------------------------------------------------------
; strrchr - find last occurrence of character in string
; rcx = str
; rdx = character (byte)
; returns rax = pointer to last char or 0 if not found
;----------------------------------------------------------
global strrchr
strrchr:
    xor rax, rax
.loop:
    mov al, byte [rcx]
    cmp al, dl
    jne .next
    mov rax, rcx
.next:
    test al, al
    jz  .done
    inc rcx
    jmp .loop
.done:
    ret

;----------------------------------------------------------
; strstr - find first occurrence of needle in haystack
; rcx = haystack
; rdx = needle
; returns rax = pointer to match or 0 if not found
;----------------------------------------------------------
global strstr
strstr:
    test byte [rdx], 0xFF
    jnz .start
    mov rax, rcx
    ret
.start:
    mov al, byte [rcx]
    test al, al
    jz  .notfound
    push rcx
    push rdx
.match:
    mov al, byte [rcx]
    mov bl, byte [rdx]
    test bl, bl
    jz  .found
    cmp al, bl
    jne .nomatch
    inc rcx
    inc rdx
    jmp .match
.found:
    pop rdx
    pop rcx
    ret
.nomatch:
    pop rdx
    pop rcx
    inc rcx
    jmp .start
.notfound:
    xor rax, rax
    ret

;----------------------------------------------------------
; strspn - length of prefix consisting of chars in accept
; rcx = str
; rdx = accept
; returns rax = length of prefix
;----------------------------------------------------------
global strspn
strspn:
    xor rax, rax
.outer:
    mov cl, byte [rcx + rax]
    test cl, cl
    jz  .done
    push rax
    push rcx
    mov rcx, rdx
.inner:
    mov bl, byte [rcx]
    test bl, bl
    jz  .not_found
    cmp bl, cl
    je  .found
    inc rcx
    jmp .inner
.found:
    pop rcx
    pop rax
    inc rax
    jmp .outer
.not_found:
    pop rcx
    pop rax
    jmp .done
.done:
    ret

;----------------------------------------------------------
; strcspn - length of prefix NOT consisting of chars in reject
; rcx = str
; rdx = reject
; returns rax = length of prefix
;----------------------------------------------------------
global strcspn
strcspn:
    xor rax, rax
.outer:
    mov cl, byte [rcx + rax]
    test cl, cl
    jz  .done
    push rax
    push rcx
    mov rcx, rdx
.inner:
    mov bl, byte [rcx]
    test bl, bl
    jz  .not_found
    cmp bl, cl
    je  .found
    inc rcx
    jmp .inner
.found:
    pop rcx
    pop rax
    jmp .done
.not_found:
    pop rcx
    pop rax
    inc rax
    jmp .outer
.done:
    ret

;----------------------------------------------------------
; strpbrk - find first char in str that is in accept
; rcx = str
; rdx = accept
; returns rax = pointer to char or 0 if not found
;----------------------------------------------------------
global strpbrk
strpbrk:
.outer:
    mov al, byte [rcx]
    test al, al
    jz  .notfound
    push rcx
    mov rcx, rdx
.inner:
    mov bl, byte [rcx]
    test bl, bl
    jz  .next
    cmp bl, al
    je  .found
    inc rcx
    jmp .inner
.found:
    pop rcx
    mov rax, rcx
    ret
.next:
    pop rcx
    inc rcx
    jmp .outer
.notfound:
    xor rax, rax
    ret

;----------------------------------------------------------
; strtok - tokenize string by delimiter set
; rcx = str (or 0 to continue)
; rdx = delimiters
; returns rax = pointer to next token or 0
; NOTE: uses internal static pointer
;----------------------------------------------------------
section .data
strtok_saved dq 0

section .text
global strtok
strtok:
    test rcx, rcx
    jnz .init
    mov rcx, [strtok_saved]
    test rcx, rcx
    jz  .notfound
    jmp .skip_delim
.init:
.skip_delim:
    mov al, byte [rcx]
    test al, al
    jz  .notfound
    push rcx
    mov rcx, rdx
.check_delim:
    mov bl, byte [rcx]
    test bl, bl
    jz  .not_delim
    cmp bl, al
    je  .is_delim
    inc rcx
    jmp .check_delim
.is_delim:
    pop rcx
    inc rcx
    jmp .skip_delim
.not_delim:
    pop rcx
    mov rax, rcx
.scan_token:
    mov al, byte [rcx]
    test al, al
    jz  .end_of_string
    push rcx
    mov rcx, rdx
.check_end:
    mov bl, byte [rcx]
    test bl, bl
    jz  .not_end
    cmp bl, al
    je  .end_token
    inc rcx
    jmp .check_end
.end_token:
    pop rcx
    mov byte [rcx], 0
    inc rcx
    mov [strtok_saved], rcx
    ret
.not_end:
    pop rcx
    inc rcx
    jmp .scan_token
.end_of_string:
    mov qword [strtok_saved], 0
    ret
.notfound:
    xor rax, rax
    ret

;----------------------------------------------------------
; strdup - duplicate a string (uses HeapAlloc)
; rcx = src
; returns rax = pointer to new string or 0 on failure
;----------------------------------------------------------
extern GetProcessHeap
extern HeapAlloc

global strdup
strdup:
    push rcx
    call strlen         ; rax = length
    pop rcx
    push rcx
    push rax
    inc rax             ; +1 for null terminator
    push rax
    call GetProcessHeap
    pop r8              ; size
    mov rcx, rax        ; heap handle
    xor rdx, rdx        ; flags = 0
    call HeapAlloc
    test rax, rax
    jz  .fail
    pop r9              ; original length (without +1)
    pop rcx             ; src
    push rax            ; save dst
    mov rdx, rcx        ; src
    mov rcx, rax        ; dst
    mov r8, r9
    inc r8              ; copy length+1 (includes null)
    call memcpy
    pop rax
    ret
.fail:
    pop r9
    pop rcx
    xor rax, rax
    ret

;----------------------------------------------------------
; strndup - duplicate at most n chars of a string
; rcx = src
; rdx = n
; returns rax = pointer to new string or 0 on failure
;----------------------------------------------------------
global strndup
strndup:
    push rcx
    push rdx
    call strlen         ; rax = full length
    pop rdx
    pop rcx
    cmp rax, rdx
    jle .use_len
    mov rax, rdx
.use_len:
    push rcx
    push rax
    mov rcx, rax
    inc rcx             ; +1 for null terminator
    push rcx
    call GetProcessHeap
    pop r8
    mov rcx, rax
    xor rdx, rdx
    call HeapAlloc
    test rax, rax
    jz  .fail
    pop r9              ; length to copy
    pop rcx             ; src
    push rax
    mov rdx, rcx
    mov rcx, rax
    mov r8, r9
    call memcpy
    pop rax
    mov byte [rax + r9], 0
    ret
.fail:
    pop r9
    pop rcx
    xor rax, rax
    ret

;----------------------------------------------------------
; memcpy - copy n bytes from src to dst
; rcx = dst
; rdx = src
; r8  = n
; returns rax = dst
;----------------------------------------------------------
global memcpy
memcpy:
    mov rax, rcx
    test r8, r8
    jz  .done
.loop:
    mov bl, byte [rdx]
    mov byte [rcx], bl
    inc rcx
    inc rdx
    dec r8
    jnz .loop
.done:
    ret

;----------------------------------------------------------
; memmove - copy n bytes handling overlapping regions
; rcx = dst
; rdx = src
; r8  = n
; returns rax = dst
;----------------------------------------------------------
global memmove
memmove:
    mov rax, rcx
    test r8, r8
    jz  .done
    cmp rcx, rdx
    jbe .forward
    lea r9, [rdx + r8]
    cmp rcx, r9
    jae .forward
    ; copy backward
    add rcx, r8
    add rdx, r8
    dec rcx
    dec rdx
.back_loop:
    mov bl, byte [rdx]
    mov byte [rcx], bl
    dec rcx
    dec rdx
    dec r8
    jnz .back_loop
    ret
.forward:
.loop:
    mov bl, byte [rdx]
    mov byte [rcx], bl
    inc rcx
    inc rdx
    dec r8
    jnz .loop
.done:
    ret

;----------------------------------------------------------
; memset - fill n bytes with value
; rcx = dst
; rdx = value (byte)
; r8  = n
; returns rax = dst
;----------------------------------------------------------
global memset
memset:
    mov rax, rcx
    test r8, r8
    jz  .done
.loop:
    mov byte [rcx], dl
    inc rcx
    dec r8
    jnz .loop
.done:
    ret

;----------------------------------------------------------
; memcmp - compare n bytes
; rcx = ptr1
; rdx = ptr2
; r8  = n
; returns rax = 0 if equal, <0 or >0 otherwise
;----------------------------------------------------------
global memcmp
memcmp:
    test r8, r8
    jz  .equal
.loop:
    mov al, byte [rcx]
    mov bl, byte [rdx]
    cmp al, bl
    jne .diff
    inc rcx
    inc rdx
    dec r8
    jnz .loop
.equal:
    xor rax, rax
    ret
.diff:
    movzx rax, al
    movzx rbx, bl
    sub rax, rbx
    ret

;----------------------------------------------------------
; memchr - find byte in memory block
; rcx = ptr
; rdx = value (byte)
; r8  = n
; returns rax = pointer to byte or 0 if not found
;----------------------------------------------------------
global memchr
memchr:
    test r8, r8
    jz  .notfound
.loop:
    mov al, byte [rcx]
    cmp al, dl
    je  .found
    inc rcx
    dec r8
    jnz .loop
.notfound:
    xor rax, rax
    ret
.found:
    mov rax, rcx
    ret