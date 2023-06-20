;==============================================================
; The LWD Disk Operating System PRINT SYSTEM CALLS.
; Copyright (c) 2023 BlueSillyDragon
;==============================================================


os_print_string:
    pusha
    mov ah, 0x0e
.loop:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .loop

.done:
    popa
    ret

os_clear_screen:
    pusha
    mov ah, 0x00
    mov al, 0x03    ; Sets video mode to color text
    int 0x10
    popa