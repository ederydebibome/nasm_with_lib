; userlib/win64/math.asm
; Windows x64 - Microsoft calling convention
; mirrors <math.h>
; maximally optimized: x87 FPU + SSE4.1 hardware instructions
default rel

section .data
_pi         dq 3.14159265358979323846
_ln2        dq 0.69314718055994530941
_ln10       dq 2.30258509299404568402
_one        dq 1.0
_two        dq 2.0
_half       dq 0.5
_nan        dq 0x7FF8000000000000
_inf        dq 0x7FF0000000000000
align 16
_abs_mask   dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF
align 16
_sign_mask  dq 0x8000000000000000, 0

section .text

;----------------------------------------------------------
; fabs - absolute value (SSE2)
; xmm0 = x
; returns xmm0 = |x|
;----------------------------------------------------------
global fabs
fabs:
    andpd xmm0, [_abs_mask]
    ret

;----------------------------------------------------------
; sqrt - square root (SSE2 hardware)
; xmm0 = x
; returns xmm0 = sqrt(x)
;----------------------------------------------------------
global sqrt
sqrt:
    sqrtsd xmm0, xmm0
    ret

;----------------------------------------------------------
; floor - round down (SSE4.1 hardware)
; xmm0 = x
; returns xmm0 = floor(x)
;----------------------------------------------------------
global floor
floor:
    roundsd xmm0, xmm0, 1
    ret

;----------------------------------------------------------
; ceil - round up (SSE4.1 hardware)
; xmm0 = x
; returns xmm0 = ceil(x)
;----------------------------------------------------------
global ceil
ceil:
    roundsd xmm0, xmm0, 2
    ret

;----------------------------------------------------------
; round - round to nearest (SSE4.1 hardware)
; xmm0 = x
; returns xmm0 = round(x)
;----------------------------------------------------------
global round
round:
    roundsd xmm0, xmm0, 4
    ret

;----------------------------------------------------------
; trunc - truncate toward zero (SSE4.1 hardware)
; xmm0 = x
; returns xmm0 = trunc(x)
;----------------------------------------------------------
global trunc
trunc:
    roundsd xmm0, xmm0, 3
    ret

;----------------------------------------------------------
; fmin - minimum (SSE2 hardware)
; xmm0 = x, xmm1 = y
; returns xmm0 = min(x, y)
;----------------------------------------------------------
global fmin
fmin:
    minsd xmm0, xmm1
    ret

;----------------------------------------------------------
; fmax - maximum (SSE2 hardware)
; xmm0 = x, xmm1 = y
; returns xmm0 = max(x, y)
;----------------------------------------------------------
global fmax
fmax:
    maxsd xmm0, xmm1
    ret

;----------------------------------------------------------
; copysign - copy sign of y to x (SSE2)
; xmm0 = x, xmm1 = y
; returns xmm0 = |x| with sign of y
;----------------------------------------------------------
global copysign
copysign:
    andpd xmm0, [_abs_mask]
    andpd xmm1, [_sign_mask]
    orpd  xmm0, xmm1
    ret

;----------------------------------------------------------
; fmod - remainder (SSE2)
; xmm0 = x, xmm1 = y
; returns xmm0 = x mod y
;----------------------------------------------------------
global fmod
fmod:
    movsd xmm2, xmm0
    divsd xmm2, xmm1
    roundsd xmm2, xmm2, 3
    mulsd xmm2, xmm1
    subsd xmm0, xmm2
    ret

;----------------------------------------------------------
; hypot - euclidean distance (SSE2)
; xmm0 = x, xmm1 = y
; returns xmm0 = sqrt(x^2 + y^2)
;----------------------------------------------------------
global hypot
hypot:
    mulsd xmm0, xmm0
    mulsd xmm1, xmm1
    addsd xmm0, xmm1
    sqrtsd xmm0, xmm0
    ret

;----------------------------------------------------------
; sin - sine (x87 FSIN hardware)
; xmm0 = x
; returns xmm0 = sin(x)
;----------------------------------------------------------
global sin
sin:
    sub rsp, 8
    movsd [rsp], xmm0
    fld qword [rsp]
    fsin
    fstp qword [rsp]
    movsd xmm0, [rsp]
    add rsp, 8
    ret

