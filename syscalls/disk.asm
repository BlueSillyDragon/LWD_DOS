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
    add di, 32
    xor bx, bx
    
.get_file_name:
    mov ah, 0x0e
    mov cx, 11
    push di

.loop:
    mov al, [di]
    int 0x10

    cmp cx, 0
    je .next_entry
    inc di
    dec cx
    jmp .loop

.next_entry:
    call os_print_new_line
    pop di
    add di, 32
    mov ax, [di]
    cmp ax, 0
    je .done
    inc bx
    cmp bx, [root_dir_entries]
    jne .get_file_name

.done:

    call os_print_new_line

    ret

; IN: SI should hold the FILENAME of the program we're trying to run

execute_program:
    call os_load_root_dir
    jmp start

start:

    mov si, SETUP_FILENAME
	mov cx, 11 					
	push di
	repe cmpsb 					
	pop di
	je found_kernel

	add di, 32 					
	inc bx 						
	cmp bx, [root_dir_entries]
	jl start 		
	
	jmp kernel_not_found 		
found_kernel:

	mov ax, [di + 26] 			
	mov [FILE_CLUSTER], ax


	mov ax, [reserved_for_boot]
	mov bx, disk_buffer
	mov cl, [sectors_per_fat]
	mov dl, [bootdev]
	call os_read_disk


	mov bx, FILE_SEGMENT
	mov es, bx
	mov bx, FILE_OFFSET
load_kernel:

	mov ax, [FILE_CLUSTER]
	
	add ax, 31 

	mov cl, 1
	mov dl, [bootdev]
	call os_read_disk

	add bx, [bytes_per_sector]


	mov ax, [FILE_CLUSTER]
	mov cx, 3
	mul cx
	mov cx, 2
	div cx

	mov si, disk_buffer
	add si, ax
	mov ax, word [ds:si]

	or dx, dx

	jz even

odd:
	shr ax, 4 
	jmp short next_cluster
even:
	and ax, 0x0fff 	

next_cluster:
	cmp ax, 0x0ff8
	jae start_kernel

	mov [FILE_CLUSTER], ax
	jmp load_kernel

start_kernel:
	mov dl, [bootdev]

	mov ax, FILE_SEGMENT
	mov ds, ax
	mov es, ax

    push ax

	jmp FILE_SEGMENT:FILE_OFFSET

kernel_not_found:
    mov si, krnl_msg_file_not_found
    call os_print_string
    ret


bootdev db 0

reserved_for_boot dw 1

bytes_per_sector dw 512

sectors_per_fat dw 9
number_of_fats db 2

sectors_per_track dw 18
number_of_heads dw 2

root_dir_entries dw 224

FILE_CLUSTER dw 0

FILE_SEGMENT equ 0x5000
FILE_OFFSET equ 0x0000
