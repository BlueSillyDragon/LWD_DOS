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

find_root_dir:
	pusha  			; We push all the general registers to the stack, in case something important was in them before this
	mov ax, [sectors_per_fat] 	; Move the value of the sectors_per_fat into the AX register
	mov bx, [number_of_fats] 	; Move the number_of_fats into BX
	mul bx  					; AX = (number_of_fats * sectors_per_fat) = Size of the FAT reigon
	add ax, [reserved_for_boot] ; AX = (Size of Reserved_For_Boot region + FAT region) = Location of the Root_Directory [Logical sector 19]
	call lba2chs 				; Call LBA2CHS so we can read from the root_dir

	mov si, BUFFER 			; This is what we will put into ES:BX [Memory location we want to store our data]
	mov bx, ds
	mov es, bx
	mov bx, si 				; We put the buffer into BX [So now ES:BX should point ot the buffer]

	mov ah, 0x02 			; Read the disk
	mov al, 14 			; Sectors to read

	pusha 				; You know the drill by now, we need the values in these registers, need to modify them aswell, push them to the stack

	jmp $

read_root_dir:
	popa
	pusha 

	stc
	int 0x13 	; Read the disk

	jmp $

;==================================
; Bootloader Disk Read Routines
;==================================

; Read the disk. AX: LBA Address, CL: Number of sectors to read, upto 128 (Altough reasonably we won't need it to be that big)
disk_read:  		; DL: drive number, ES:BX Memory address where we want to store data
	; We push the registers we're going to modify to the stack
	; Save the CL register (Number of sectors to read)
	pusha

	push cx 		; We push CX to the stack twice because, PUSHA doesn't put it on top of the stack.
	call lba2chs 	; Calcuate CHS
	pop ax		; The sector count was saved to the stack, so we pop it

	mov ah, 0x02 	; Tells the BIOS that we want to read from the disk when we invoke INT 13H
	mov di, 5 		; Set SI to 5, this will be our retry counter.

.retry:
	pusha
	stc 		; Some BIOS'es don't properly set the carry flag.
	int 0x13 	; We call the Disk Routines interrupt
	jnc .fin 	; If the carry flag is set to 0, then that means the we successfully read from the disk, otherwise there was an error
	popa
	call disk_reset
	dec di 		; We decrement our counter
	cmp di, 0	; We check to see if our counter is 0
	jnz .retry 	; If it's not, then we jump back to the retry label

.fail:
	jmp floppy_error

.fin:
	popa

	pop di
	pop dx
	pop cx
	pop bx
	pop ax 	; Pop the modified registers

	ret

floppy_error:
	mov si, msg_flpy_err
	call bootloader_print
	call reboot
	hlt

disk_reset:
	pusha
	mov ah, 0x00
	stc
	int 0x13
	jc floppy_error
	popa
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
	int 10h 		; Video Interrupt
	jmp .repeat 	; Jump back to .repeat

.done: 		; Finish printing characters
	popa 		; We pop all the general registers back
	ret			; We return to where we were before

reboot:
	mov ax, 0 	; Wait for keystroke
	int 0x16
	mov ax, 0
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
CLUSTER dw 0 	; The cluster of the file we want to load
POINTER dw 		; The pointer into our buffer [This is for loading the kernel]

KERN_FILENAME db "LWDKRNL BIN" 	; Filenames in MS-DOS [And older OSes similar to] had to be 11 bytes long, like our Volume label, remember

msg_booting db "Booting LWD_DOS...", 0x0d, 0x0a, 0 ; 0x0D and 0x0A form what is equivilant to a C++ endl. And 0 is the null terminator
msg_flpy_err db "DISK ERROR! PRESS ANY KEY TO RESTART", 0

times 510 - ($-$$) db 0 ; Pad out the rest of the program with 0s
dw 0xaa55 ; Boot Signature

BUFFER: 		; Where we will load the Root_Directory into memory