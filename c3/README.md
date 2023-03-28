这一章主要粗略学习

硬盘原理，端口写入读出，简单列出mbr与loader的关系

### 硬盘简史

....



### 硬盘工作原理

....



### 硬盘端口控制器

硬盘用端口控制

![](https://i.imgur.com/lJ3G52Q.png)

端口分为两组，`Command Block Registers`和`Control Block registers` 

`Command Block Registers`用于向硬盘驱动器写如命令字或者从硬盘控制器获得硬盘状态

`Control Block registers` 用于控制硬盘工作状态

主要使用三个命令：

- identify:	0xEC 	，即硬盘识别

- read sector： 0x20 ，即读硬盘
- write sector： 0x30 ，即写扇区



关于error,feature和status,command两组寄存器：

​	这两组是同一寄存器（也就是同一端口）多个用途。写入时是命令。读取时是状态



![](https://i.imgur.com/BoZCYht.png)













































```shell
#带文件包含的汇编编译
nasm -I include/ -o loader.bin loader.s

```





```shell
#将mbr写入硬盘的第0扇区
dd if=/home/blact/codes/myOs/os_src/c3/boot/mbr.bin of=/home/blact/codes/myOs/bochs/hd60M.img bs=512 count=1 conv=notrunc 
```





```shell
#将loader写入硬盘的第2扇区，中间间隔了一个，按原作者的还说--“就是玩儿”
dd if=/home/blact/codes/myOs/os_src/c3/boot/loader.bin of=/home/blact/codes/myOs/bochs/hd60M.img bs=512 count=1 seek=2 conv=notrunc

```

