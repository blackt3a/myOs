在Linux获取内存的方法不止一种，一种不行就换另一种

1. EAX=0xE820    便历主机全部内存

  其返回的地址范围描述符(Address Range Descriptor Structure, ARDS) 如下：(注意，此字段大小为20字节，表中基地址和长度都分为低32位和高32位)

  ![](https://i.imgur.com/P4P4T4m.png)

  ![](https://i.imgur.com/h8XELRv.png)

  BIOS按类型返回内存信息，因为其内存可能是：

  - 系统的ROM
  - ROM用到了这部分内存
  - 设备内存映射到了这部分内存
  - 由于某些原因，这段内存不适合标准设备使用

  由于我们在32位的工作环境下，所以在`ARDS`结构属性中，我们只用到32位属性。`BaseAddrLow+LengthLow`是一片内存区域上限，单位是字节。除非安装的物理内存极小，否则不会出现较大的内存区域不可用

  调用方法：

  ![](https://i.imgur.com/CypG7HS.png)

  ![](https://i.imgur.com/jAoc4wy.png)

  表中的ECX寄存器和ES：DI寄存器，是典型的“值-结果”型参数，即调用方提供两个变量作为被调用函数的参数，一个是缓冲区指针，一个是缓冲区大小。被调用函数在缓冲区中写入数据后，将实际所写入的字节数记录到缓冲区大小变量中。

  中断步骤如下：

  - 填写“调用前输入”中的寄存器
  - 执行中断调用`int 0x15`
  - 在CF位为0的情况下，“返回后输出”中对应的寄存器便会有对应的结果

  

2. AX  =0xE801    分别检测第`15MB`和`16MB～4GB`的内存，最大支持`4GB`

此法简单，但功能也不强大，最多只识别`4GB`内存。特别的是，此法检测的内存是分别存放到两组寄存器中的。低于`15MB`的内存以`1KB`为单位来记录，单位数量在AX和CX寄存器中记录(其中，AX和CX的值是一样的)，所以在`15MB`空间以下的实际内存容量=AX*`1024`。AX,CX最大值为`0x3c00`(即`0x3c00*1024=15MB`

`16MB~4GB`是以`64KB`为单位大小来记录的，单位数量在寄存器BX和DX中记录(其中BX和DX的值是一样的)，所以`16MB`以上的空间的内存实际大小=`BX*64*1024`，BX和DX的最大值，其实无所谓，反正只支持`4GB`最大。

![](https://i.imgur.com/oPsXPzt.png)

​		关于为什么`0xE801`调用显得有点奇怪，也是因为历史遗留的兼容问题。在80286时期(其寻址大小为`16MB`，此时有些ISA设备需要用到`15MB`以上的内存作为缓冲区，此缓冲区`1MB`大小，硬件系统将其保留下来，操作系统不可使用，形成内存空洞(memory hole)。此兼容一直持续到现在。使用`0xE801`也是因为支持拓展ISA设备的支持。

实际内存大于`16MB`时，能检测出内存空洞。但是实际内存小于`16MB`时，检测出的内存仍然会小一些，此时实际结果比检测结果多`1MB`（并没有少，可用，只是显示得少了）

`0xE801`的调用步骤：

- 将AX寄存器写入`0xE801`
- 执行中断调用int 0x15
- 在CF位为0的情况下，“返回后输出”中对应的寄存器便会有对应的结果





3. AH=0x88          最多检测`64MB`内存，实际内存超过此容量也按照`64MB`返回

此方法使用最简单，功能也最简单，最多检测`64MB`的内存

![](https://i.imgur.com/oPsXPzt.png)

即便内存容量大于`64MB`也只会显示`63MB`的内存，显示`1MB`之上的内存，不包括这`1MB`。

中断调用步骤：

- 将AX寄存器写入0x88
- 执行中断用int 0x15
- 在CF为0的情况下，“返回后输出”中对应的寄存器便会有对应的结果



分页机制

关于换入换出



页表

![](https://i.imgur.com/Xy7ema7.png)

![](https://i.imgur.com/IkaejGY.png)

经转换，物理地址变为虚拟地址



线性地址空间，指程序内部内存空间(不同任务可能有相同线性空间,却不会影响)

虚拟地址空间，指对物理地址的映射

物理地址空间，指内存条上的线性空间



一个页表项4字节大小

![](https://i.imgur.com/ZYMweJe.png)



关于一级页表

线性地址的高`20`位在页表中，索引页表项，用线性地址中的低`12`位与页表项中的物理地址相加，所求和就是线性地址最终的物理地址

![](https://i.imgur.com/ZDyoKhR.png)



关于二级页表

二级页表的理由：

- 一级页表中最多可以容纳$2^{20}=1M$个页表项，每个页表项4KB大小，若页表全满，其大小为4MB.
- 一级页表中所有页表都需要提前建好，因为操作系统需要使用4GB虚拟地址的高1GB,用户进程要占用低3GB
- 每一个进程都有自己的页表，当进程很多时，页表所占空间也多

总结：不把页表一次性建好，需要时动态创建页表项



具体实现：

​	所有页表都是标准页(即4KB大小)，所以4GB最多1M个标准页。

​	二级页表将`1M`个标准页平均放置在`1K`个页表中(如果采用一级页表，这1M页表项都会在同一页表中)

​	每一个页表包含`1k`个页表项，每个页表项`4KB`大小，刚好塞满一个标准页。

​	共`1K`个页表，最终大小也会`4MB`大小，但更灵活

![](https://i.imgur.com/wuBNv9y.png)

​	页目录一共`1024`个页表，每个页表`1024`个也目录项。内存在物理内存中离散分布，不分类型，毫无规律。



二级页表中定位物理页：

- 虚拟地址的高`10`位在页目录中定位==页表==(页目录项PDE)
- 虚拟地址的中`10`位在页表中定位具体的==物理页==(页表项PTE)
- 虚拟地址中余下`12`位定位具体的页内偏移

因为以上数据都是`4KB`大小，所以在给出索引后，具体寻址需要$\times 4$

这种自动化较强的工作可交由硬件(页部件)自动完成。

以`mov ax, [0x1234567]`举例：

![](https://i.imgur.com/zm0bHJU.png)



每一个任务都有自己的页表，每一个任务都以为自己独占内存空间。



前面说过，也目录项和页表项也都是`4BYTE大小`，但是我们在索引时(索引最大时，也只需要$2^{20}=1K$个，并不需要`32位`,多的`12`位可以储存其它信息。

![](https://i.imgur.com/jg4NUio.png)

P(Present)，存在位，若为1表示该页存在于物理页，若为0表示不再物理页，操作系统的页式虚拟内存管理便是通过P位和相应的pagefault异常实现

RW(Read/Write)，读写位，若为1表示可读可写，若为0表示可读不可写

US(User/Supervisor)，普通用户/超级用户位。若为1表示User级，任意级别可访问。若为0,表示Supervisor级，只允许0,1,2访问，特权级3不可访问。

PWT(Page-level Write-Through),页级通写位(页级写透位)，若为1表示采用通写方式，表示该位不仅仅是普通内存，还是高速缓存。此项和高速缓存有关，“通写”是高速缓存的一种工作方式，本位用来间接决定是否用此方式改善该页的访问效率。此处暂时为0.

PCD(Page-level Cache Disable)，页级高速缓存禁止位，若为1表示该页启用高速缓存，0表示禁止该页缓存。此处暂时置0

A(Accessed)，访问位。若为1表示该页已被CPU访问过，所以该位由CPU设置.内存置换算法可用。

D(Dirty)，意为脏页。当一个CPU对页进行写操作时，就会设置对应的D位为1。此项只针对==页表项==，不会修改页目录项中的D位。

PAT(Page Attribute Table)，意为页属性表位，能够在页一级的粒度上设置内存属性。较为复杂，此处暂时置0.

G(Global)，意为全局位。为了提高获取物理页的速度，将虚拟地址与物理页转换结果储存在TLB(Translation Lookaside Buffer)。该位用来指定该页是否为全局页。1表示全局页，0表示不是全局页。若是全局页，该位将在高速缓存TLB中一直保存，给出虚拟地址直接就出物理地址，无需转换。

顺便说，清空TLB有两种方式：

- 用invlpg指令单独对虚拟地址条目清理
- 重新加载`cr3`寄存器，直接清空TLB

AVL(Available)，表示可用。相对用户程序而言，操作系统可用该位，CPU不会理会。



启动分页机制，需做好三件事：

- 准备好==页目录表==和==页表==
- 将页表地址写入寄存器`cr3`
- 寄存器`cr0`的PG位置1



页表描述符也会时内存中的一个数据结构，处理器有专门的寄存器储存它，即`cr3`寄存器

因为页目录表所在的地址要求在一个自然页内，即页的起始地址是`4KB`的整数倍，低`12`位全是0。

所以`cr3`的第`31～12`(高20)位写入物理地址。相应的，低12位可以储存一些其他信息(事实上，除`PCD`和`PWT`其他位也没啥用)。

关于cr3(Page Directory Base Register,PDBR)寄存器



![](https://i.imgur.com/iqTNj6h.png)



打开分页机制需将`cr0`寄存器的PG位(第1位)置1。顺便说一下，第0位是PE位，保护模式开关。



在Linux中，用户进程`4GB`虚拟地址空间的高`3GB`以上的部分划给操作系统，`0～3GB`是用户进程自己的虚拟空间(但不一定都有映射)。为了实现共享操作系统，也就是让所有进程的虚拟地址`3GB～4GB`指向==同一片物理页地址==。



加入我们在内存中，让==所有页表==紧挨==页目录表==，且将页目录表存放在`0x100000`处，那么第一个页表位置是`0x101000`

![](https://i.imgur.com/KzryQtb.png)



为了实现真正的内核共享，页目录表中所有页目录项均初始化(第255个PDE指向页目录表自身，内核空间1GB)

后面，为了让每个用户进程共享内存空间，每个进程都有独立的虚拟4GB空间，每个用户进程的高1GB都必须指向内核。也就是说，对于每一个进程，==页目录表==(每个页目录表不同)中第`768～1022`个页目录项都与其他进程相同(第`1023`个页目录项指向页目录表自身)。

在进程创建页表时，都会把内核页第`768~1022`个页目录项复制到进程页目录表中相同的位置。这是最简单的共享内核方法(提前将内核页固定下来)。

否则，如果因为需求，进程陷入内核时，新申请了内存(新增了页表)，还需要将新内核页同步到其他的进程的页表中。结果是如果内核为某个进程提供了资源，其他进程也能访问(暂不评价)。





如何在页表中访问字节的物理地址呢？

结合前面的知识：

- 虚拟地址转化为物理地址的过程。32位地址的高，中，低三个部分各表不同
- 每一个页表的最后一项都是自己的物理地址。

我们用`0xfffffXXX`访问自己的物理地址。



关于TLB(Translation Lookaside Buffer)

- CPU会先访问它，且会实施刷新

- 其对开发人员不可见，但需要开发人员手动控制

  通过`invlpg`(invalidate page)指令，刷新特定的条目。

  如：若更新虚拟地址0x1234对应的条目`invlpg [0x1234]`

  注意，不是invlpg 0x1234



加载内核

关于gcc编译的一些基础知识，ld链接时，默认的入口地址是`_start`。可以使用`-e `（entry)手动指定。

一般情况先gcc会默认完成整个过程。`C/C++`中`main`作起始是标准(也可以是其它的)。



MBR加载到`0x7c00`，`loader`的地址是`0x900`，都是固定的

但为了灵活，可不可以不固定？

这就需要一种==标准==，或者说==文件格式==

将一些重要信息储存在文件可开始的位置，再以一种约定去解析。这些信息就包括程序的==入口地址==



关于ELF文件格式

![](https://i.imgur.com/Ut2sYh5.png)

![](https://i.imgur.com/7PTS8mc.png)

![](https://i.imgur.com/LyLR40k.png)

```c

typedef struct
{
  unsigned char	e_ident[EI_NIDENT];	/* Magic number and other info */
  Elf32_Half	e_type;			/* Object file type */
  Elf32_Half	e_machine;		/* Architecture */
  Elf32_Word	e_version;		/* Object file version */
  Elf32_Addr	e_entry;		/* Entry point virtual address */
  Elf32_Off	e_phoff;		/* Program header table file offset */
  Elf32_Off	e_shoff;		/* Section header table file offset */
  Elf32_Word	e_flags;		/* Processor-specific flags */
  Elf32_Half	e_ehsize;		/* ELF header size in bytes */
  Elf32_Half	e_phentsize;		/* Program header table entry size */
  Elf32_Half	e_phnum;		/* Program header table entry count */
  Elf32_Half	e_shentsize;		/* Section header table entry size */
  Elf32_Half	e_shnum;		/* Section header table entry count */
  Elf32_Half	e_shstrndx;		/* Section header string table index */
} Elf32_Ehdr;


```

![](https://i.imgur.com/zaRcTkb.png)

![](https://i.imgur.com/yb6ejif.png)

![](https://i.imgur.com/YklZh7M.png)

![](https://i.imgur.com/M6FQuTR.png)

elf实现了机器平台无关的良好移植性

`e_version`占4字节，表明版本信息

`e_entry`占四字节，程序如果，表明操作系统运行该程序时，将控制权转交到虚拟地址

`e_phoff`(program header table offset)，占4字节，程序头表的偏移，如果没有程序头表则为0.

`e_shoff`(section header table)，占4字节，程序内节头表偏移，若没有节头表则为0.

`e_flag`占4字节，与CPU相关的标志

`e_ehsize`占2字节，用于指明elf header的字节大小

`e_phentsize`占2字节，用于指明程序头(program header table)中每个条目(entry)的字节大小

`e_phnum`占两字节，指明节头表中条目的数量，实际上就是节的个数。

`e_shstrndx`占2字节，用于指明`string name table`在节头表中的索引index



关于程序头表

```c

typedef struct
{
  Elf32_Word	p_type;			/* Segment type */
  Elf32_Off	p_offset;		/* Segment file offset */
  Elf32_Addr	p_vaddr;		/* Segment virtual address */
  Elf32_Addr	p_paddr;		/* Segment physical address */
  Elf32_Word	p_filesz;		/* Segment size in file */
  Elf32_Word	p_memsz;		/* Segment size in memory */
  Elf32_Word	p_flags;		/* Segment flags */
  Elf32_Word	p_align;		/* Segment alignment */
} Elf32_Phdr;
```

`p_type`类型说明

![](https://i.imgur.com/N6p4G0v.png)

`p_offset`占4字节，用于指明本段在文件内的起始偏移字节

`p_vaddr`占用4字节，用于指明本段在内存中的起始虚拟地址(需要被加载到哪里)

`p_paddr`占4字节，仅用于与物理地址相关的系统中

`p_filesz`占4字节，指明本段在文件中的大小

`P_memsz`占4字节，用来指明本段在内存中的大小

`p_flags`占4字节，用来指明本段相关的标志

![](https://i.imgur.com/JzceM2f.png)

`p_align`占用4字节，用与表明本段在文件和内存中的对齐方式，0或1表示不对齐，否则应该是2的幂次数



汇编指令`cld`和`std`

控制flag寄存器，DF(（Direction Flag)位

`cld`(clear direction),将DF寄存器置0，内存地址向高处变化。

`std`(set direction)，将DF寄存器置1,内存地址向低处变化。



为了保险，多做点不过分



关于，ELF文件格式，建议还是熟悉一下。可以看看《程序员的自我与修养》



关于程序权限

程序特权级`0～3`

TSS(Task State Segment)，任务状态段

![](https://i.imgur.com/573UiI6.png)

因为每个特权级只能有一个栈段，所以TSS可以储存3个栈段。





关于特权级转移

- 由中断门，调用门实现低特权级向高特权级
- 由调用返回指令从高特权级返回到低特权级(这是唯一一种让处理器降低特权级的情况)



因为从低到高是门调用，所以TSS储存的栈地址是0,1,2特权级的地址。而从高特权级到低特权级是调用返回，所以不用储存特权级3的栈地址，因为在低特权级转到高特权级之前，其相关寄存器肯定备份了。

TSS需要将地址加载到TR(Task Register)寄存器。



门结构

![](https://i.imgur.com/bm6vZ3K.png)



关于DPL,CPL和RPL

CPL(`Current Privilege Level`)，当前正在执行的代码等级(处理器当前CPL储存在CS.RPL中)，处理器当前所处的特权级

RPL(`Requester Privilege Level`)，请求者需要的特权级别，在选择子中

DPL(`Descriptor Privilege Level`)，段描述符对应的特权级



对于任务门

当要向高特权级跃迁时，需满足最低特权级的限制



![](https://i.imgur.com/fKFF4mp.png)



一致性代码和非一致性代码(对于代码而言)

==一致性代码就是操作系统拿出来被共享的代码段，可以被代码段直接访问的代码==

一致性代码的限制作用：

- 特权级高的代码段不允许访问特权级低的代码段：即内核态不允许 调用用户态的代码
- 特权级低的代码可以访问特权级高的代码段，但是当前特权级不发生变化，即：用户太可以访问内核态的代码，但是用户依然是用户态



==非一致性代码段是为了避免低特权级访问而被操作系统保护起来的系统代码，也就是非共享代码==

非一致性代码的限制作用：

- 只允许同特权间访问
- 绝对禁止不同级间访问，即：用户态和内核态间相互不能访问



对于数据段的访问：

- 数据段中`DPL`规定了可以访问此段的最低特权级
- 要求：`RPL`和`CPL`都同时大于`DPL`



关于特权级DPL CPL 和RPL有机会再看吧，写得太。。。。***诶***



关于IO特权级

一共2`bit`，反映4个特权级

不仅是除限制当前任务进行IO敏感指令最低特权级，还用来决定是否允许操作所有的IO端口(全部，每个任务都有储存自己的`eflags`,每个任务都有自己的`IOPL`)

其设置通过`pushf`和`popf`

![](https://i.imgur.com/9XHteVZ.png)



此外，`IO`端口的开关可以通过像防火墙一样(先整体关闭，再局部打开)，控制端口的同时减少时间成本。



IO位图

- 只有在特权级(数值上)`CPL > IOPL`时才有意义，即上文说“防火墙控制法”
- 当特权级(数值上)`CPL < IOPL`时，任何端口都可以不受限制地访问。



IO位图位于TSS中(在TSS==内==偏移102字节的位置)，在不光包括IO位图时，TSS有104字节大小

Inter最多支持`65536`个端口，通过65536个`bit`,每一个bit代表一个端口，也就是`65536/8=8192`字节，即`8KB`大小

![](https://i.imgur.com/FLrA7js.png)

在包含IO位图时，TSS大小为==“IO位图偏移地址” + 8192 + 1字节==(1字节是IO位图的结束边界符)



在计算机硬件中，IO端口按字节编址，也就是说==一个端口只能写一个字节==，如果对一个端口连续写入多个字节数据，实际上是对该端口为起始的多个端口进行连续写入

举个例子

```sh
in ax, 0x234
#相当于

in al, 0x234
in al. 0x235
```

在处理IO位图时，处理器会检查相应的bit是否为0。

- 若要读取多个字节，势必要检查连续多个端口所对应的多个`bit`，这些bit必须都为0时才能访问。
- 当`bit`跨字节时，处理器需将涉及到的字节全部读入进行处理(异或)



大多数新情况下没事

​	但是，当第一个`bit`就是位图的最后一个`bit`时，此时再顺延读取后面的`bit`就有可能访问到IO位图之外的数据(造成错误).

​	所以，处理器要求位图最后一字节是`0xFF`作为边界，也照应了IO位图的检测方法(`1`为关，`0`为开)



