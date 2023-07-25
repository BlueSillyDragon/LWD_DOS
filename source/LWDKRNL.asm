;==============================================================
; The LWD Disk Operating System Kernel.
; Copyright (c) 2023 BlueSillyDragon
;==============================================================

[org 0x0]
[bits 16]

kernel_start:

    mov ah, 0x00        ; Clear the screen
    mov al, 0x03
    int 0x10

    mov si, krnl_msg_loaded     ; Print our messages
    call os_print_string

    call os_print_new_line

    mov si, krnl_msg_ver
    call os_print_string

    call os_print_new_line

command_line_interface:

    mov si, prompt      ; Print the command prompt
    call os_print_string
 
.get_cmd_init:
    pusha

    ; Setup buffer
    mov di, input       ; We move our input buffer into DI
    mov al, 0           ; We move 0 into al
    mov cx, 32          ; Move 32 into cx (the number of times we want to preform stosb)
    rep stosb

    ;mov si, input       ; we move our input buffer into bx

.get_command:

    mov ax, input        ; We move our input buffer into ax, our os_input_string needs this parameter
    call os_input_string

.check_for_command:
    mov si, input        ; We move our input into SI

    mov di, about_str    ; We move the string we want to compare it to into DI
    call os_compare_strings     ; Then we compare the strings
    jc near about_command

    mov di, help_str
    call os_compare_strings
    jc near help_command

    mov di, restart_str
    call os_compare_strings
    jc near restart_command

.sta:
    call os_print_new_line

    jmp command_line_interface

.halt:
    hlt
    jmp .halt


; Commands
about_command:
    call os_print_new_line
    mov si, krnl_msg_ver
    call os_print_string
    call os_print_new_line

    jmp command_line_interface

help_command:
    call os_print_new_line
    mov si, krnl_msg_help
    call os_print_string
    call os_print_new_line

    jmp command_line_interface

restart_command:
    mov ax, 0x00
    int 0x19

; This just copies the code in the include file here, basically is the same as just writing the functions here.

%include "syscalls/print.asm"
%include "syscalls/keyboard.asm"
%include "syscalls/strings.asm"

prompt db "> ", 0               ; This is just what appears before your cursor

; Command strings
about_str db "about", 0
cls_str db "cls", 0
help_str db "help", 0
ver_str db "ver", 0
restart_str db "restart", 0

input times 32 db 0             ; Since we're going to be putting our input into here, we need to set aside some bytes for the input

krnl_msg_loaded db "LWD_DOS was successfully loaded!", 0x0d, 0x0a, 0
krnl_msg_ver db "LWD_DOS Version 1.0 Copyright(c) BlueSillyDragon 2023", 0x0d, 0x0a, 0

krnl_msg_help db "COMMANDS: about, help, restart", 0x0d, 0x0a, 0
