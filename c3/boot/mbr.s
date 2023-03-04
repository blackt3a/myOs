;LOADER_BASE_ADDR equ 0xa000
;LOADER_START_SECTOR equ 0x2
;--------------------------------

SECTION MBR vstart=0x7c00
  mov ax,cx
  mov ds,ax
  mov es,ax
  mov ss,ax
  mov fs,ax
  mov sp,0x7c00
  mov ax,0xb800
  mov gs,ax

;功能号 0x06,上卷全部行，实现清屏
;use 0x10,上卷全部行
;AH 功能号
;AL 上卷行数
;上卷行属性
;(CL,CH)左上角，(DL,DH)右下角

  mov ax,0600h
  mov bx,0700h
  mov cx,0      ;左上
  mov dx,184fh  ;右下
  int 10h



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


  jmp $

  times 510-($-$$) db 0
  db 0x55,0xaa





