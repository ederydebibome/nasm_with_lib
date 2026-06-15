; userlib/linux64/process.asm
default rel

global exit, abort, getpid, sleep, system, spawnl

exit:
    mov eax, 60
    syscall
    hlt

abort:
    mov edi, 3
    jmp exit

getpid:
    mov eax, 39
    syscall
    ret

sleep:
    ; sleep(seconds) via nanosleep({sec,0}, NULL)
    sub rsp, 16
    mov [rsp], rdi
    mov qword [rsp + 8], 0
    mov rdi, rsp
    xor esi, esi
    mov eax, 35
    syscall
    add rsp, 16
    ret

system:
    mov eax, -1
    ret

spawnl:
    mov eax, -1
    ret
