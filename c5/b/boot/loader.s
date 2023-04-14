;----------------创建页目录及页表----------------
setup_page:
;先把页目录占用的空间逐字节清零(1页=4K，16进制位0x1000)
  mov ecx,  4096
  mov esi,  0

;注意，此时的我们是从0x100000处开始的
.clear_page_dir:
  mov byte [PAGE_DIR_TABLE_POS + esi].  0
  inc esi
  loop  .clear_page_dir

;开始创建页目录项(PDE)
.create_pde:    ;创建Page Directory Entry
  mov eax,  PAGE_DIR_TABLE_POS
  add eax,  0x1000    ;此时eax为第一个页表的位置及属性
  mov ebx,  eax       ;此处位ebx赋值，是为.create_pte做准备,ebx为基址
                      ;此时ebx也是第一个页表的地址

;下面将页目录项0和0xc00都存为第一个页表的位置，每个页表表示4MB内存
;这样,0xc03fffff以下的地址和0x003fffff以下的地址都指向相同的页表
;这是为将地址映射为内核做准备
;页目录项的属性RW和P位为1,US为1,表示用户属性，所有特权级都可访问该页
  or eax, PG_US_U | PG_RW_W | PG_P    ;即0x101007

  mov [PAGE_DIR_TABLE_POS + 0x0], eax   ;第一个目录项
  ;在页目录表中的第一个页目录项写入第一个页表的位置(0x101000)及其属性(7)

  mov [PAGE_DIR_TABLE_POS + 0xc00], eax  ;0xc00=3072
;一个页表项占用4字节
;0xc00表示第768个页表占用的页目录项，0xc00以上的页目录项用于内核空间
;也就是页表的0xc0000000~0xffffffff共计1G属于内核
  sub eax,  0x1000      ;此时eax是页目录项的地址
  mov [PAGE_DIR_TABLE_POS + 4092],  eax ;使页目录项的最后一个指向页目录表自己的位置

;下面创建页表项(PTE)
;因为到此时我们所写的代码仍都在1M低端内存，所以需要将其映射到二级页表中
  mov ecx,  256     ;1M低端内存/每页大小4K = 256
  mov esi,  0
  mov edx,  PG_US_U | PG_RW_W | PG_P  ;属性为7,US=1,RW=1,P=1
;为每一个页赋值属性，

.create_pde:      ;创建Page Table Entry
;此时ebx为第一个页表的地址
  mov [ebx+esi*4]，edx    ;在循环中，也是每个页的地址
  add edx,4096  ;此时ebx已经通过上面eax的赋值为0x101000，也就是第一个页表的地址
  inc esi       ;开始创建页表，每个4BYTE
  loop .create_pde

  mov eax,  PAGE_DIR_TABLE_POS
  add eax,  0x2000      ;此时eax为第二个页表的位置
  or  eax,  PG_US_U | PG_RW_W | PG_P  ;页目录项的属性US,RW和P位都为1
                                      ;为后面每一个页赋值
  mov ebx,  PAGE_DIR_TABLE_POS
  mov ecx,  254           ;范围为第769～1022的梭鱼页目录项数量
  mov esi,  769

.create_kernel_pde:
  mov [ebx+esi*4],  eax
  inc esi
  add eax,0x1000      ;4096,这作者一会儿16进制，一会儿十进制。
  loop .create_kernel_pde
  ret
;到此，一共三张完整的jk页表，一张用于页目录项，一张用户，一张系统



;---------------------启用分页-------------------------
;创建页目录表并初始化页内存位图
call setup_page

;要将描述符表地址及偏移量写入内存gdt_ptr,一会儿用新地址重新加载
sgdt [gdt_ptr]      ;储存到原来gdt所有的位置,暂存

;将gdt描述符中视屏段描述符中的基地址+0xc0000000
;打印功能需实现在内核
mov ebx,  [gdt_ptr + 2]   ;gdt_ptr是48位，前两字节是偏移量，后4字节是GDT基址
or  dword [ebx + 0x18 + 4], 0xc0000000

;视屏段是第3个段描述符，每个描述符是8字节，故0x18
;段描述符的高4字节的最高位是基地制的第31～24位


;将gdt的基地制加上0xc0000000使其成为内核所在地而高地址
add esp,  0xc0000000    ;将栈指针同样映射到内核空间

;把页目录表赋值给cr3
mov eax,  PAGE_DIR_TABLE_POS
mov cr3,  eax

;在开启分页后，用gdt新的地址重新加载

lgdt  [gdt_ptr]     ;重新加载

mov byte [gs:160], 'V'  
;视屏段基地址更新，用字符V表示virtual addr

jmp $
