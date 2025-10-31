---
layout: post
title: "编译器、汇编器、连接器和加载器: 一个简要的介绍"
description: "description"
categories: ["基础知识"]
tags: ["编译器","汇编器","连接器","加载器","进程空间"]
published: true
---

本来想自己写一篇关于可执行程序的连接及程序执行时进程空间等问题的博客，结果被我发现了一篇好文章，遂翻译出来顺便学习。原文[COMPILER, ASSEMBLER, LINKER AND LOADER:A BRIEF STORY][1]，翻译主要还是更具自己的理解来，如有疑问请参考原文。

注意：
本文提供了一个进程（运行程序）相当多的细节故事。它试图探讨C/C++源代码如何预处理，编译，链接和加载为一个正在运行的程序。它是基于GCC（GNU编译器集合）来说明的。当你使用IDE（集成开发环境）编译器，如微软的Visual C + +，Borland的C++ Builder等，这里讨论过程对IDE用户来说是透明的。关于Linux的GNU GCC，G++，GDB等工具的命令和示例请参考这里[待添加]。

C编译器的能力：
能理解和预处理过程，编译，连接，加载和运行的C / C + +程序。

##1. 编译器，汇编器和连接器 COMPILERS, ASSEMBLERS and LINKERS

通常情况下，C程序的构建过程包括四个阶段，分别采用不同的“工具”，如预处理器，编译器，汇编器和链接器。在最后应该有一个单一的可执行文件。下面就是这几个阶段（忽略了操作系统/编译器差异）发生的顺序。表1和图1展示了这几个阶段。

 - **预处理**是任何C编译的第一遍。它处理头文件，条件编译指令和宏。
 - **编译**是第二遍。它需要预处理器的输出、源代码，并生成汇编源代码。
 - **汇编**它采用汇编源代码，并生成带偏移地址的汇编清单。汇编器的输出存储在目标文件。
 - **链接**是编译的最后阶段。这需要一个或多个目标文件或库作为输入，并结合他们产生一种单一的（通常是可执行文件）文件。在这样做时，它解析引用外部符号，分配给最后地址的程序/函数和变量，并修改代码和数据，以反映新的地址（一个称为重定位的处理）。

如果你使用IDE进行开发，这些过程对你来说就是透明的。现在，我们将研究发生在链接阶段之前和之后过程中的更多细节。对于任何给定的输入文件，文件名后缀（文件扩展名）确定由什么样的编译工具来完成，下表给出了GCC的例子,关于这方面可以参考[GCC的文档][2]。在UNIX / Linux上，该可执行文件或二进制文件没有扩展名，而在Windows中的可执行文件，可能有.exe，.com和.dll的后缀。


![文件后缀和对应的处理方式][3]

下面的一张图给出了参与构建C程序，从编译开始，直到加载可执行文件成为内存中运行的程序（一个进程）的步骤，关于这些步骤的具体情况会在下面进行说明。


![从源代码到进程][4]

##2.目标文件和可执行  OBJECT FILES and EXECUTABLE

 - 在源代码被汇编后，会得到很多目标文件(Object File ,如 .o .obj ) ，然后通过连接得到一个可执行的文件。
 - 可目标文件和可执行文件的格式有好多种，例如像ELF(Executable and Linking Forma)和COFF(Common Object-File Format). ELF是Linux系统中使用的，而windows使用的是COFF ，下表给出了一些可执行文件格式的描述：
 

![enter image description here][5]
 

 - 目标文件的里的内容有段区域。这些段区域可容纳可执行代码，数据，动态链接信息，调试数据，符号表，重定位信息，注释，字符串表，以及附注。
 - 部分段会被加载到进程映像，另外一些段会提供一些必要的信息来帮助构建进程，同时还有一些仅用于连接目标文件。
 - 有几个部分是所有可执行文件格式共同的（可能有不同的名称，这取决于编译器/链接）如下表所示：


![enter image description here][6]


下面是一个用` readelf` 工具读取目标对象内容的例子.  另外还可以使用的工具有` objdump`.  对windows来说可以使用`dumpbin`工具，或者更强大的`PEBrowseFor`.下面是代码：

    /* testprog1.c */
    #include <stdio.h>
    static void display(int i, int *ptr);
     
    int main(void)
    {
          int x = 5;
          int *xptr = &x;
          printf("In main() program:\n");
          printf("x value is %d and is stored at address %p.\n", x, &x);
          printf("xptr pointer points to address %p which holds a value of %d.\n", xptr, *xptr);
          display(x, xptr);
          return 0;
    }
     
    void display(int y, int *yptr)
    {
          char var[7] = "ABCDEF"; 
          printf("In display() function:\n");
          printf("y value is %d and is stored at address %p.\n", y, &y);
          printf("yptr pointer points to address %p which holds a value of %d.\n", yptr, *yptr);
    }
 
 编译并查看目标文件：
 
     $ gcc -c testprog1.c
     $ readelf -a testprog1.o