;----------------------------------------------------------
; cos - cosine (x87 FCOS hardware)
; xmm0 = x
; returns xmm0 = cos(x)
;----------------------------------------------------------
global cos
cos:
    sub rsp, 8
    movsd [rsp], xmm0
    fld qword [rsp]
    fcos
    fstp qword [rsp]
    movsd xmm0, [rsp]
    add rsp, 8
    ret

;----------------------------------------------------------
; tan - tangent (x87 FPTAN hardware)
; xmm0 = x
; returns xmm0 = tan(x)
;----------------------------------------------------------
global tan
tan:
    sub rsp, 8
    movsd [rsp], xmm0
    fld qword [rsp]
    fptan
    fstp st0            ; pop the implicit 1.0
    fstp qword [rsp]
    movsd xmm0, [rsp]
    add rsp, 8
    ret

;----------------------------------------------------------
; atan - arc tangent (x87 FPATAN hardware)
; xmm0 = x
; returns xmm0 = atan(x)
;----------------------------------------------------------
global atan
atan:
    sub rsp, 8
    movsd [rsp], xmm0
    fld qword [rsp]
    fld1
    fpatan              ; st0 = atan(x/1) = atan(x)
    fstp qword [rsp]
    movsd xmm0, [rsp]
    add rsp, 8
    ret

;----------------------------------------------------------
; atan2 - arc tangent y/x (x87 FPATAN hardware)
; xmm0 = y, xmm1 = x
; returns xmm0 = atan2(y, x)
;----------------------------------------------------------
global atan2
atan2:
    sub rsp, 16
    movsd [rsp],     xmm0   ; y
    movsd [rsp + 8], xmm1   ; x
    fld qword [rsp + 8]          ; st0 = x
    fld qword [rsp]              ; st0 = y, st1 = x
    fpatan                  ; st0 = atan2(y, x)
    fstp qword [rsp]
    movsd xmm0, [rsp]
    add rsp, 16
    ret

;----------------------------------------------------------
; asin - arc sine (x87)
; xmm0 = x
; returns xmm0 = asin(x)
; asin(x) = atan2(x, sqrt(1 - x^2))
;----------------------------------------------------------
global asin
asin:
    sub rsp, 16
    movsd [rsp], xmm0
    ; sqrt(1 - x^2)
    mulsd xmm0, xmm0
    movsd xmm1, [_one]
    subsd xmm1, xmm0
    sqrtsd xmm1, xmm1
    movsd xmm0, [rsp]
    ; atan2(x, sqrt(1-x^2))
    movsd [rsp + 8], xmm1
    fld qword [rsp + 8]          ; st0 = sqrt(1-x^2)
    fld qword [rsp]              ; st0 = x
    fpatan
    fstp qword [rsp]
    movsd xmm0, [rsp]
    add rsp, 16
    ret

;----------------------------------------------------------
; acos - arc cosine (x87)
; xmm0 = x
; returns xmm0 = acos(x)
; acos(x) = atan2(sqrt(1 - x^2), x)
;----------------------------------------------------------
global acos
acos:
    sub rsp, 16
    movsd [rsp], xmm0
    mulsd xmm0, xmm0
    movsd xmm1, [_one]
    subsd xmm1, xmm0
    sqrtsd xmm1, xmm1
    movsd xmm0, [rsp]
    movsd [rsp + 8], xmm1
    fld qword [rsp]              ; st0 = x
    fld qword [rsp + 8]          ; st0 = sqrt(1-x^2)
    fpatan                  ; atan2(sqrt, x)
    fstp qword [rsp]
    movsd xmm0, [rsp]
    add rsp, 16
    ret

;----------------------------------------------------------
; exp - e^x (x87 F2XM1 + FSCALE)
; xmm0 = x
; returns xmm0 = e^x
;----------------------------------------------------------
global exp
exp:
    sub rsp, 24
    movsd [rsp], xmm0
    fld qword [rsp]              ; st0 = x
    fldl2e                  ; st0 = log2(e), st1 = x
    fmulp                   ; st0 = x * log2(e)
    fld st0                 ; st0 = copy, st1 = x*log2(e)
    frndint                 ; st0 = round(x*log2(e))
    fsubr st1, st0          ; st1 = frac part
    fxch                    ; st0 = frac, st1 = int
    f2xm1                   ; st0 = 2^frac - 1
    fld1
    faddp                   ; st0 = 2^frac
    fscale                  ; st0 = 2^frac * 2^int = e^x
    fstp st1
    fstp qword [rsp]
    movsd xmm0, [rsp]
    add rsp, 24
    ret

