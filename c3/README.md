这一章主要粗略学习

硬盘原理，端口写入读出，简单列出mbr与loader的关系

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

