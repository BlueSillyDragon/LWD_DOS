;==============================================================
; The LWD Disk Operating System Kernel.
; Copyright (c) 2023 BlueSillyDragon
;==============================================================

[org 0x0]
[bits 16]

%include "syscalls/print.asm"

kernel_start:

    mov ah, 0x00
    mov al, 0x03
    int 0x13

    mov si, krnl_msg_loaded
    call os_print_string

    jmp $


krnl_msg_loaded db "LWD_DOS was successfully loaded!"
