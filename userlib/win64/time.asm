; userlib/win64/time.asm
; Windows x64 - Microsoft calling convention
; mirrors <time.h>
; maximally optimized: direct Win32 API, minimal overhead

extern GetSystemTimeAsFileTime
extern GetLocalTime
extern GetSystemTime
extern SystemTimeToFileTime
extern FileTimeToSystemTime
extern SystemTimeToTzSpecificLocalTime

; SYSTEMTIME struct layout (16 bytes)
; offset 0  : wYear        (WORD)
; offset 2  : wMonth       (WORD)
; offset 4  : wDayOfWeek   (WORD)
; offset 6  : wDay         (WORD)
; offset 8  : wHour        (WORD)
; offset 10 : wMinute      (WORD)
; offset 12 : wSecond      (WORD)
; offset 14 : wMilliseconds(WORD)

; struct tm layout (mirrors C runtime, 9 x int = 36 bytes)
; offset 0  : tm_sec   (int)
; offset 4  : tm_min   (int)
; offset 8  : tm_hour  (int)
; offset 12 : tm_mday  (int)
; offset 16 : tm_mon   (int) 0-based
; offset 20 : tm_year  (int) years since 1900
; offset 24 : tm_wday  (int)
; offset 28 : tm_yday  (int)
; offset 32 : tm_isdst (int)

; FILETIME = 100ns intervals since Jan 1 1601
; Unix time = seconds since Jan 1 1970
; offset between 1601 and 1970 in 100ns units:
EPOCH_DIFF equ 116444736000000000

section .data
_st         times 16 db 0      ; SYSTEMTIME buffer
_ft         times 8  db 0      ; FILETIME buffer
_tm         times 36 db 0      ; tm buffer
_days_month dd 0,31,59,90,120,151,181,212,243,273,304,334

section .text

;----------------------------------------------------------
; time - get unix timestamp
; rcx = pointer to time_t to store result (or NULL)
; returns rax = current unix time_t
;----------------------------------------------------------
global time
time:
    push rbx
    push rcx
    ; GetSystemTimeAsFileTime → FILETIME
    lea rcx, [_ft]
    call GetSystemTimeAsFileTime
    ; load FILETIME as 64-bit value
    mov rax, [_ft]
    ; subtract epoch offset
    mov rbx, EPOCH_DIFF
    sub rax, rbx
    ; convert 100ns → seconds
    mov rbx, 10000000
    xor rdx, rdx
    div rbx
    ; store if pointer provided
    pop rcx
    test rcx, rcx
    jz  .done
    mov [rcx], rax
.done:
    pop rbx
    ret

;----------------------------------------------------------
; clock - CPU ticks since program start
; returns rax = clock ticks (CLOCKS_PER_SEC = 1000)
;----------------------------------------------------------
global clock
clock:
    ; RDTSC gives raw cycle count — use GetTickCount64 for
    ; millisecond precision matching CLOCKS_PER_SEC = 1000
    push rbx
    lea rcx, [_ft]
    call GetSystemTimeAsFileTime
    mov rax, [_ft]
    mov rbx, EPOCH_DIFF
    sub rax, rbx
    ; convert 100ns → milliseconds
    mov rbx, 10000
    xor rdx, rdx
    div rbx
    pop rbx
    ret

;----------------------------------------------------------
; difftime - difference between two timestamps
; xmm0 = time1 (returned as double seconds)
; rcx  = time1 (int64)
; rdx  = time0 (int64)
; returns xmm0 = (double)(time1 - time0)
;----------------------------------------------------------
global difftime
difftime:
    sub rcx, rdx
    cvtsi2sd xmm0, rcx
    ret