;----------------------------------------------------------
; log - natural logarithm (x87 FYL2X)
; xmm0 = x
; returns xmm0 = ln(x)
;----------------------------------------------------------
global log
log:
    sub rsp, 8
    movsd [rsp], xmm0
    fldln2                  ; st0 = ln(2)
    fld qword [rsp]              ; st0 = x, st1 = ln(2)
    fyl2x                   ; st0 = ln(2) * log2(x) = ln(x)
    fstp qword [rsp]
    movsd xmm0, [rsp]
    add rsp, 8
    ret

;----------------------------------------------------------
; log2 - base 2 logarithm (x87 FYL2X)
; xmm0 = x
; returns xmm0 = log2(x)
;----------------------------------------------------------
global log2
log2:
    sub rsp, 8
    movsd [rsp], xmm0
    fld1                    ; st0 = 1.0
    fld qword [rsp]              ; st0 = x, st1 = 1.0
    fyl2x                   ; st0 = 1.0 * log2(x)
    fstp qword [rsp]
    movsd xmm0, [rsp]
    add rsp, 8
    ret

;----------------------------------------------------------
; log10 - base 10 logarithm (x87 FYL2X)
; xmm0 = x
; returns xmm0 = log10(x)
;----------------------------------------------------------
global log10
log10:
    sub rsp, 8
    movsd [rsp], xmm0
    fldlg2                  ; st0 = log10(2)
    fld qword [rsp]              ; st0 = x, st1 = log10(2)
    fyl2x                   ; st0 = log10(2) * log2(x) = log10(x)
    fstp qword [rsp]
    movsd xmm0, [rsp]
    add rsp, 8
    ret

;----------------------------------------------------------
; pow - x^y (x87 FYL2X + F2XM1 + FSCALE)
; xmm0 = x, xmm1 = y
; returns xmm0 = x^y
;----------------------------------------------------------
global pow
pow:
    sub rsp, 16
    movsd [rsp],     xmm0
    movsd [rsp + 8], xmm1
    fld qword [rsp + 8]          ; st0 = y
    fld qword [rsp]              ; st0 = x, st1 = y
    fyl2x                   ; st0 = y * log2(x)
    fld st0
    frndint                 ; st0 = int part
    fsubr st1, st0          ; st1 = frac part
    fxch
    f2xm1
    fld1
    faddp                   ; 2^frac
    fscale                  ; 2^(frac+int) = x^y
    fstp st1
    fstp qword [rsp]
    movsd xmm0, [rsp]
    add rsp, 16
    ret

;----------------------------------------------------------
; sinh - hyperbolic sine (x87)
; xmm0 = x
; returns xmm0 = sinh(x)
; sinh(x) = (e^x - e^-x) / 2
;----------------------------------------------------------
global sinh
sinh:
    push rbx
    movq rbx, xmm0
    call exp
    movsd xmm2, xmm0
    movq xmm0, rbx
    andpd xmm0, [_abs_mask]
    xorpd xmm0, [_sign_mask]
    call exp
    subsd xmm2, xmm0
    mulsd xmm2, [_half]
    movsd xmm0, xmm2
    pop rbx
    ret

;----------------------------------------------------------
; cosh - hyperbolic cosine (x87)
; xmm0 = x
; returns xmm0 = cosh(x)
; cosh(x) = (e^x + e^-x) / 2
;----------------------------------------------------------
global cosh
cosh:
    push rbx
    movq rbx, xmm0
    call exp
    movsd xmm2, xmm0
    movq xmm0, rbx
    andpd xmm0, [_abs_mask]
    xorpd xmm0, [_sign_mask]
    call exp
    addsd xmm2, xmm0
    mulsd xmm2, [_half]
    movsd xmm0, xmm2
    pop rbx
    ret

;----------------------------------------------------------
; tanh - hyperbolic tangent
; xmm0 = x
; returns xmm0 = tanh(x)
; tanh(x) = sinh(x) / cosh(x)
;----------------------------------------------------------
global tanh
tanh:
    push rbx
    movq rbx, xmm0
    call sinh
    movsd xmm2, xmm0
    movq xmm0, rbx
    call cosh
    divsd xmm2, xmm0
    movsd xmm0, xmm2
    pop rbx
    ret
