;==============================================================
; The LWD Disk Operating Screen system calls.
; Copyright (c) 2023 BlueSillyDragon
;==============================================================

os_move_cursor:
    pusha

    mov bh, 0
    mov ah, 0x02
    int 0x10

    popa
    ret

os_clear_screen:
    pusha

    mov dx, 0       ; Position cursor at top left
    call os_move_cursor

    mov ah, 0x06    ; Scroll Full-screen
    mov al, 0       ; Normal white on black
    mov bh, 7
    mov cx, 0       ; Top left
    mov dh, 24      ; Bottom right
    mov dl, 79
    int 0x10

    popa
    ret