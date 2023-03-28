;代码0-1

section my_code vstart=0
;通过远跳转的方式给代码寄存器CS赋值0x90
  jmp 0x90:start

  start:    ;标号start只是为了jmp跳到下一条指令

  ;初始化数据寄存器DS
  mov ax,section.my_data.start
  add ax,0x900    ;加0x900是因为本程序会被mbr加载到0x900处
  shr ax,4        ;提前右移4位，因为段基址会被CPU段部件左移4位
  mov ds,ax

  ;初始化段寄存器SS
  mov ax,section.my_stack.start
  add ax,0x900    ;加0x900是因为本程序会被mbr加载到内存0x900处
  shr ax,4        ;提前右移4位，因为段基址会被CPU段部件左移4位
  mov ss,ax
  mov sp,start_top    ;初始化栈指针

  ;此时CS,DS,SS段寄存器已经完成初始化，下面开始正式工作
  push word [var2]  ;变量var2编译后变成0x4
  jmp $

  ;自定义的数据的数据段

section my_data align=16 vstart=0
  var1 dd 0x1
  var2 dd 0x6

  ;自定义的栈段
section my_stack align=16 vstart=0
  times 128 db 0

stack_top:    ;此处用于栈顶，标号作用域是当前section
              ;以当前section的vstart为基数
