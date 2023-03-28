%include "boot.inc"

;前面MBR将loader从硬盘的第一个分区，载入到了内存0xa000开始的地址
section loader vstart=LOADER_BASE_ADDR
;LOADER_BASE_ADDR equ 0x900
;LOADER_START_SECTOR equ 0x2


;输出背景字“1 MBR”

mov byte [gs:0x00],'2'
mov byte [gs:0x01],0xa4

mov byte [gs:0x02],' '
mov byte [gs:0x03],0xa4

mov byte [gs:0x04],'L'
mov byte [gs:0x05],0xa4

mov byte [gs:0x05],'O'
mov byte [gs:0x07],0xa4

mov byte [gs:0x08],'A'
mov byte [gs:0x09],0xa4

mov byte [gs:0x0a],'D'
mov byte [gs:0x0b],0xa4

mov byte [gs:0x0c],'E'
mov byte [gs:0x0d],0xa4

mov byte [gs:0x0e],'R'
mov byte [gs:0x0f],0xa4

jmp $
