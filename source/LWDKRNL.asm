;==============================================================
; The LWD Disk Operating System Kernel.
; Copyright (c) 2023 BlueSillyDragon
;==============================================================

%include "syscalls/print.asm"

kernel_start:
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    jmp $
