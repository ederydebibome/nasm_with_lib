; userlib/mac64/math.asm
default rel

section .data
_one dq 1.0
_abs_mask dq 0x7fffffffffffffff, 0x7fffffffffffffff
_sign_mask dq 0x8000000000000000, 0

section .text
global fabs, sqrt, floor, ceil, round, trunc, fmin, fmax, copysign
global fmod, hypot, sin, cos, tan, atan, atan2, asin, acos
global exp, log, log2, log10, pow, sinh, cosh, tanh

fabs:     andpd xmm0, [_abs_mask]
          ret
sqrt:     sqrtsd xmm0, xmm0
          ret
floor:    roundsd xmm0, xmm0, 1
          ret
ceil:     roundsd xmm0, xmm0, 2
          ret
round:    roundsd xmm0, xmm0, 4
          ret
trunc:    roundsd xmm0, xmm0, 3
          ret
fmin:     minsd xmm0, xmm1
          ret
fmax:     maxsd xmm0, xmm1
          ret
copysign: andpd xmm0, [_abs_mask]
          andpd xmm1, [_sign_mask]
          orpd xmm0, xmm1
          ret
fmod:     movsd xmm2, xmm0
          divsd xmm2, xmm1
          roundsd xmm2, xmm2, 3
          mulsd xmm2, xmm1
          subsd xmm0, xmm2
          ret
hypot:    mulsd xmm0, xmm0
          mulsd xmm1, xmm1
          addsd xmm0, xmm1
          sqrtsd xmm0, xmm0
          ret

sin:      sub rsp, 8
          movsd [rsp], xmm0
          fld qword [rsp]
          fsin
          fstp qword [rsp]
          movsd xmm0, [rsp]
          add rsp, 8
          ret
cos:      sub rsp, 8
          movsd [rsp], xmm0
          fld qword [rsp]
          fcos
          fstp qword [rsp]
          movsd xmm0, [rsp]
          add rsp, 8
          ret
tan:      sub rsp, 8
          movsd [rsp], xmm0
          fld qword [rsp]
          fptan
          fstp st0
          fstp qword [rsp]
          movsd xmm0, [rsp]
          add rsp, 8
          ret
atan:     sub rsp, 8
          movsd [rsp], xmm0
          fld qword [rsp]
          fld1
          fpatan
          fstp qword [rsp]
          movsd xmm0, [rsp]
          add rsp, 8
          ret
atan2:    sub rsp, 16
          movsd [rsp], xmm0
          movsd [rsp+8], xmm1
          fld qword [rsp+8]
          fld qword [rsp]
          fpatan
          fstp qword [rsp]
          movsd xmm0, [rsp]
          add rsp, 16
          ret

asin:     ret
acos:     ret
exp:      ret
log:      ret
log2:     ret
log10:    ret
pow:      ret
sinh:     ret
cosh:     ret
tanh:     ret