输出：

    ELF Header:
      Magic:   7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00
      Class:                                  ELF32
      Data:                                   2's complement, little endian
      Version:                                1 (current)
      OS/ABI:            UNIX - System V
      ABI Version:              0
      Type:              REL (Relocatable file)
      Machine:           Intel 80386
      Version:           0x1
      Entry point address:      0x0
      Start of program headers: 0 (bytes into file)
      Start of section headers: 672 (bytes into file)
      Flags:                    0x0
      Size of this header:      52 (bytes)
      Size of program headers:  0 (bytes)
      Number of program headers:       0
      Size of section headers:         40 (bytes)
      Number of section headers:       11
      Section header string table index:      8
     
    Section Headers:
      [Nr] Name          Type          Addr     Off        Size     ES Flg Lk Inf Al
      [ 0]               NULL          00000000 000000 000000 00      0   0  0
      [ 1] .text         PROGBITS      00000000 000034 0000de 00  AX   0   0  4
      [ 2] .rel.text     REL           00000000 00052c 000068 08      9   1  4
      [ 3] .data         PROGBIT       00000000 000114 000000 00         WA  0   0  4
      [ 4] .bss          NOBIT         00000000 000114 000000 00  WA  0   0  4
      [ 5] .rodata              PROGBITS      00000000 000114 00010a 00      A  0   0  4
      [ 6] .note.GNU-stack      PROGBITS      00000000 00021e 000000 00      0   0  1
      [ 7] .comment      PROGBITS      00000000 00021e 000031 00      0   0  1
      [ 8] .shstrtab     STRTAB 00000000 00024f 000051 00       0   0  1
      [ 9] .symtab              SYMTAB 00000000 000458 0000b0 10     10  9  4
      [10] .strtab              STRTAB 00000000 000508 000021 00      0   0  1
    Key to Flags:
      W (write), A (alloc), X (execute), M (merge), S (strings)
      I (info), L (link order), G (group), x (unknown)
      O (extra OS processing required) o (OS specific), p (processor specific)
     
    There are no program headers in this file.
     
    Relocation section '.rel.text' at offset 0x52c contains 13 entries:
     Offset       Info                 Type   Sym.Value  Sym. Name
    0000002d  00000501 R_386_32 00000000   .rodata
    00000032  00000a02 R_386_PC32      00000000   printf
    00000044  00000501 R_386_32 00000000   .rodata
    00000049  00000a02 R_386_PC32      00000000   printf
    0000005c  00000501 R_386_32 00000000   .rodata
    00000061  00000a02 R_386_PC32      00000000   printf
    0000008c  00000501 R_386_32 00000000   .rodata
    0000009c  00000501 R_386_32 00000000   .rodata
    000000a1  00000a02 R_386_PC32      00000000   printf
    000000b3  00000501 R_386_32 00000000   .rodata
    000000b8  00000a02 R_386_PC32      00000000   printf
    000000cb  00000501 R_386_32 00000000   .rodata
    000000d0  00000a02 R_386_PC32      00000000   printf
     
    There are no unwind sections in this file.
     
    Symbol table '.symtab' contains 11 entries:
       Num:    Value     Size Type    Bind        Vis             Ndx Name
         0: 00000000     0 NOTYPE  LOCAL  DEFAULT  UND
         1: 00000000     0 FILE    LOCAL  DEFAULT  ABS testprog1.c
         2: 00000000     0 SECTION LOCAL  DEFAULT    1
         3: 00000000     0 SECTION LOCAL  DEFAULT    3
         4: 00000000     0 SECTION LOCAL  DEFAULT    4
         5: 00000000     0 SECTION LOCAL  DEFAULT    5
         6: 00000080     94 FUNC   LOCAL  DEFAULT    1 display
         7: 00000000     0 SECTION LOCAL  DEFAULT    6
         8: 00000000     0 SECTION LOCAL  DEFAULT    7
         9: 00000000     128 FUNC  GLOBAL DEFAULT    1 main
        10: 00000000     0 NOTYPE  GLOBAL DEFAULT  UND printf
     
    No version information found in this file.

当使用汇编语言编写程序时，要和assembler directives的段选项相对应，下面是我们感兴趣的部分选项列表：

 
Assembler directives在用汇编语言编写程序时可以用来识别code, data段 ; allocate/initialize memory,让符号外部可见或者不可见。


##3.重定位记录RELOCATION RECORDS

因为目标文件可能包涵很多对其他目标文件代码或者（和）数据的引用，所以在链接的时候有相当多的地址需要被组合起来。
例如上面的代码，在main()中就包含了对printf()和display()的引用。
当把所有的目标文件连接在一起的时候，链接器使用重定位记录来确定那些地址。

###4.符号表 SYMBOL TABLE


  [1]: http://www.tenouk.com/ModuleW.html
  [2]: https://gcc.gnu.org/onlinedocs/gcc/Overall-Options.html
  [3]: https://docs.google.com/drawings/d/1X6_Udtq8LfMkEGCl25e-lVqYJxF16FlkXNIUrz97rS0/pub?w=626&h=415
  [4]: https://docs.google.com/drawings/d/1jB91FZlTdaDIx53eaKQdtr51jqJVoqZ69yDaujrXZis/pub?w=405
  [5]: https://docs.google.com/drawings/d/12g71dluRSnqBovG-PdLDZZ0F3psmLl3_Q8xvcS1gUDg/pub?w=625
  [6]: https://docs.google.com/drawings/d/1VuKxrQA2DrD2NUDOQ4V4aPzjqVI-PtO3gRdeNvqTPBk/pub?w=625