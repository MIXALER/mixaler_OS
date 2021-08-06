#! Makefile

C_SOURCES = $(shell find . -name "*.c") # 查找后缀为 .c 的文件
C_OBJECTS = $(patsubst %.c, %.o, $(C_SOURCES)) # 替换以 .c 结尾的变量为 .o 结尾的变量
S_SOURCES = $(shell find .  -name "*.s") # 查找后缀为 .s 的文件
S_OBJECTS = $(patsubst %.s, %.o, $(S_SOURCES))

CC = gcc # 编译器
LD = ld # 连接器
ASM = nasm # 汇编器

C_FLAGS = -c -Wall -m32 -ggdb -gstabs+ -nostdinc -fno-builtin -fno-stack-protector -I include  # gcc 编译参数

LD_FLAGS = -T scripts/kernel.ld -m elf_i386 -nostdlib # ld 链接参数

ASM_FLAGS = -f elf -g -F stabs # nasm 汇编参数

all : $(S_OBJECTS) $(C_OBJECTS) link update_image

.c .o:
	@echo	编译代码文件 $< ...
	$(CC) $(C_FLAGS) $< -o $@

.s .o:
	@echo	编译汇编文件 $< ...
	$(ASM) $(ASM_FLAGS) $<


link:
	@echo 链接内核文件...
	$(LD) $(LD_FLAGS) $(S_OBJECTS) $(C_OBJECTS) -o mix_kernel

.PHONY:clean
clean:
	$ (RM) $(S_OBJECTS) $(C_OBJECTS) mix_kernel

.PHONY:update_image
update_image:
	mount floppy.img /mnt/kernel
	cp mix_kernel /mnt/kernel/mix_kernel
	sleep 1
	unmount /mnt/kernel

.PHONY:mount_image
mount_image:
	mount floppy.img /mnt/kernel

.PHONY:unmount_image
unmount_image:
	umount /mnt/kernel

.PHONY:qemu
qemu:
	qemu -fda floppy.img -boot alias

.PHONY:bochs
bochs:
	bochs -f tools/bochsrc.txt

.PHONY:debug
debug:
	qemu -S -s -fda floppy.img -boot a &
	sleep 1
	cgdb -x tools/gdbinit