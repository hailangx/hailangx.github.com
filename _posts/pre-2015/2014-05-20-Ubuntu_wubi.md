---
layout: post
title: "Ubuntu Wubi背后的原理"
description: ""
categories: ["Linux","基础知识"]
tags: ["Ubuntu Wubi","Boot loader","GRUB 2"]
published: true
---


自从周末让Ubuntu自己更新了一下推荐更新就出现了一些毛病：wifi图标不见了，Goagent的图标也不能显示了，wifi的设置页面打不开。真是要吐个槽了，你升级你的干嘛把我用的好好的东西给搞坏了呢 ？软件开发者自以为是的毛病。因为实验室的网真是个龟速，而且Ubuntu默认更新完全单线程，慢死。重新编译一下NetworkManager结果依赖库下载不了，而且还有其他一些莫名奇妙的问题，就想直接重新装个ubutnu算了，但是又不想把这个删掉，毕竟前面我还搭了环境，用实验算的破网下了几个库。开始的时候用wubi装得ubuntu放在windows下面最后一个单独分区里面了，现在想把原来这个ubuntu移到其他盘，把这最后一个盘直接用ubuntu原生安装，可是移动原来的ubuntu让我碰到了一些问题，为了解决这个麻烦瞎折腾了半天终于把整个过程基本弄清楚了。不得不说我真是太能折腾了，这绝对是病！不折腾清楚心里硬是不爽。为了搞清楚整个流程，查了不少资料，下面是把我认为让需要的基本知识记录下来。

##1. 操作系统的启动流程

以下是PC启动过程的简要描述 [^1] ：

 1. 电源按钮激活电源在PC，送电源到主板和其他部件。
 2. PC将执行开机自我测试（POST）。POST是在BIOS中一个小的计算机程序用来检查硬件故障。在POST后哔一声预示着一切都还好。其他蜂鸣序列标志着发生硬件故障。
 3. PC在连接的显示器上显示有关引导过程的详细信息。这些包括BIOS的制造商和版本，处理器规格，安装的RAM量，和检测出的驱动器。很多电脑已经默认替换了这些文字显示，代之为显示制造商的标志。
 4. BIOS尝试访问指定为引导磁盘驱动器的第一个扇区(称为boot sector)。第一个扇区是磁盘的序列的第一个千字节(根据扇区的大小)，从第一个扇区中加载Bootloaer.
 5. BIOS确认有一个引导加载器，或引导装载程序(Bootloader)，在启动盘的第一个扇区，它会加载Bootloader到内存（RAM）。引导加载程序(Bootloader)的目的是找到并启动PC的操作系统的一个小程序。
 6. 一旦引导加载程序(Bootloader)被加载到内存，BIOS移交控制权给Bootloader，从而开始加载操作系统到内存中。
 7. 当引导加载程序(Bootloader)完成它的任务，即把系统内核加载到了内存中，就把控制权交给操作系统。然后，操作系统就可以与用户交互。


###BIOS
有一些计算机基础的应该都知道电脑有个叫[BIOS][1]的东西，这是一个存储在主板ROM芯片上的一个固件， 根据wiki上说的：当计算机的电源打开，BIOS就会由主板上的闪存（flash memory）运行，并将芯片组和存储器子系统初始化。BIOS会把自己从闪存中，解压缩到系统的主存；并且从那边开始运行。PC的BIOS代码也包含诊断功能，以保证某些重要硬件组件，像是键盘、磁盘设备、输出输入端口等等，可以正常运作且正确地初始化。几乎所有的BIOS都可以选择性地运行CMOS存储器的设置程序；也就是保存BIOS会访问的用户自定义设置数据（时间、日期、硬盘细节，等等）。

现代的BIOS可以让用户选择由哪个设备启动计算机，如光盘驱动器、硬盘、软盘、USB 闪存盘等等。这项功能对于安装操作系统、以LiveCD启动计算机、以及改变计算机找寻开机媒体的顺序特别有用。

### Bootloader

