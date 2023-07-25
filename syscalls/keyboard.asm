;==============================================================
; The LWD Disk Operating System Keyboard System Calls.
; Copyright (c) 2023 BlueSillyDragon
;==============================================================

os_keystroke:

    mov ah, 0x00
    int 0x16

    ret

; IN: SI = input buffer
; OUT: string 

os_input_string:

.setup:
    pusha

    mov di, ax      ; DI is where our input will be stored
    mov cx, 0

.get_string:
    call os_keystroke
    
    cmp al, 13
    je near .done

.no_enter:
    pusha
    mov ah, 0x0e
    int 0x10
    popa

    stosb       ; Store character into our buffer
    inc cx
    cmp cx, 30
    jae .done

    jmp .get_string

.done:
    mov ax, 0  ; Terminator
    stosb

    popa
    ret


