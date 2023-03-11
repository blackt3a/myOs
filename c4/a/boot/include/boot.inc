;-------------loader & kernel -------------

LOADER_BASE_ADDR      equ  0x900
LOADER_START_SECTOR   equ  0x2

;--------------gdt 描述符属性----
DESC_G_4K             equ  1000_0000_0000_0000_0000_0000b
DESC_D_32             equ   100_0000_0000_0000_0000_0000b
DESC_L                equ    00_0000_0000_0000_0000_0000b
;64位代码标记，此处标记位0便可

DESC_AVL              equ      0000_0000_0000_0000_0000b
;cpu不用此位，暂时置为0

DESC_LIMIT_CODE2      equ      1111_0000_0000_0000_0000b
DESC_LIMIT_DATA2      equ  DESC_LIMIT_CODE2
DESC_LIMIT_VIDEO2     equ       000_0000_0000_0000_0000b
DESC_P                equ           1000_0000_0000_0000b

DESC_DPL_0            equ           0000_0000_0000_0000b
DESC_DPL_1            equ           0100_0000_0000_0000b
DESC_DPL_2            equ           1000_0000_0000_0000b
DESC_DPL_3            equ           1100_0000_0000_0000b

DESC_S_CODE           equ              1_0000_0000_0000b
DESC_S_DATA           equ  DESC_S_CODE
DESC_S_sys            equ              0_0000_0000_0000b
DESC_TYPE_CODE        equ                1000_0000_0000b
;x=1.e=0.w=0.a=0 数据可执行，向上拓展，可写，已访问位a清零

DESC_TYPE_DATA        equ                0010_0000_0000b

;x=0.e=0.w=1.a=0 数据不可执行，向上拓展，可写，已访问位a清零

DESC_CODE_HIGH4       equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + \
DESC_L + DESC_AVL + DESC_LIMIT_CODE2 + \
DESC_P + DESC_DPL_0 + DESC_S_CODE + \
DESC_TYPE_CODE + 0x00

DESC_DATA_HIGH4       equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + \
DESC_L + DESC_AVL + DESC_LIMIT_DATA2 + \
DESC_P + DESC_DPL_0 + DESC_S_DATA + \
DESC_TYPE_DATA + 0x00

DESC_VIDEO_HIGH4      equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + \
DESC_L + DESC_AVL + DESC_LIMIT_VIDEO2 + DESC_P + \
DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x00

;--------选择子属性---------
RPL0                  equ 00b
RPL1                  equ 01b
RPL2                  equ 10b
RPL3                  equ 11b

TI_GDT                equ 000b
TI_LDT                equ 100b