Bootloader是被BIOS从磁盘的第一个扇区([boot sector][2])加载到内存执行的，Bootloader的工作就是把操作系统加载到RAM [参考][3]。但是现在操作系统一般都使用了Second-stage boot loader，以提供更复杂的控制，比如多启动项等等。Second-stage boot loader有例如GNU GRUB, BOOTMGR, Syslinux,  NTLDR 参见[wiki][4]，这个时候BIOS从磁盘第一个扇区加载的bootloader 的全部任务就只是为了把Second-stage boot loader加载到RAM并转移控制权。 然后由Second-stage bootloader完成加载操作系统的任务。这里又见到了**分层**的思想，发现计算机的世界好多都是一些分层接力的设计，例如网络协议的分层，计算机存储体系的分层，web中代理缓存的分层等等，要不是为了分离任务便于实现，要不就是为了减轻负担加快速度。


后面的内容就全部是基于Second-stage boot loader.

 - GRUB是Linux中使用的非常广泛的bootloader .
 - BOOTMGR是win7之后采用的bootloader
 - NTLDR 是Windows NT/2000/XP's 采用的bootloader 

##2.Wubi的原理

###Wubi干了啥？

下面是使用Ubuntu13.10 用wubi在windows 7下面进行安装的。

 1. wubi安装的时候在宿主系统windows7中建立了一个虚拟磁盘文件root.disk，ubuntu系统全部在这个虚拟的磁盘文件中。

 2. wubi同时也给win7添加了一个启动项，即在BOOTMGR中添加了一个类型为BOOTSECTOR类型的启动项。

        ———————
        标识符                  {39bed8be-0619-11df-a4ea-f49453e653f3}
        device                  partition=D:
        path                    \ubuntu\winboot\wubildr.mbr
        description             Ubuntu

 3. 在C盘会增加**wubildr** 和**wubildr.mbr**两个文件


###启动过程

通过我昨天和今天的折腾，和查资料基本验证了如下过程：

 1. windows的BOOTMGR启动后，选择从上面的Ubuntu启动项启动
 2. 会把wubildr.mbr(这个文件很小)加载到RAM，他的主要任务和目的是在**磁盘根目录找到第一个wubildr文件**，并加载
 3. wubildr这个文件里的代码包含了grub ，相当于现在已经把控制权转移给了GRUB
 4. wubildr里面的GRUB程序要找到root.disk 作为loop挂载，作为系统盘使用
 5. wubildr从loop里面读取配置文件grub.cfg，加载ubuntu内核 


正如下面参考的一篇博文说的：系统中除了正常的Win启动项外，还会有一个启动项指向wubildr.mbr文件，这就是一个chainloader机制，因为windows的bootloader不能直接启动Linux系统，但可以把bootloader“链”到另一个bootloader，这个bootloader可能是其他分区的boot sector，也可能是一个镜像文件，然后wubildr再去扮演grub的角色，来启动Linux。

在查资料的过过程中，发现wubi在windows下面使用chainloader 到grub是基于一个些中国人开发的一个GRUB变种GRUB4DOS，但是在网上却找不到GRUB4DOS的官方文档。

就我的理解，GRUB4DOS在wubi这里的应用，相当于就是把GRUB 的state 1用一个文件wubildr.mbr替代而不用把它写在硬盘的MBR上， 然后后面也对windows的文件系统进行了支持. 关于GRUB的一个Stage参看[wiki][5]。




给windows增加到wubi的安装的linux的启动项，只需要以管理员身份运行windows7命令提示符，执行：

    bcdedit /create /d "Ubuntu" /application bootsector 
    #此时系统会自动生成一个{id} 下面在使用的时候要用这个值
    
    bcdedit /set {id} device partition=D:  # D:为wubi安装的ubuntu所在的盘符
    bcdedit /set {id} path \ubuntu\winboot\wubildr.mbr #这个是boot sector文件的路径）
    bcdedit /displayorder {id} /addlast


这部分还参考了[从一个bug看Linux启动原理][6] 还有[Ubuntu with Wubi: WUBILDR, WUBILDR.MBR and GRLDR][7]

