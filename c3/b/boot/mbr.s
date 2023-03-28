;LOADER_BASE_ADDR equ 0x900
;LOADER_START_SECTOR equ 0x2
;--------------------------------

%include "boot.inc"

;--------初始化寄存器-------------
SECTION MBR vstart=0x7c00
  mov ax,cs         ;别照着抄都写错o.0,cpu初始化，cs=0
  mov ds,ax
  mov es,ax
  mov ss,ax
  mov fs,ax
  mov sp,0x7c00
  mov ax,0xb800
  mov gs,ax
;---------寄存器初始化完成----------



;------------清屏---------------
;功能号 0x06,上卷全部行，实现清屏
;---------------------------------
;INT 0x10 功能号:0x06 功能描述：上卷窗口
;----------------------------------------
;输入
;AH 功能号 = 0x06
;AL = 上卷行数
;BH = 上卷行属性
;(CL,CH)左上角
;(DL,DH)右下角
;无返回值

  mov ax,0600h
  mov bx,0700h
  mov cx,0      ;左上(0,0)
  mov dx,184fh  ;右下(80,25)
  int 10h
;在VGA文本模式中，一行只能容纳80个字符，共25行
;-------------清屏节结束---------------

;------------输出字符串------------------------
;直接写入显卡VGA模式映射的内存中
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
;---------------输出字符串结束------------------------


;-------------读取硬盘n个扇区-------------------
  mov eax,LOADER_START_SECTOR ; 读取地址：起始扇区lba地址0x2
  mov bx,LOADER_BASE_ADDR ;写入的目的地址
  mov cx,1  ;待写入的扇区数
  call rd_disk_m_16   ;读取程序

;--------------读取结束--------------------------


;--------------跳转到loader------------------
  jmp LOADER_BASE_ADDR

;--------------读取程序的实现开始----------------
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
;往0x1f2端口写入要读取的扇区数1

  mov eax,esi ;恢复ax

;第二步，将LBA地址存入0x1f3~0x1f6（LBA寄存器储存扇区起始的24位地址）
  ;LBA地址7～0位写入端口0x1f3
  mov dx,0x1f3
  out dx,al ;0x2

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
  in al,dx  ;读取0x1f7的状态
  and al,0x88 ;第4位为1表示硬盘控制器已准备好数据传输(10001000)
  ;将返回结果中第4和第7位不变，其他位置0。
  ;第7位为1表示硬盘忙
  cmp al,0x08
  jnz .not_ready  ;若未准备好，继续等待

;第五步：从0x1f0端口读入数据
  mov ax,di         ;这里数值为1
  mov dx,256
  mul dx
  mov cx,ax

;di为要读取的扇区数，一个扇区有512字节，每次输入一个字，共需di*512/2次，所以di*256
;ax是16位，每次两个字节
  mov dx,0x1f0

;-------------循环读取---------------------
.go_on_read:
  in ax,dx
  mov [bx],ax     ;写入地址
  add bx,2
  loop .go_on_read
  ret
;-------------循环读取结束------------------


  times 510-($-$$) db 0
  db 0x55,0xaa





