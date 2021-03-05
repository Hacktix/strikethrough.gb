SECTION "Functions", ROM0
; ------------------------------------------------------------------------------
; Copies a memory section of size BC pointed to by DE to HL.
; ------------------------------------------------------------------------------
Memcpy::
    ld a, [de]
    inc de
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, Memcpy
    ret

; ------------------------------------------------------------------------------
; Copies a zero-terminated string pointed to by DE to HL.
; ------------------------------------------------------------------------------
Strcpy::
    ld a, [de]
    inc de
    ld [hli], a
    and a
    jr nz, Strcpy
    ret