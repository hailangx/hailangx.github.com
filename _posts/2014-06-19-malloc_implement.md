---
layout: post
title: " malloc的实现原理"
description: ""
categories: ["操作系统","基础知识"]
tags: ["malloc","动态内存分配","堆"]
published: true
---

CS:APP 《深入理解操作系统》提供了一个实现malloc的小project. 为了弄清楚malloc的实现原理，这两天调研了一下，记录如下。

##1.进程空间

Linux的虚拟内存空间使得每个进程都有一个独立的进程空间，使用地址转换机制把虚存地址转换为物理地址.在进程看来它拥有全部的4G寻址空间(32位系统),然而实际上进程是受操作系统管理的，它只是在理论上拥有全部的寻址空间，实际运行中操作系统只分配了部分物理空间给特定的进程，因为“局部性”原理，虚拟内存空间得以高效的实现。

Linux中进程的控制块(PCB)用一个`task_struct` 数据结构表示，这个数据结构记录了所有进程信息，包括进程状态、进程调度信息、标示符、进程通信相关信息、进程连接信息、时间和定时器、文件系统信息、虚拟内存信息等，具体参见[`task_struct`结构描述][1]. 这里和`malloc`密切相关的就是虚拟内存信息，定义`为Struct mm_struct *mm`
具体描述进程的地址空间.`mm_struct`结构是对整个用户空间（进程空间）的描述。

mm_strcut 用来描述一个进程的虚拟地址空间，在/include/linux/sched.h 中描述如下：

    struct mm_struct {
             struct vm_area_struct * mmap;  /* 指向虚拟区间（VMA）链表 */
             rb_root_t mm_rb;         ／*指向red_black树*/
             struct vm_area_struct * mmap_cache;     /* 指向最近找到的虚拟区间*/
             pgd_t * pgd;             ／*指向进程的页目录*/
             atomic_t mm_users;                   /* 用户空间中的有多少用户*/                                     
             atomic_t mm_count;               /* 对"struct mm_struct"有多少引用*/                                     
             int map_count;                        /* 虚拟区间的个数*/
             struct rw_semaphore mmap_sem;
             spinlock_t page_table_lock;        /* 保护任务页表和 mm->rss */       
             struct list_head mmlist;            /*所有活动（active）mm的链表 */
             unsigned long start_code, end_code, start_data, end_data;
             unsigned long start_brk, brk, start_stack; /*堆栈相关*/
             unsigned long arg_start, arg_end, env_start, env_end;
             unsigned long rss, total_vm, locked_vm;
             unsigned long def_flags;
             unsigned long cpu_vm_mask;
             unsigned long swap_address;
     
             unsigned dumpable:1;
             /* Architecture-specific MM context */
             mm_context_t context;
    };

其中`start_brk` 和`brk`分别是堆的起始和终止地址，我们使用`malloc`动态分配的内存就在这之间。`start_stack`是进程栈的起始地址，栈的大小是在编译时期确定的，在运行时不能改变。而堆的大小由`start_brk` 和`brk`决定，但是可以使用系统调用`sbrk()` 或`brk()`增加`brk`的值，达到增大堆空间的效果，但是系统调用代价太大，涉及到用户态和核心态的相互转换。所以，实际中系统分配较大的堆空间，进程通过`malloc()`库函数在堆上进行空间动态分配，堆如果不够用`malloc`可以进行系统调用，增大`brk`的值。

Linux中对虚拟内存空间采用分区域进行管理，`struct vm_area_struct `数据结构描述了一个虚拟区域，对这个虚拟区域使用双链表或者红黑树进行管理，这样在进行寻址的时候先找虚拟区域。详见[虚拟空间的数据结构][2]

![enter image description here][3]

这一部分就是`malloc`底层依赖的相关信息了，但是这对用户进程来说是透明的，总结一下：`malloc`只知道`start_brk` 和`brk`之间连续可用的内存空间它可用任意分配，如果不够用了就向系统申请增大`brk`。后面一部分主要就malloc如何分配内存进行说明。

##2.内存分配

malloc进行内存分配的时候有很多种策略可以使用，不同的策略运用了不同的数据表示方式，也有不同的性能。这里可以发现数据结构和算法在计算机世界中真的是无处不在，上面对虚拟区间进行管理的时候也说了可用使用双链表或者AVL树、红黑树，在不同情形下有不同的效率。

通过上面的储备，可以知道malloc进行内存分配的时候，可以认为它面对的是一个连续的大数组，要把这个大数组的空间分配给动态内存请求，同时还要处理内存释放。这就需要用一个有效的策略处理内存分配和释放任务，下面涉及到的方法来自《深入理解操作系统》，这里仅简要介绍作为记录，需要详细了解请参考该书动态内存分配部分章节。

动态内存分配不仅要高效的响应动态内存请求，而且也要堆内存释放做出合理的操作，既要保证高效也要保证不浪费空间。处理内存分配碎片，空闲块合并等等。在《深入理解操作系统》中有详细的介绍，这里就不累述。

###A.隐含链表方式

隐含链表方式即在每一块空闲或被分配的内存块中使用一个字的空间来保存此块大小信息和标记是否被占用。根据内存块大小信息可以索引到下一个内存块，这样就形成了一个隐含链表，通过查表进行内存分配。

###B.显示空闲链表

显示空闲链表的方法，和隐含链表方式相似，唯一不同就是在空闲内存块中增加两个指针，指向前后的空闲内存块。

###C.多链表

根据空闲的内存块的不同大小建立多个链表，在分配内存时根据请求大小之间到接近链表中去查找空闲块。

###D.高级方式

前面的几种方法非常简单，但是效率也不高，实际中只在特定情况会使用，通常情况下并不使用这些策略。实际中通常使用红黑树、Splay树等平衡二叉查找树管理空闲块，块大小作为关键字这样可用快速找到合适的内存进行分配。更多可用参考[wiki][4]。

##3.总结

本文主要对malloc背后的原理进行了探究，简要了解了Linux操作系统中实现进程控制的数据结构`task_struct`，重点介绍了其中关于虚拟空间管理的`mm_struct`，进程中堆空间通过`start_brk` 和`brk`进行控制，而malloc的功能就是对`start_brk` 和`brk`之间的连续空间进行动态的分配和释放，这里可以使用不同的策略得到不同的效率是空间利用，全文对malloc的功能从原理上进行了总体探究。


  [1]: http://oss.org.cn/kernel-book/ch04/4.3.htm
  [2]: http://oss.org.cn/kernel-book/ch06/6.4.1.htm
  [3]: http://oss.org.cn/kernel-book/ch06/6.4.2.files/image005.gif
  [4]: http://en.wikipedia.org/wiki/C_dynamic_memory_allocation