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

%include "syscalls/print.asm"
%include "syscalls/screen.asm"

msg_setup_environment db "LWD-DOS SETUP ENVIRONMENT", 0x0d, 0x0a, 0