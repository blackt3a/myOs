;-------------loader & kernel -------------

LOADER_BASE_ADDR      equ  0x900
LOADER_START_SECTOR   equ  0x2

;--------------gdt 描述符属性--------------------------------
;指明使用4KB的颗粒度
DESC_G_4K             equ  1000_0000_0000_0000_0000_0000b

;数段上，指明使用32位寄存器
DESC_D_32             equ   100_0000_0000_0000_0000_0000b

;32位或64位
DESC_L                equ    00_0000_0000_0000_0000_0000b
;64位代码标记，此处标记位0便可

;是否可用，暂时用不到
DESC_AVL              equ      0000_0000_0000_0000_0000b
;cpu不用此位，暂时置为0

;------------------------段界限--------------------------
DESC_LIMIT_CODE2      equ      1111_0000_0000_0000_0000b
DESC_LIMIT_DATA2      equ  DESC_LIMIT_CODE2 ;同上
;VIDEO显示用
DESC_LIMIT_VIDEO2     equ       000_0000_0000_0000_0000b

;------------------------该段存在------------------------
DESC_P                equ           1000_0000_0000_0000b

;---------------------DPL权限----------------------------
DESC_DPL_0            equ           0000_0000_0000_0000b
DESC_DPL_1            equ           0100_0000_0000_0000b
DESC_DPL_2            equ           1000_0000_0000_0000b
DESC_DPL_3            equ           1100_0000_0000_0000b
;----------------------------------------------------------

;--------------------是否系统段----------------------------
DESC_S_CODE           equ              1_0000_0000_0000b
DESC_S_DATA           equ  DESC_S_CODE
DESC_S_sys            equ              0_0000_0000_0000b
DESC_TYPE_CODE        equ                1000_0000_0000b
;x=1.e=0.w=0.a=0 数据可执行，向上拓展，可写，已访问位a清零

DESC_TYPE_DATA        equ                0010_0000_0000b
;x=0.e=0.w=1.a=0 数据不可执行，向上拓展，可写，已访问位a清零
;-----------------------------------------------------------


;----------------------为代码段各个位赋值--------------------------
DESC_CODE_HIGH4       equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + \
DESC_L + DESC_AVL + DESC_LIMIT_CODE2 + \
DESC_P + DESC_DPL_0 + DESC_S_CODE + \
DESC_TYPE_CODE + 0x00

;----------------------为数据段各个位赋值--------------------------
;0x00是8位，左移24位后整个变32位

DESC_DATA_HIGH4       equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + \
DESC_L + DESC_AVL + DESC_LIMIT_DATA2 + \
DESC_P + DESC_DPL_0 + DESC_S_DATA + \
DESC_TYPE_DATA + 0x00


;-----------------------同上--------------------------------------
DESC_VIDEO_HIGH4      equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + \
DESC_L + DESC_AVL + DESC_LIMIT_VIDEO2 + DESC_P + \
DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x0b
;说实话，这里作者就有点坑，我怎么算16～23位也不是0x00,翻实体书上，也是0x00
;翻他随书代码，果然是0xb,我严重怀疑这是作者的反盗版安全措施

;--------选择子属性---------
RPL0                  equ 00b
RPL1                  equ 01b
RPL2                  equ 10b
RPL3                  equ 11b

;GDT或LDT
TI_GDT                equ 000b
TI_LDT                equ 100b


