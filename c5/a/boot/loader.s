%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR  ;加载的位置
LOADER_STACK_TOP equ LOADER_BASE_ADDR


;--------构建GDT及其内部描述符---------------
  GDT_BASE:   dd   0x00000000 
              dd   0x00000000 

  CODE_DESC:  dd   0x0000ffff
              dd   CODE_DESC_HIGH4

  DATA_STACK_DESC:  dd   0x0000ffff
                    dd   CODE_DATA_HIGH4

  VIDEO_DESC: dd   0x80000007
              dd   DESC_VIDEO_HIGH4

  GDT_SIZE  equ $ - GDT_BASE
  GDT_LIMIT equ GDT_SIZE - 1

  times 60  dq  0

  SELECTOR_CODE  equ (0x0001<<3) + TI_GDT + RPL0
  SELECTOR_DATA  equ (0x0002<<3) + TI_GDT + RPL0
  SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0

;total_mem_bytes用于保存内存容量，以字节为单位，此位置比较好记
;当前偏移loader.bin头文件0x200字节
;loader.bin的加载地址是0x900
;故total_mem_bytes的地址是0xb00
;将来在内核中会引用此地址

  total_mem_bytes dd 0

;以下是定义gdt的指针，前两个字节是gdt界限，后四个字节是gdt起始地址
  gdt_ptr dw  GDT_LIMIT
          dd  GDT_BASE

;人工对齐：total_mem_bytes4+gdt_ptr6+ards_buf244+ards_nr2,共256字节
  ards_buf times 244 db 0
  ards_nr  dw   0   ;用于记录ARDS结构体数量

  loader_start:
;int 15h, eax = 0000E820, edx = 534D4150h('SMAP') 获取内存
;第一次调用时，ebx值要为0
;edx只赋值一次，:循环体中不会改变
  xor ebx,  ebx
  mov edx,  0x534d4150
  mov di ,  ards_buf    ;ards结构缓冲区

;循环获取每个ARDS内存范围描述符结构
.e820_mem_get_loop:
;执行完前面int 0x15后，eax值变为0x534d4150
;所以每次执行完int前都要更新为子功能号
  mov eax,  0x0000e820   
  mov ecx,  20    ;ARDS地址范围描述符结构大小是20字节
  int 0x15
;若cf位为1,则有错误发生，尝试0xe801子功能
  jc  .e820_failed_so_try_e801      ;gc指令是Jump if Carry
  add di ,  cx     ;使di增加20字节指向缓冲区中新ARDS结构位置
  inc  word [ards_nr]   ;记录ARDS数量
  cmp ebx,  0           ;若ebx为0且cf不为1,说明ards全部返回,当前已是最后一个


;在出所有ards结构中,找出(base_add_low+length_low)的最大值，即内存容量
  jnz .e820_mem_get_loop

;遍历每一个ARDS结构体，循环次数是ARDS的数量
  mov cx ,  [ards_nr]
  mov ebx,  ards_buf
  xor edx, edx    ;edx为最大的内存容量，在此先清零

;无需判断type是否为1,最大的内存一定是可以使用的
.find_max_mem_area:
  mov eax,  [ebx]     ;base_add_low
  add eax.  [ebx+8]   ;length_low
  add ebx,  20        ;指向缓冲区中下一个ARDS结构
  cmp edx,  eax       ;冒泡排序，找出最大，edx寄存器始终是最大的内存容量
  jge .next_ards
  mov edx,  eax       ;edx为总内存大小

.next_ards:
  loop  .find_max_mem_area
  jmp   .mem_get_ok

;------int 15h, ax = E801h获取内存大小，最大支持4G
;返回后，ax和cx的值一样，以KB为单位，bx和cx值一样，以64KB为单位
;在ax和cx寄存器中为低16MB,在bx和dx寄存器中为16MB到4GB
.e820_failed_so_try_e801:
  mov ax, 0xe801
  int 0x15
  jc  .e801_failed_so_try_88    ;若当前e801方法失败，就尝试0x88方法


;1.先算出低15MB的内存
;ax和cx中以KB为单位的内存数量，将其转换为以byte为单位
  mov cx ,  0x400
  mul cx
  shl edx,  16
  and eax,0x0000ffff
  or edx, eax
  add edx,0x100000    ;ax只是15MB,所以还要加1MB
  mov esi,edx         ;先把低15MB的内存容量存入esi寄存器备份


;2.再将16MB以上的内存准换为byte为单位，寄存器bx和dx中以64KB为单位的内存数量
  xor eax,  eax
  mov ax ,  bx
  mov ecx 0x10000     ;0x10000十进制就是64KB
  mul ecx             ;32位乘法，默认的被除数是eax,积为64位
                      ;高32位存入edx,低32位存入eax.

  add esi,  eax       ;由于此方法只能测出4GB内的内存，故32位eax足够了
                      ;edx肯定为0,只加eax便可
  mov edx,  esi       ;edx为总内存大小
  jmp .mem_get_ok


;-----------int 15h, ah = 0x88获取内存大小，只能是64MB之内
.e801_failed_so_try_88:
  mov ah ,  0x88
  int 0x15
  jc  .error_hlt    ;hlt挂起
  and eax,  0x0000ffff

;16位乘法，被乘数是ax,积为32位，积的高16位在dx中，低16位在ax中
  mov cx ,  0x400   ;0x400=1024,将ax中的内存容量换位byte为单位
  mul cx
  shl edx,  16      ;把dx移到高16位
  or edx,eax        ;把积的低16位组合到edx,为32位的积
  add edx,0x100000  ;0x88子功能只会返回1MB以上的内存,所以要加1MB

.mem_get_ok:
  mov [total_mem_bytes],  edx
  