###迷惑的地方

wubildr.mbr中的程序是从磁盘第一块分区开始以此往后在磁盘根目录查找wubildr的，
我只要保证在磁盘根目录有一个wubildr就可以成功进入GRUB了。
问题是：
我的磁盘有 C D E F四个分区，开始的时候我把ubuntu安装在F:/ubnutu/ ,启动进入ubuntu后 我把把F盘的/ubuntu/复制到E盘了，在现在运行中的ubuntu桌面添加了一个文件"This is origin"作为区分标志，然后把wubildr从C盘移到E盘。系统中的结构如下：

    D:  wubildr
    E: /ubuntu/... (This is the copy)
    F: /ubuntu/... (This is the origin)
    
重启之后我还是进入了This is the origin. 进入E盘Ubuntu的办法只有一个：进入GRUB后编辑启动目录，指定E盘的root.disk
下面是在GRUB中启动条目的代码：

    gfxmode $linux_gfx_mode
	insmod gzio
	insmod ntfs
	set root='hd0,msdos5' #设定给GRUB用的，找/ubuntu/disks/root.disk
	if [ x$feature_platform_search_hint = xy ]; then
	  search --no-floppy --fs-uuid --set=root --hint-bios=hd0,msdos5 --hint-efi=hd0,msdos5 --hint-baremetal=ahci0,msdos5  0E24BF3A24BF241D
	else
	  search --no-floppy --fs-uuid --set=root 0E24BF3A24BF241D
	fi
	loopback loop0 /ubuntu/disks/root.disk #根据上面找到的磁盘挂载/ubuntu/disks/root.disk 
	set root=(loop0) #设定给linux用的，从root.disk中找内核
	linux	/boot/vmlinuz-3.11.0-20-generic root=UUID=0E24BF3A24BF241D loop=/ubuntu/disks/root.disk ro rootflags=sync  quiet splash $vt_handoff
	initrd	/boot/initrd.img-3.11.0-20-generic

注意上面我给的注释，**第一个设定root是给GRUB用来找/ubuntu/disks/root.disk，用loopback挂载用的；第二个设定root=(loop0)是给linux启动用的，在挂载的loop0中找内核。**

要把其中**对应的磁盘(hd0,msdos5)和磁盘UUID(0E24BF3A24BF241D)改为和E盘对应**，GRUB才能正确找到E盘的Ubuntu，并启动Ubuntu. 具体命令参考[GNU GRUB Manual 2.00][8]

进入E盘的ubuntu之后使用update-grub可以更新本系统的/boot/grub/grub.cfg。但是问题是重启之后GRUB还是默认就从F盘的Ubuntu启动了。wubildr是按什么顺序搜寻/ubuntu/disks/root.disk的呢 ？难道在安装的时候硬编码了吗？可是如果我把F盘的/ubuntu/文件夹改名或者删除后，就有自动的找到E盘的/ubuntu了。这个地方有点迷惑。

又找到了一个关于GRUB4DOS的配置文档，通过grubinst可以[更改相关的参数][9]，这里可能是wubi在安装时设定了默认查找盘。
参考[Grub4dos Guide][10]

  [^1]: 大概流程，这个网址也有描述 http://computer.howstuffworks.com/pc3.htm


  [1]: http://zh.wikipedia.org/wiki/BIOS
  [2]: http://en.wikipedia.org/wiki/Boot_sector
  [3]: http://yunli.blog.51cto.com/831344/181630
  [4]: http://en.wikipedia.org/wiki/Booting#Second-stage_boot_loader
  [5]: http://en.wikipedia.org/wiki/GNU_GRUB
  [6]: http://blog.tomsheep.net/2011/07/08/linux-boot/
  [7]: http://ubuntu-with-wubi.blogspot.com/2011/01/wubildr-wubildrmbr-and-grldr.html
  [8]: http://www.gnu.org/software/grub/manual/grub.html
  [9]: http://diddy.boot-land.net/grub4dos/files/grldrmbr.htm
  [10]: http://diddy.boot-land.net/grub4dos/Grub4dos.htm