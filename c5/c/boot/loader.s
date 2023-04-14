







mov eax,  KERNEL_START_SECTOR ;kernel.bin所在的扇区
mov ebx,  KERNEL_BIN_BASE_ADDR  ;从磁盘读出后，写入到ebx指定的地址
mov ecx,  200   ;读入的扇区数

call rd_disk_m_32


;------------将kernel.bin中的segment拷贝到编译的地址-------
kernel_init:
  xor eax,  eax
  xor ebx,  ebx   ;ebx记录程序头表地址
  xor ecx.  ecx   ;cx记录程序头表中program header数量
  xor edx,  edx   ;dx记录program header尺寸，即e_phentsize

  mov dx, [KERNEL_BIN_BASE_ADDR + 42] ;文件偏移42字节处是e_phentsize属性，表示program header大小
  mov ebx,  [KERNEL_BIN_BASE_ADDR + 28] ;文件偏移28字节的地方是e_phoff
  ;表示第一个program header在文件中的偏移量，即使知道该值，也要采用读取来赋值

  add ebx,  KERNEL_BIN_BASE_ADDR
  mov cx,   [KERNEL_BIN_BASE_ADDR + 44] ;文件偏移44字节的地方是e_phnum,表示有几个program header

.each_segment:
  cmp byte [ebx + 0], PT_NULL ;若p_type等于PT_NULL，说明program header未使用

  je  .PTNULL

  ;为函数memcpy压入参数，参数是从右往左的
  ;参数原型 memcpy(dst,src,size)
  push dword [ebx + 16]
  ;program header中偏移16字节的地方是p_filesz
  ;压入第三个参数size

  mov eax,  [ebx + 4] ;距程序头偏移量为4字节的位置是p_offset
  add eax,  KERNEL_BIN_BASE_ADDR
  ;加上kernel.bin被加载到的物理地址，eax为该段的物理地址
  push eax  ;压入第二个参数,源地址 
  push dword [ebx + 8]  ;压入第一个参数，目的地址，程序头偏移8字节的p_vaddr

  call mem_cpy ;调用mem_cpy完成复制
  add esp, 12   ;清理栈中压入的三个参数

.PTNULL:
  add ebx,  edx     ;edx为program header大小，即e_phentsize
  loop .each_segment
  ret

;------------逐字节拷贝mem_cpy(dst,src,size)
;输入：栈中的三个参数(dst,src,size)
;输出
mem_cpy:
  cld
  push ebp
  mov ebp,  esp
  push ecx ;rep指令用到ecx,但是ecx对于外层的循环好友用，故先备份
  mov edi,  [ebp + 8] ;dst
  mov esi,  [ebp + 12] ;src
  mov ecx,  [ebp + 16]  ;size
  rep movsb
;恢复环境
  pop ecx
  pop ebx
  ret


