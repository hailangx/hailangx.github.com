---
layout: post
title: "B-Link Ubuntu 14.04下装驱动  "
description: ""
categories: ["Linux","笔记"]
tags: ["Linux","B-Link","Ubuntu 14.04","Ralink 7601"]
published: true
---


先用:

    lsusb 

查看usb设备型号:
    
    Bus 002 Device 003: ID 148f:2070 Ralink Technology, Corp. RT2070 Wireless Adapter
    Bus 002 Device 004: ID 148f:7601 Ralink Technology, Corp. 
    Bus 002 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
    Bus 004 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
    Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
    
第二行ID 148f:7601 Ralink Technology, Corp. 就是我的网卡，从网上下载驱动源文件DPO_MT7601U_LinuxSTA_3.0.0.4_20130913.tar.bz2 
直接make，会报错，要把os/linux/rt_linux.c中的1222行左右的代码改动一下：

    pOSFSInfo->fsuid = current_fsuid();
    pOSFSInfo->fsuid = current_fsuid();

把他们两个改为：

    pOSFSInfo->fsuid = *(int *)&current_fsuid();
    pOSFSInfo->fsuid = *(int *)&current_fsuid(); 

然后，可以顺利的make，和后面把148F 7601 添加到new_id里面

    make
    make install

    echo 148F 7601 > /sys/bus/usb/drivers/rt2870/new_id
    
最后，加载模块：

    sudo modprobe mt7601Usta

报错：

    could not insert 'mt7601Usta': Device or resource busy
    
解决办法，在终端输入dmesg，
发现有这么一句： Error: Driver 'rt2870' is already registered, aborting...
根据网上查询驱动有冲突，先用modprobe -r命令将已经安装的驱动移除，然后再将另一个驱动modprobe进去，即：

    sudo modprobe -r rt5370sta
    sudo modprobe mt7601Usta

然后就好了。。。

后面一重启发现网卡又不能用了，原来是驱动开机没加载，可我在加载的时候又是could not insert 'mt7601Usta': Device or resource busy，因为rt5370sta开机被加载了，所以把mt7601Usta加入到开机加载，把rt5370sta从卡机加载移除：

 /lib/modules/3.13.0-24-generic/kernel/drivers/net/wireless/rt5370sta.ko


最后发现，用这个驱动连上网系统**直接挂掉**！ 

最后进TTY，把这个驱动make uninstall才好 悲催。。。 还是用老网卡吧。

参考：

http://blog.lytsing.org/archives/954.html       
http://blog.csdn.net/michaelbaker/article/details/23597741          
http://blog.163.com/thinki_cao/blog/static/83944875201310154248858/         
http://blog.163.com/thinki_cao/blog/static/8394487520134514629561