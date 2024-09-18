;==============================================================
; The LWD Disk Operating System Error System Calls.
; Copyright (c) 2023 BlueSillyDragon
;==============================================================

;==============================================================
; Blue Screen of Death
;==============================================================

; Takes BL as an error code (eg. BL = 0x02 is a disk error)

bsod:
    mov ah, 0x06
    mov al, 0x00
    mov bh, 0x1f
    mov cx, 0
    mov dh, 24
    mov dl, 79
    int 0x10

    mov dx, 20
    mov dh, 10
    call os_move_cursor

    mov si, system_error_message
    call os_print_string
    call os_print_new_line

    mov dx, 2
    mov dh, 11
    call os_move_cursor

    mov si, system_error_message2
    call os_print_string
    call os_print_new_line

    mov dx, 16
    mov dh, 12
    call os_move_cursor

    mov si, ctrl_alt_del_message
    call os_print_string
    call os_print_new_line

check_for_error_code:

    push bx

    mov bx, [error_code]

.forcefully_invoked:
    cmp bx, 0x0a
    je forcefully_invoked

.disk_read_error:
    cmp bx, 0x02
    je disk_read_issue

.disk_write_error:
    cmp bx, 0x03
    je disk_write_issue

continue:

    mov dx, 26
    mov dh, 16
    call os_move_cursor

    mov si, restart_message
    call os_print_string
    call os_print_new_line

    call os_keystroke

    mov ax, 0x00
    int 0x19

forcefully_invoked:
    mov dx, 20
    mov dh, 14
    call os_move_cursor
    mov si, forcefully_invoked_message
    call os_print_string
    call os_print_new_line
    jmp continue

disk_read_issue:
    mov dx, 20
    mov dh, 14
    call os_move_cursor
    mov si, disk_issue_message
    call os_print_string
    call os_print_new_line
    jmp continue

disk_write_issue:
    mov dx, 22
    mov dh, 14
    call os_move_cursor
    mov si, diskw_issue_message
    call os_print_string
    call os_print_new_line
    jmp continue

system_error_message db "LWD-DOS has ran into a fatal error!", 0
system_error_message2 db "Your Operating System has been stopped to prevent damage to your computer.", 0
ctrl_alt_del_message db "*Press Ctrl + Alt + Del to restart your system", 0
forcefully_invoked_message db "Error code 0x0A - Forcefully Invoked!", 0
disk_issue_message db "Error code 0x02 - Disk Read Error!", 0
diskw_issue_message db "Error code 0x03 - Disk Write Error!", 0
restart_message db "Press any key to continue", 0