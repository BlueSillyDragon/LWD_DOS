;==============================================================
; The LWD Disk Operating System string system calls.
; Copyright (c) 2023 BlueSillyDragon
;==============================================================

;   Compare two strings to see if they match
;   IN: SI = string one, DI = string two
;   OUT: Carry set if equal, clear if false

os_compare_strings:

.prepare:
    pusha

.compare:

    mov al, [si]    ; Move SI and DI, into AL and BL
    mov bl, [di]

    cmp al, bl      ; Check to see if the current character in AL is equal to BL
    jne .not_equal  ; If not, jump to the .not_equal label

    cmp al, 0       ; Next check to see if AL is equal to 0 (The string terminator)
    je .done        ; If so, jump to the .done label

    inc si
    inc di
    jmp .compare

.not_equal:
    popa
    clc     ; Clear carry flag
    ret

.done:
    popa
    stc     ; Set carry flag
    ret