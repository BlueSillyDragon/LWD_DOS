;==============================================================
; The LWD Disk Operating System Bootloader.
; Copyright (c) 2023 BlueSillyDragon
;==============================================================

[bits 16] ; We tell the compliler [NASM] that we're working in 16 bit mode
[org 0x7c00] ; The BIOS checks in this memory address for the bootloader, this tells NASM that this is the memory offset we want to load our code from

jmp short bootloader_start
nop

;==============================
; BIOS Parameter Block [BFP]
;==============================

oem_label 		db "LWD_DOS1" ; Disk Label
bytes_per_sector 		dw 512 		; The number of bytes per cluster, usually 512B
sectors_per_cluster 	db 1 		; Sectors per Cluster
reserved_for_boot 	dw 1 		; Sectors reserved for boot
number_of_fats 		db 2 		; Number of copies of FAT12
root_dir_entries 		dw 224 		; The number of sectors to read (224 * 32 = 7168 = 14 sectors to read)
logical_sectors 		dw 2880 	; Number of logical sectors (If you multiply this by 512 you get the 1.44MB we need to read)
medium_byte 		db 0F0h 		; Medium descriptor byte (0xF0 is a 3.5" floppy diskette)
sectors_per_fat 		dw 9 		; The number of sectors per fat
sectors_per_track 	dw 18 		; The number of sectors per track (This number is usually 18)
heads 			dw 2 		; The amount of sides/heads of the disk drive (again, usually 2)
hidden_sectors 		dd 0 	; The amount of hidden sectors
large_sectors 		dd 0 	; The amount of large sectors
drive_number 		dw 0 	; Tne drive number [0x00 for floppy, and 0x80 for a hard disk]. This number is practically useless since the media is likely to be moved to a different machine with a different drive number
signature 		db 0x29 		; The Volume's Signature (Should be either 0x29 or 0x28)
volume_id 		dd 020e04031h		; The volume id, this can really be any number
volume_label 		db "LWD_DOS    " 	; The volume label. This can be any 11 chars, this will be padded out with spaces.
file_system 		db "FAT12   " 		; The File System Type. DON'T TOUCH!!!

;==============================
; Main Bootloader code	
;==============================

bootloader_start: ; The starting point

	; Setup Segment registers

	cli 		; Disable interrupts while we setup the stack

	mov ax, 0 ; We can't assign ds and es a constant directly
	mov ds, ax
	mov es, ax 	; We will give ES a value when we need to read from a memory address higher than 64KiB

	mov ss, ax ; We set the Stack Segment register to 0
	mov sp, 0x7c00 ; We set the Stack Pointer to our current memory address

	sti 		; Restore interrupts

	mov si, msg_booting
	call bootloader_print

;==================================
; FAT12 File System Routines
;==================================

load_root_dir:
	mov ax, [sectors_per_fat] 	; Move the value of the sectors_per_fat into the AX register
	mov bl, [number_of_fats] 	; Move the number_of_fats into BX
	xor bh, bh 					; Set BH to zero
	mul bx  					; AX = (number_of_fats * sectors_per_fat) = Size of the FAT reigon
	add ax, [reserved_for_boot] ; AX = (Size of Reserved_For_Boot region + FAT region) = Location of the Root_Directory [Logical sector 19]
	push ax 

	mov ax, [root_dir_entries] 	; We move the number of root_dir_entries
	shl ax, 5 					; We shift it left 5 bits to multiply it by 32
	xor dx, dx  				; Set DX to 0
	div word [bytes_per_sector] ; Divide the sectors_per_fat by the bytes_per_sector

	test dx, dx 				; Check to see if DX = 0
	jz read_root_dir
	inc ax 						; If DX doesn't equal 0, then that means we have a sector only partially filled with entries

read_root_dir:
	; Read Root Directory
	mov cl, al 					; We set CL to the number of sectors to read
	pop ax 						; We pop AX of the stack, this holds the location of the Root Directory
	mov dl, [BOOTDEV] 			; Set dl to the Boot Device number
	mov bx, BUFFER 				; set ES:BX to the buffer, this is where we will laod our code
	call disk_read					; Read the Root Directory

	xor bx, bx 					; Set BX to zero, this will count the amount of entries we've already read
	mov di, BUFFER 				; This will point to the loaction were loaded at

search_for_kernel:
	mov si, KERN_FILENAME 		; Move the filename into SI
	mov cx, 11 					; Move 11 into CX, this is the amount of times we want to repeat CMPSB
	push di
	repe cmpsb 					; This will compare ES:DI to DS:SI to see if we have found the kernel file
	pop di
	je found_kernel

	add di, 32 					; We go to the next entry, one entry is 32 bytes
	inc bx 						; increment our count
	cmp bx, [root_dir_entries] 	; See if we've checked all the entries yet
	jl search_for_kernel 		; if we haven't, try the next entry
	
	jmp kernel_not_found 		; Otherwise, tell the user that we couldn't find the kernel.bin file
found_kernel:
	mov ax, [di + 26] 			; DI still holds the buffer addres, we add 26 to this, which points to the first cluster value
	mov [KERNEL_CLUSTER], ax

	; Load FAT from disk into memory
	mov ax, [reserved_for_boot]
	mov bx, BUFFER
	mov cl, [sectors_per_fat]
	mov dl, [BOOTDEV]
	call disk_read

	; Read Kernel, and process FAT cluster chain
	mov bx, KERNEL_SEGMENT
	mov es, bx
	mov bx, KERNEL_OFFSET
load_kernel:
	; Read next cluster
	mov ax, [KERNEL_CLUSTER]
	
	add ax, 31 

	mov cl, 1
	mov dl, [BOOTDEV]
	call disk_read

	add bx, [bytes_per_sector]

	; Compute location of the next cluster
	mov ax, [KERNEL_CLUSTER]
	mov cx, 3
	mul cx
	mov cx, 2
	div cx

	mov si, BUFFER
	add si, ax
	mov ax, word [ds:si]

	or dx, dx 		; If DX = 0, cluster is even, If DX = 1, cluster is odd

	jz even

odd:
	shr ax, 4 		; We cut off those extra 4 bits, those belong to another cluster
	jmp short next_cluster
even:
	and ax, 0x0fff 	; Mask out final 4 bits

next_cluster:
	cmp ax, 0x0ff8 	; File end marker in FAT
	jae start_kernel 		; If it is that means we have successfully read the kernel, and are now reday to jump to it

	mov [KERNEL_CLUSTER], ax
	jmp load_kernel

start_kernel:
	mov dl, [BOOTDEV] 		; Set dl for the kernel

	mov ax, KERNEL_SEGMENT
	mov ds, ax
	mov es, ax

	jmp KERNEL_SEGMENT:KERNEL_OFFSET


;=======================
; Error Handlers
;=======================

kernel_not_found:
	mov si, msg_kern_not_found
	call bootloader_print
	call reboot
	hlt

floppy_error:
	mov si, msg_flpy_err
	call bootloader_print
	call reboot
	hlt

;=================================
; Disk Read Routines
;=================================
disk_reset: 		; In goes the BOOTDEV, out comes... nothing, well unless something went wrong, in which case it will set the carry flag
	push ax
	push dx
	mov ah, 0x00 		; Reset the disk
	mov dl, byte [BOOTDEV] 	; Move the BOOTDEV into dl
	stc
	int 0x13
	pop ax
	pop dx
	ret


disk_read:

    push ax                             ; Save registers we will modify
    push bx
    push cx
    push dx
    push di

    push cx                             ; We push CX twice because the previous operations didn't push CX to the top of the Stack
    call lba2chs                     ; Compute the CHS
    pop ax                              ; AL = number of sectors to read
    
    mov ah, 0x02
    mov di, 3                           ; Retry count

.r:
    pusha                               ; Save all registers, we don't know what BIOS modifies
    stc                                 ; set carry flag, some BIOS'es don't set it
    int 0x13                             
    jnc .fin                           ; If there's no error pop sll the registers off the stack

    ; The Read failed, so we pop all the registers off the stack and then reset the disk.
    popa
    call disk_reset

    dec di 			; Decrement the counter
    test di, di
    jnz .r

.fail:
    ; All attempts are exhausted
    jmp floppy_error

.fin:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax                             ; Restore registers modified
	ret

;==========================================
; Bootloader Subroutines
;==========================================

bootloader_print:
	pusha 			; We push all general registers to the stack

.repeat: 		; Continue until all characters have been printed
	lodsb	; Load the string byte from si into al
	or al, al		; We check to see if al is 0 (no more characters to print). cmp al, 0 should also work.
	jz .done 		; If that's true we jump to .done
	mov ah, 0x0e 	; We tell INT 10H that we want to start printing characters
	int 0x10 		; Video Interrupt
	jmp .repeat 	; Jump back to .repeat

.done: 		; Finish printing characters
	popa 		; We pop all the general registers back
	ret			; We return to where we were before

reboot:
	mov ax, 0x00 	; Wait for keystroke
	int 0x16
	mov ax, 0x00
	int 0x19 	; Reboot System

lba2chs:

	push ax
	push dx

	xor dx, dx 		; DX = 0

	div word [sectors_per_track] 	; When we divide a word the result gets stored in AX and DX.
									; AX is the normal division (In this case LBA / SPT), and DX is the modulo result (LBA % SPT)
	inc dx 		; We increment DX to get (LBA % SPT) + 1, which is our sector
	mov cx, dx

	xor dx, dx
	div word [heads] 	; We now divide our heads. AX: (LBA / SPT) / heads, DX: (LBA / SPT) % heads. This actually gives us our heads and cylinder. AX is our cylinders, and DX is our heads
						; Though we still need to put these values into the CL, and CH registers
	mov dh, dl 		; DH = heads

	mov ch, al 		; CH = cylinder (lower 8 bits)
	shl ah, 6 		; We preform the SHift Left instruction on ah, which should give us the upper two bits of the cylinder
					; Remember that AX already has the value of the cylinders stored, due to our last division
	or cl, ah		; put upper two bits of the cylinder in CL

	pop ax
	mov dl, al 		; We restore DL, since you cannot push and pop 8 bit registers off the stack, and we need DH to store our heads
	pop ax
	ret

BOOTDEV db 0 	; The boot device number, 0 for the A drive (AKA floppy disk)
KERNEL_CLUSTER dw 0 	; The cluster of the file we want to load

KERN_FILENAME db "LWDKRNL BIN" 	; Filenames in MS-DOS [And older OSes similar to] had to be 11 bytes long, like our Volume label, remember

msg_booting db "Booting LWD_DOS...", 0x0d, 0x0a, 0 ; 0x0D and 0x0A form what is equivilant to a C++ endl. And 0 is the null terminator
msg_flpy_err db "DISK ERROR!", 0
msg_kern_not_found db "LWDKRNL.BIN NOT FOUND !", 0x0d, 0x0a, 0

KERNEL_SEGMENT equ 0x2000
KERNEL_OFFSET equ 0x0000

times 510 - ($-$$) db 0 ; Pad out the rest of the program with 0s
dw 0xaa55 ; Boot Signature

BUFFER: 		; Where we will load the Root_Directory into memory
