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

os_print_new_line:
    pusha
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10

.done:
    popa
    ret