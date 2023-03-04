
;主引导程序
;----------------------------------
SECTION MBR vstart=0x7c00
  mov ax,cx
  mov ds,ax
  mov es,ax
  mov ss,ax
  mov fs,ax
  mov sp,0x7c00

;清屏利用0x06号功能，上卷全部行，实现清屏
;INT 0x10 功能号：0x6 功能描述：上卷窗口
;
;输入 AH 功能号; BH：上卷的行数
;BH 上卷行数属性; （CL,CH）左上角位置，（DL,DH）右下角位置

  mov ax,0x600
  mov bx,0x700
  mov cx,0

  int 0x10

;获取光标位置
  mov ah,3
  mov bh,0

  int 0x10

;打印字符串
  mov ax,message
  mov bp,ax

; 光标位置要用到dx寄存器，cx中的光标位置可忽略
  mov cx,5
  mov ax,0x1301
  mov bx,0x2
  int 0x10

;打印字符串结束
  jmp $

  message db "1 MBR"
  times 510-($-$$) db 0

  db 0x55,0xaa


