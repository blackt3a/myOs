;LOADER_BASE_ADDR equ 0xA000
;LOADER_START_SECTOR equ 0x2
;--------------------------------
;---------初始化寄存器-----------
SECTION MBR vstart=0x7c00
  mov ax,cx
  mov ds,ax
  mov es,ax
  mov ss,ax
  mov fs,ax
  mov sp,0x7c00
  mov ax,0xb800
  mov gs,ax
;----------初始化寄存器完成---------


;----------清屏---------------------
;利用0x06号功能，上卷全部行，则可 清屏
;--------------------------------------
;INT 0x10 功能号：0x06  功能描述：上卷窗口
;输入
;AH 功能号=0x06
;AL = 上卷的行数（如果为0.表示全部）
;BH = 上卷行属性
;（CL,CH）= 窗口左下角的（x,y）位置
;（DL,DH）= 窗口右下角的（x,y）位置
;无返回值
;VGA文本模式中，一行只能呢个容纳80个字符，共25行
  mov ax,0600h
  mov bx,0700h
  mov cx,0      ;左上
  mov dx,184fh  ;右下
  int 10h
;----------清屏结束-----------------------

;----------写入显存--------------------------
;直接写入相关内存区域即显示
  mov byte [gs:0x00],'1'
  mov byte [gs:0x01],0xa4 ;A绿色背景闪烁，4：前景为红色


  mov byte [gs:0x02],' '
  mov byte [gs:0x03],0xa4 ;A绿色背景闪烁，4：前景为红色


  mov byte [gs:0x04],'M'
  mov byte [gs:0x05],0xa4 ;A绿色背景闪烁，4：前景为红色


  mov byte [gs:0x06],'B'
  mov byte [gs:0x07],0xa4 ;A绿色背景闪烁，4：前景为红色


  mov byte [gs:0x08],'1'
  mov byte [gs:0x09],0xa4 ;A绿色背景闪烁，4：前景为红色
;------------写入显存结束---------------------------

  jmp $

  times 510-($-$$) db 0
  db 0x55,0xaa





