第1章 部署环境

要求：

- nasm
- gcc
- 虚拟机(qemu或boch)



### bochs虚拟机

下载，解压

configure,make,make install三步曲

```shell

./configure \
--prefix=/home/blact/codes/myOs/bochs \
--enable-disasm \
--enable-iodebug \
--enable-x86-debugger \
--with-x \
--with-x11 \
--enable-debugger 
#--enable-gdb-stub ;gdb调试和boch自带的debugger二选一
```

