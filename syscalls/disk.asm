;==============================================================
; The LWD Disk Operating System Disk System Calls.
; Copyright (c) 2023 BlueSillyDragon
;==============================================================

os_lba2chs:
    push ax
    push dx

    xor dx, dx

    div word [sectors_per_track]

    inc dx
    mov cx, dx

    xor dx, dx

    div word [number_of_heads]

    mov dh, dl
    mov ch, al

    shl ah, 6

    or cl, ah

    pop ax
    mov dl, al
    pop ax
    ret

os_reset_disk:
    push ax
    push dx
    mov ah, 0x00
    mov dl, byte [bootdev]
    stc
    int 0x13
    pop ax
    pop dx
    ret

os_read_disk:
    push ax
    push bx
    push cx
    push dx
    push di

    push cx
    call os_lba2chs
    pop ax

    mov ah, 0x02
    mov di, 3

.sta:
    pusha
    stc
    int 0x13
    jnc .fin

    popa
    call os_reset_disk
    
    dec di
    test di, di
    jnz .sta

.fail:
    jmp os_floppy_error

.fin:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax

    ret    

os_load_root_dir:

    mov ax, [sectors_per_fat]
    mov bl, [number_of_fats]
    xor bh, bh
    mul bx
    add ax, [reserved_for_boot]
    push ax

    mov ax, [root_dir_entries]
    shl ax, 5
    xor dx, dx
    div word [bytes_per_sector]

    test dx, dx
    jz os_read_root_dir

os_read_root_dir:
    mov cl, al
    pop ax
    mov dl, [bootdev]
    mov bx, disk_buffer
    call os_read_disk

    xor bx, bx
    mov di, disk_buffer

    ret

os_get_file_list:
    call os_load_root_dir
    mov cx, 11
    add di, 32
    
.loop:
    mov al, [di]
    mov ah, 0x0e
    int 0x10
    inc di
    mov al, [di]
    int 0x10
    inc di
    mov al, [di]
    int 0x10
    inc di
    mov al, [di]
    int 0x10
    inc di
    mov al, [di]
    int 0x10
    inc di
    mov al, [di]
    int 0x10
    inc di
    mov al, [di]
    int 0x10
    inc di
    mov al, [di]
    int 0x10
    inc di
    mov al, [di]
    int 0x10
    inc di
    mov al, [di]
    int 0x10
    inc di
    mov al, [di]
    int 0x10

    call os_print_new_line

    ret



bootdev db 0

reserved_for_boot dw 1

bytes_per_sector dw 512

sectors_per_fat dw 9
number_of_fats db 2

sectors_per_track dw 18
number_of_heads dw 2

root_dir_entries dw 224
