ASM=nasm

SRC_DIR=source
BUILD_DIR=build

.PHONY: all floppy_image bootloader kernel setup clean always

#
# Floppy
#
floppy_image: $(BUILD_DIR)/LWD_DOS.img

$(BUILD_DIR)/LWD_DOS.img: bootloader kernel setup pong
	dd if=/dev/zero of=$(BUILD_DIR)/LWD_DOS.img bs=512 count=2880
	mkfs.fat -F 12 -n "LWD_DOS" $(BUILD_DIR)/LWD_DOS.img
	dd if=$(SRC_DIR)/boot/LWDBOOT.bin of=$(BUILD_DIR)/LWD_DOS.img conv=notrunc
	mcopy -i $(BUILD_DIR)/LWD_DOS.img $(SRC_DIR)/LWDKRNL.bin "::LWDKRNL.bin"
	mcopy -i $(BUILD_DIR)/LWD_DOS.img $(SRC_DIR)/programs/SETUP.bin "::SETUP.bin"
	mcopy -i $(BUILD_DIR)/LWD_DOS.img $(SRC_DIR)/programs/PONG.bin "::PONG.bin"

#
# Bootloader
#
bootloader: $(SRC_DIR)/LWDBOOT.bin

$(SRC_DIR)/LWDBOOT.bin:
	$(ASM) $(SRC_DIR)/boot/LWDBOOT.asm -f bin -o $(SRC_DIR)/boot/LWDBOOT.bin 

#
# Kernel
#
kernel: $(SRC_DIR)/LWDKRNL.bin

$(SRC_DIR)/LWDKRNL.bin:
	$(ASM) $(SRC_DIR)/LWDKRNL.asm -f bin -o $(SRC_DIR)/LWDKRNL.bin

# Programs

#
# Setup
#
setup: $(SRC_DIR)/SETUP.bin

$(SRC_DIR)/SETUP.bin:
	$(ASM) $(SRC_DIR)/programs/SETUP.asm -f bin -o $(SRC_DIR)/programs/SETUP.bin

#
# Pong
#
pong: $(SRC_DIR)/PONG.bin

$(SRC_DIR)/PONG.bin:
	$(ASM) $(SRC_DIR)/programs/PONG/PONG.asm -f bin -o $(SRC_DIR)/programs/PONG.bin

#
# Run
#
run: floppy_image
	qemu-system-i386 -fda $(BUILD_DIR)/LWD_DOS.img


#
# Always
#
always: 
	mkdir -p $(BUILD_DIR)

#
# Clean
#
clean: 
	rm -rf $(BUILD_DIR)/*
	rm $(SRC_DIR)/boot/LWDBOOT.bin
	rm $(SRC_DIR)/LWDKRNL.bin
