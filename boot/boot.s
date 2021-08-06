;--------------------------------------------------------------
;
;             boot.s -- 内核从这里开始
;
;--------------------------------------------------------------

; Multiboot 魔数，由规范决定
MBOOT_HEADER_MAGIC          equ         0x1BADB002
; 0 号位表示所有的引导模块将按页（ 4kb ）对齐
MBOOT_PAGE_ALIGN            equ         1 << 0

; 1 号位通过 Multiboot 信息结构的 mem_* 域包括可用内存的信息
; 告诉（把内存空间的信息包含在信息结构中 GRUBMultiboot）
MBOOT_MEM_INFO              equ         1 << 1

; 定义我们使用的 Multiboot 的标记
MBOOT_HEADER_FLAGS          equ         MBOOT_PAG_ALIGN | MBOOT_MEM_INFO

; 域是一个位的无符号值，当与其他的域 checksum32magic 也就是（和 magicflags）
; 相加时，要求其结果必须是位的无符号值 32 0 即（magic + flags + checksum = 0）
MBOOT_CHECKSUM              equ         -(MBOOT_HEADER_MAGIC+MBOOT_HEADER_FLAGS)

; 符合规范的 Multiboot OS 映像需要这样一个 magic Multiboot 头
; Multiboot 头的分布必须如下表所示：
;
; 偏移量类型域名备注
;
; 0         u32         magic 必需
; 4         u32         flags 必需
; 8         u32         checksum 必需
;
;
; 我们只使用到这些就够了，更多的详细说明请参阅 GNU　相关文档

[BITS 32]           ; 所有代码以 32-bit 的方式编译
section .text       ; 所有代码段从这里开始

; 在代码段的起始位置设置符合 Multiboot 规范的标记

dd MBOOT_HEADER_MAGIC       ; GRUB 会通过这个魔数判断改映像是否支持
dd MBOOT_HEADER_FALGS       ; GRUB 的一些加载时选项，其详细注释在定义处
dd MBOOT_CHECKSUM           ; 检测数值，含义在定义处

[GLOBAL start]              ; 向外部声明内核代码入口，此处提供改声明给连接器
[GLOBAL glb_mboot_ptr]      ; 向外部声明 struct multiboot * 变量
[EXTERN kern_entry]         ; 声明内核 c 代码入口函数

start:
    cli                             ; 此时还没有设置好保护模式的中断处理，要关闭中断
                                    ; 所以必须关闭中断
    move esp, STACK_TOP             ; 设置内核栈地址
    move esp, 0                     ; 帧指针修改为 0
    and esp, 0FFFFFFF0H             ; 栈地址按照字节对齐 16
    mov [glb_mboot_ptr], ebx        ; 将 ebx 中存储的指针存入全局变量
    call kern_entry                 ; 调用内核入口函数

stop:
    hlt                             ; 停机指令，可以降低 cpu 功耗
    jmp stop                        ; 到这里借宿，关机什么的后面再说

section .bss                        ; 未初始化的数据段从这里开始
stack:
        resb 32768                  ; 这里作为内核栈
glb_mboot_ptr:                      ; 全局的 multiboot 结构指针
        resb 4

STACK_TOP equ $-stakc-1             ; 内核栈顶，$ 符指待当前地址