;----------------------------------------------------------
; gmtime - convert time_t to UTC struct tm
; rcx = pointer to time_t
; returns rax = pointer to static struct tm
;----------------------------------------------------------
global gmtime
gmtime:
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, [rcx]          ; time_t value

    ; convert unix time to FILETIME
    mov rax, r12
    mov rbx, 10000000
    imul rax, rbx
    mov rbx, EPOCH_DIFF
    add rax, rbx
    mov [_ft], rax

    ; FileTimeToSystemTime
    lea rcx, [_ft]
    lea rdx, [_st]
    call FileTimeToSystemTime

    ; fill tm struct from SYSTEMTIME
    lea rdi, [_tm]

    movzx eax, word [_st + 12] ; wSecond
    mov [rdi + 0], eax
    movzx eax, word [_st + 10] ; wMinute
    mov [rdi + 4], eax
    movzx eax, word [_st + 8]  ; wHour
    mov [rdi + 8], eax
    movzx eax, word [_st + 6]  ; wDay
    mov [rdi + 12], eax
    movzx eax, word [_st + 2]  ; wMonth (1-based → 0-based)
    dec eax
    mov [rdi + 16], eax
    movzx eax, word [_st + 0]  ; wYear - 1900
    sub eax, 1900
    mov [rdi + 20], eax
    movzx eax, word [_st + 4]  ; wDayOfWeek
    mov [rdi + 24], eax

    ; compute tm_yday
    movzx r13, word [_st + 2]   ; month 1-based
    movzx r14, word [_st + 0]   ; year
    movzx r15, word [_st + 6]   ; day

    ; days before this month
    lea rbx, [_days_month]
    dec r13                     ; 0-based index
    mov eax, [rbx + r13 * 4]
    ; leap year correction if month > Feb
    cmp r13, 2
    jl  .no_leap
    ; check leap: (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    mov rax, r14
    xor rdx, rdx
    mov rbx, 400
    div rbx
    test rdx, rdx
    jz  .is_leap
    mov rax, r14
    xor rdx, rdx
    mov rbx, 100
    div rbx
    test rdx, rdx
    jz  .no_leap
    mov rax, r14
    xor rdx, rdx
    mov rbx, 4
    div rbx
    test rdx, rdx
    jnz .no_leap
.is_leap:
    mov eax, [rbx + r13 * 4]
    inc eax
    jmp .store_yday
.no_leap:
    lea rbx, [_days_month]
    mov eax, [rbx + r13 * 4]
.store_yday:
    add eax, r15d
    dec eax
    mov [rdi + 28], eax

    ; tm_isdst = 0 (UTC has no DST)
    mov dword [rdi + 32], 0

    lea rax, [_tm]
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

;----------------------------------------------------------
; localtime - convert time_t to local struct tm
; rcx = pointer to time_t
; returns rax = pointer to static struct tm
;----------------------------------------------------------
global localtime
localtime:
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, [rcx]

    ; convert unix time to FILETIME
    mov rax, r12
    mov rbx, 10000000
    imul rax, rbx
    mov rbx, EPOCH_DIFF
    add rax, rbx
    mov [_ft], rax

    ; FileTimeToSystemTime → UTC SYSTEMTIME
    lea rcx, [_ft]
    lea rdx, [_st]
    call FileTimeToSystemTime

    ; convert UTC to local
    xor rcx, rcx                ; TZ = NULL (use system TZ)
    lea rdx, [_st]
    lea r8, [_st]
    call SystemTimeToTzSpecificLocalTime

    ; fill tm struct
    lea rdi, [_tm]

    movzx eax, word [_st + 12]
    mov [rdi + 0], eax
    movzx eax, word [_st + 10]
    mov [rdi + 4], eax
    movzx eax, word [_st + 8]
    mov [rdi + 8], eax
    movzx eax, word [_st + 6]
    mov [rdi + 12], eax
    movzx eax, word [_st + 2]
    dec eax
    mov [rdi + 16], eax
    movzx eax, word [_st + 0]
    sub eax, 1900
    mov [rdi + 20], eax
    movzx eax, word [_st + 4]
    mov [rdi + 24], eax

    ; tm_yday
    movzx r13, word [_st + 2]
    movzx r14, word [_st + 0]
    movzx r15, word [_st + 6]
    lea rbx, [_days_month]
    dec r13
    mov eax, [rbx + r13 * 4]
    cmp r13, 2
    jl  .no_leap
    mov rax, r14
    xor rdx, rdx
    mov rbx, 400
    div rbx
    test rdx, rdx
    jz  .is_leap
    mov rax, r14
    xor rdx, rdx
    mov rbx, 100
    div rbx
    test rdx, rdx
    jz  .no_leap
    mov rax, r14
    xor rdx, rdx
    mov rbx, 4
    div rbx
    test rdx, rdx
    jnz .no_leap
.is_leap:
    lea rbx, [_days_month]
    mov eax, [rbx + r13 * 4]
    inc eax
    jmp .store_yday
.no_leap:
    lea rbx, [_days_month]
    mov eax, [rbx + r13 * 4]
.store_yday:
    add eax, r15d
    dec eax
    mov [rdi + 28], eax
    mov dword [rdi + 32], -1    ; tm_isdst = -1 (unknown)

    lea rax, [_tm]
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

;----------------------------------------------------------
; mktime - convert local struct tm to time_t
; rcx = pointer to struct tm
; returns rax = time_t or -1 on failure
;----------------------------------------------------------
global mktime
mktime:
    push rbx
    push r12
    push r13
    mov r12, rcx

    ; fill SYSTEMTIME from tm
    mov eax, [r12 + 20]         ; tm_year
    add eax, 1900
    mov word [_st + 0], ax      ; wYear
    mov eax, [r12 + 16]         ; tm_mon (0-based)
    inc eax
    mov word [_st + 2], ax      ; wMonth
    mov eax, [r12 + 24]         ; tm_wday
    mov word [_st + 4], ax
    mov eax, [r12 + 12]         ; tm_mday
    mov word [_st + 6], ax
    mov eax, [r12 + 8]          ; tm_hour
    mov word [_st + 8], ax
    mov eax, [r12 + 4]          ; tm_min
    mov word [_st + 10], ax
    mov eax, [r12 + 0]          ; tm_sec
    mov word [_st + 12], ax
    mov word [_st + 14], 0      ; wMilliseconds

    ; SystemTimeToFileTime
    lea rcx, [_st]
    lea rdx, [_ft]
    call SystemTimeToFileTime
    test rax, rax
    jz  .fail

    ; FILETIME → unix time_t
    mov rax, [_ft]
    mov rbx, EPOCH_DIFF
    sub rax, rbx
    mov rbx, 10000000
    xor rdx, rdx
    div rbx

    pop r13
    pop r12
    pop rbx
    ret

.fail:
    or rax, -1
    pop r13
    pop r12
    pop rbx
    ret

;----------------------------------------------------------
; asctime - convert struct tm to string
; rcx = pointer to struct tm
; returns rax = pointer to static string
; format: "Www Mmm DD HH:MM:SS YYYY\n"
;----------------------------------------------------------
global asctime

section .data
_asctime_buf    times 26 db 0
_day_names      db "SunMonTueWedThuFriSat"
_mon_names      db "JanFebMarAprMayJunJulAugSepOctNovDec"

section .text
asctime:
    push rbx
    push r12
    mov r12, rcx
    lea rbx, [_asctime_buf]

    ; day name
    mov eax, [r12 + 24]         ; tm_wday
    imul eax, 3
    lea rcx, [_day_names + rax]
    mov al, [rcx]
    mov [rbx], al
    mov al, [rcx + 1]
    mov [rbx + 1], al
    mov al, [rcx + 2]
    mov [rbx + 2], al
    mov byte [rbx + 3], ' '

    ; month name
    mov eax, [r12 + 16]         ; tm_mon
    imul eax, 3
    lea rcx, [_mon_names + rax]
    mov al, [rcx]
    mov [rbx + 4], al
    mov al, [rcx + 1]
    mov [rbx + 5], al
    mov al, [rcx + 2]
    mov [rbx + 6], al
    mov byte [rbx + 7], ' '

    ; day (DD)
    mov eax, [r12 + 12]
    mov ecx, eax
    xor edx, edx
    mov edi, 10
    div edi
    add al, '0'
    mov [rbx + 8], al
    add dl, '0'
    mov [rbx + 9], dl
    mov byte [rbx + 10], ' '

    ; hour
    mov eax, [r12 + 8]
    xor edx, edx
    div edi
    add al, '0'
    mov [rbx + 11], al
    add dl, '0'
    mov [rbx + 12], dl
    mov byte [rbx + 13], ':'

    ; minute
    mov eax, [r12 + 4]
    xor edx, edx
    div edi
    add al, '0'
    mov [rbx + 14], al
    add dl, '0'
    mov [rbx + 15], dl
    mov byte [rbx + 16], ':'

    ; second
    mov eax, [r12 + 0]
    xor edx, edx
    div edi
    add al, '0'
    mov [rbx + 17], al
    add dl, '0'
    mov [rbx + 18], dl
    mov byte [rbx + 19], ' '

    ; year
    mov eax, [r12 + 20]
    add eax, 1900
    xor edx, edx
    mov ecx, 1000
    div ecx
    add al, '0'
    mov [rbx + 20], al
    mov eax, edx
    xor edx, edx
    mov ecx, 100
    div ecx
    add al, '0'
    mov [rbx + 21], al
    mov eax, edx
    xor edx, edx
    div edi
    add al, '0'
    mov [rbx + 22], al
    add dl, '0'
    mov [rbx + 23], dl

    mov byte [rbx + 24], 0x0A
    mov byte [rbx + 25], 0

    lea rax, [_asctime_buf]
    pop r12
    pop rbx
    ret

;----------------------------------------------------------
; ctime - convert time_t to string
; rcx = pointer to time_t
; returns rax = pointer to static string
;----------------------------------------------------------
global ctime
ctime:
    call gmtime
    mov rcx, rax
    call asctime
    ret

;----------------------------------------------------------
; strftime - format time into string
; rcx = buffer
; rdx = max size
; r8  = format string
; r9  = pointer to struct tm
; returns rax = number of chars written
;----------------------------------------------------------
global strftime
strftime:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rdi
    push rsi
    sub rsp, 32

    mov r12, rcx            ; buffer
    mov r13, rdx            ; max size
    mov r14, r8             ; format
    mov r15, r9             ; struct tm
    xor rsi, rsi            ; chars written
    lea rdi, [r12]          ; write pointer

.sf_next:
    movzx rax, byte [r14]
    test al, al
    jz  .sf_done
    cmp al, '%'
    je  .sf_spec
    ; write literal char
    cmp rsi, r13
    jge .sf_done
    mov [rdi], al
    inc rdi
    inc rsi
    inc r14
    jmp .sf_next

.sf_spec:
    inc r14
    movzx rax, byte [r14]
    inc r14

    cmp al, 'Y'
    je  .sf_year4
    cmp al, 'y'
    je  .sf_year2
    cmp al, 'm'
    je  .sf_mon
    cmp al, 'd'
    je  .sf_mday
    cmp al, 'H'
    je  .sf_hour
    cmp al, 'M'
    je  .sf_min
    cmp al, 'S'
    je  .sf_sec
    cmp al, 'A'
    je  .sf_dayname
    cmp al, 'B'
    je  .sf_monname
    cmp al, 'j'
    je  .sf_yday
    cmp al, 'w'
    je  .sf_wday
    cmp al, '%'
    je  .sf_percent
    jmp .sf_next

.sf_year4:
    mov eax, [r15 + 20]
    add eax, 1900
    call .write_int4
    jmp .sf_next

.sf_year2:
    mov eax, [r15 + 20]
    add eax, 1900
    xor edx, edx
    mov ecx, 100
    div ecx
    mov eax, edx
    call .write_int2
    jmp .sf_next

.sf_mon:
    mov eax, [r15 + 16]
    inc eax
    call .write_int2
    jmp .sf_next

.sf_mday:
    mov eax, [r15 + 12]
    call .write_int2
    jmp .sf_next

.sf_hour:
    mov eax, [r15 + 8]
    call .write_int2
    jmp .sf_next

.sf_min:
    mov eax, [r15 + 4]
    call .write_int2
    jmp .sf_next

.sf_sec:
    mov eax, [r15 + 0]
    call .write_int2
    jmp .sf_next

.sf_yday:
    mov eax, [r15 + 28]
    call .write_int3
    jmp .sf_next

.sf_wday:
    mov eax, [r15 + 24]
    call .write_int1
    jmp .sf_next

.sf_dayname:
    mov eax, [r15 + 24]
    imul eax, 3
    lea rbx, [_day_names + rax]
    mov al, [rbx]
    call .write_char
    mov al, [rbx + 1]
    call .write_char
    mov al, [rbx + 2]
    call .write_char
    jmp .sf_next

.sf_monname:
    mov eax, [r15 + 16]
    imul eax, 3
    lea rbx, [_mon_names + rax]
    mov al, [rbx]
    call .write_char
    mov al, [rbx + 1]
    call .write_char
    mov al, [rbx + 2]
    call .write_char
    jmp .sf_next

.sf_percent:
    mov al, '%'
    call .write_char
    jmp .sf_next

.sf_done:
    cmp rsi, r13
    jge .sf_null
    mov byte [rdi], 0
.sf_null:
    mov rax, rsi
    add rsp, 32
    pop rsi
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; write single char al
.write_char:
    cmp rsi, r13
    jge .wc_ret
    mov [rdi], al
    inc rdi
    inc rsi
.wc_ret:
    ret

; write 1-digit int eax
.write_int1:
    add al, '0'
    call .write_char
    ret

; write 2-digit zero-padded int eax
.write_int2:
    push rdx
    xor edx, edx
    mov ecx, 10
    div ecx
    push rdx
    add al, '0'
    call .write_char
    pop rax
    add al, '0'
    call .write_char
    pop rdx
    ret

; write 3-digit zero-padded int eax
.write_int3:
    push rdx
    xor edx, edx
    mov ecx, 100
    div ecx
    push rdx
    add al, '0'
    call .write_char
    pop rax
    xor edx, edx
    mov ecx, 10
    div ecx
    push rdx
    add al, '0'
    call .write_char
    pop rax
    add al, '0'
    call .write_char
    pop rdx
    ret

; write 4-digit zero-padded int eax
.write_int4:
    push rdx
    xor edx, edx
    mov ecx, 1000
    div ecx
    push rdx
    add al, '0'
    call .write_char
    pop rax
    xor edx, edx
    mov ecx, 100
    div ecx
    push rdx
    add al, '0'
    call .write_char
    pop rax
    xor edx, edx
    mov ecx, 10
    div ecx
    push rdx
    add al, '0'
    call .write_char
    pop rax
    add al, '0'
    call .write_char
    pop rdx
    ret
