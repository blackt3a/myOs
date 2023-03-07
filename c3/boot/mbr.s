;LOADER_BASE_ADDR equ 0xa000
;LOADER_START_SECTOR equ 0x2
;--------------------------------

%include "boot.inc"


SECTION MBR vstart=0x7c00
  mov ax,cx
  mov ds,ax
  mov es,ax
  mov ss,ax
  mov fs,ax
  mov sp,0x7c00
  mov ax,0xb800
  mov gs,ax
;即，将寄存器初始化（为0x7c00

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


  mov eax,LOADER_START_SECTOR ;起始扇区lba地址
  mov bx,LOADER_BASE_ADDR ;写入的地址
  mov cx,1  ;代写入的扇区数
  call rd_disk_m_16   ;读取程序

  jmp LOADER_BASE_ADDR

;-------------------------
;功能：读取n个扇区
;eax=LBA扇区号，bx=将数据写入的内存地址，cx读入的扇区数
rd_disk_m_16:
  mov esi,eax ;备份eax
  mov di,cx ;备份cx
;读写硬盘
;第一步：设置要读写的扇区数
  mov dx,0x1f2
  mov al,cl
  out dx,al   ;读取的扇区数

  mov eax,esi ;恢复ax

;第二步，将LBA地址存入0x1f3~0x1f6
  ;LBA地址7～0位写入端口0x1f3
  mov dx,0x1f3
  out dx,al

  ;LBA地址15～8位写入端口0x1f4
  mov cl,8
  shr eax,cl
  mov dx,0x1f4
  out dx,al

  ;LBA地址23～16位写入端口0x1f5
  shr eax,cl
  mov dx,0x1f5
  out dx,al

  shr eax,cl
  and al,0x0f ;LBA第24～27位
  or al,0xe0  ;设置7～4位为1110,表示LBA模式
  mov dx,0x1f6
  out dx,al

;第三步：向0x1f7端口写入读命令，0x20
  mov dx,0x1f7
  mov al,0x20
  out dx,al

;第四步，检测硬盘状态
  .not_ready:
  ;同一端口，写时表示写入命令字，读时表示读入硬盘状态
  nop
  in al,dx
  and al,0x88 ;第4位为1表示硬盘控制器已准备好数据传输
  ;第7位为1表示硬盘忙
  cmp al,0x08
  jnz .not_ready  ;若未准备好，继续等待

;第五步：从0x1f0端口读入数据
  mov ax,di
  mov dx,256
  mul dx
  mov cx,ax

;di为要读取的扇区数，一个扇区有512字节，每次输入一个字，共需di*512/2次，所以di*256
  mov dx,0x1f0
.go_on_read:
  in ax,dx
  mov [bx],ax
  add bx,2
  loop .go_on_read
  ret



  times 510-($-$$) db 0
  db 0x55,0xaa





