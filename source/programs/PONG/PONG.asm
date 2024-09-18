[org 0x0]
[bits 16]

main:
        %include "source/programs/PONG/setup.asm"
        %include "source/programs/PONG/loop.asm"
        %include "source/programs/PONG/utils.asm"

data:
        %include "source/programs/PONG/data.asm"