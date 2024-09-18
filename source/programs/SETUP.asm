;==============================================================
; The LWD Disk Operating System Setup Program.
; Copyright (c) 2023 BlueSillyDragon
;==============================================================

[org 0x0]
[bits 16]

mov dx, 0
call os_move_cursor

mov ah, 0x06
mov al, 0x00
mov bh, 0x1f
mov cx, 0
mov dh, 24
mov dl, 79
int 0x10

mov si, msg_setup_environment
call os_print_string

call os_print_new_line
call os_print_new_line

mov si, msg_input_month
call os_print_string

call os_input_string

call os_print_new_line

mov si, msg_input_day
call os_print_string

call os_input_string

call os_print_new_line

mov si, msg_input_year
call os_print_string

call os_input_string

call os_print_new_line

mov ah, 0x03
mov al, 0x01
mov ch, 0x00
mov cl, 0x01
mov dh, 0x00
mov dl, 0x80
xor bx, bx
mov es, bx
mov bx, 0x7c00
int 0x13

jc disk_error

mov si, msg_bootloader_written
call os_print_string
call os_print_new_line

mov si, msg_setup_done
call os_print_string
mov si, msg_remove_floppy
call os_print_string

call os_keystroke
call restart

hlt

restart:
    mov ax, 0x00
    int 0x19

disk_error:
    push bx

    mov bx, 0x03
    mov [error_code], bx

    call bsod

%include "syscalls/print.asm"
%include "syscalls/screen.asm"
%include "syscalls/keyboard.asm"
%include "syscalls/error.asm"

error_code db 0

msg_setup_environment db "LWD-DOS SETUP ENVIRONMENT", 0x0d, 0x0a, 0
msg_input_month db "What month is it?", 0x0d, 0x0a, 0
msg_input_day db "What day is it?", 0x0d, 0x0a, 0
msg_input_year db "What year is it?", 0x0d, 0x0a, 0
msg_bootloader_written db "Bootloader written to drive C:", 0x0d, 0x0a, 0
msg_setup_done db "Setup completed successfully!" , 0x0d, 0x0a, 0
msg_remove_floppy db "remove all disks from diskette drives, then press ENTER", 0x0d, 0x0a, 0
