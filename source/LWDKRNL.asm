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

    mov si, krnl_msg_type_help
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

    mov di, ver_str
    call os_compare_strings
    jc near ver_command

    mov di, cls_str
    call os_compare_strings
    jc near cls_command

    mov di, echo_str
    call os_compare_strings
    jc near echo_command

    mov di, dir_str
    call os_compare_strings
    jc near list_working_directory_command

    mov di, setup_str
    call os_compare_strings
    jc near setup_command

    ; If the user did not input a valid command
    mov si, krnl_msg_invalid
    call os_print_new_line
    call os_print_string

.sta:
    call os_print_new_line

    jmp command_line_interface

.halt:
    hlt
    jmp .halt


; Commands
about_command:
    call os_print_new_line
    mov si, krnl_msg_about
    call os_print_string
    call os_print_new_line

    jmp command_line_interface

help_command:
    call os_print_new_line
    mov si, krnl_msg_help
    call os_print_string
    call os_print_new_line

    jmp command_line_interface

ver_command:
    call os_print_new_line
    mov si, krnl_msg_ver
    call os_print_string
    call os_print_new_line

    jmp command_line_interface

cls_command:
    call os_clear_screen
    
    jmp command_line_interface

restart_command:
    pusha

    mov si, krnl_msg_restart_confirmation
    call os_print_new_line
    call os_print_string

    call os_keystroke

    mov cl, 'y'
    mov ch, 'n'

    cmp al, cl
    jz .restart

    cmp al, ch
    jz .exit

.invalid_option:
    mov si, krnl_msg_invalid_option
    call os_print_string
    jmp restart_command

.restart:
    mov ax, 0x00
    int 0x19
    hlt

.exit:
    popa
    jmp command_line_interface

echo_command:

    ; Get string to print

    pusha

    call os_print_new_line
    mov si, krnl_msg_echo_string
    call os_print_string
    mov ax, input
    call os_input_string

    ; Move what's in our input buffer to SI

    mov si, input

    ; Print SI

    call os_print_new_line
    call os_print_string
    call os_print_new_line

    popa

    jmp command_line_interface

list_working_directory_command:

    pusha

    call os_print_new_line
    mov si, krnl_msg_current_directory
    call os_print_string

    call os_get_file_list

    popa

    jmp command_line_interface

setup_command:
    popa

    mov dx, 0
    call os_move_cursor

    mov ah, 0x06
    mov al, 0x00
    mov bh, 0x1f
    mov cx, 0
    mov dh, 24
    mov dl, 79
    int 0x10

    mov si, krnl_msg_setup_environment
    call os_print_string

    call os_print_new_line
    call os_print_new_line

    mov si, krnl_msg_input_month
    call os_print_string

    call os_input_string

    call os_print_new_line

    mov si, krnl_msg_input_day
    call os_print_string

    call os_input_string

    call os_print_new_line

    mov si, krnl_msg_input_year
    call os_print_string

    call os_input_string

    call os_print_new_line

    mov si, krnl_msg_setup_done
    call os_print_string
    call os_keystroke
    
    call os_clear_screen

    jmp command_line_interface

os_floppy_error:

    mov si, krnl_msg_floppy_error
    call os_print_string

    call os_keystroke
    call restart_command

; This just copies the code in the include file here, basically is the same as just writing the functions here.

%include "syscalls/print.asm"
%include "syscalls/keyboard.asm"
%include "syscalls/strings.asm"
%include "syscalls/screen.asm"
%include "syscalls/disk.asm"

prompt db "A:\>", 0               ; This is just what appears before your cursor

; Command strings
about_str db "about", 0
cls_str db "cls", 0
help_str db "help", 0
ver_str db "ver", 0
restart_str db "restart", 0
echo_str db "echo", 0
dir_str db "dir", 0
setup_str db "setup", 0
time_str db "time", 0

input times 32 db 0             ; Since we're going to be putting our input into here, we need to set aside some bytes for the input
filename times 11 db 0

; Kernel's messages

krnl_msg_loaded db "LWD-DOS was successfully loaded!", 0x0d, 0x0a, 0
krnl_msg_ver db "LWD-DOS Version 1.0 Copyright(c) BlueSillyDragon 2023", 0x0d, 0x0a, 0
krnl_msg_about db "Version: LWD-DOS 1.0, Running in 16-bit real mode, Made in 2023", 0x0d, 0x0a, 0
krnl_msg_type_setup db "Type 'setup' to set the date", 0x0d, 0x0a, 

krnl_msg_type_help db "Type 'help' for a list of commands.", 0x0d, 0x0a, 0

krnl_msg_setup_environment db "LWD-DOS SETUP ENVIRONMENT", 0x0d, 0x0a, 0

krnl_msg_input_month db "What month is it?", 0x0d, 0x0a, 0
krnl_msg_input_day db "What day is it?", 0x0d, 0x0a, 0
krnl_msg_input_year db "What year is it?", 0x0d, 0x0a, 0

krnl_msg_setup_done db "Setup Finished, press any key to return to LWD-DOS", 0x0d, 0x0a, 0

krnl_msg_echo_string db "Input string to relay: ", 0x0d, 0x0a, 0

krnl_msg_current_directory db "/A:", 0x0d, 0x0a, 0

krnl_msg_restart_confirmation db "Are you sure you want to restart? (y/n)", 0x0d, 0x0a, 0
krnl_msg_invalid_option db "INVALID OPTION! PLEASE TRY AGAIN! (Make sure it's in lowercase)", 0x0d, 0x0a, 0

krnl_msg_help db "COMMANDS: about, help, ver, setup, cls, echo, dir, restart", 0x0d, 0x0a, 0

krnl_msg_invalid db "No such command!", 0x0d, 0x0a, 0
krnl_msg_floppy_error db "FATAL ERROR TRYING TO READ FROM DISK! PRESS ANY BUTTON TO RESTART!", 0x0d, 0x0a, 0

disk_buffer:
