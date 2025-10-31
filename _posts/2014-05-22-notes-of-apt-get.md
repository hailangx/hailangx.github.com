---
layout: post
title: "apt-get 使用笔记"
description: ""
categories: ["Linux","笔记"]
tags: ["Linux","apt-get","Unable to locate package"]
published: true
---


编译NetworkManager 的心得：

configure的时候说找不到xx ,于是就用`sudo apt-get install xx`结果它告诉你 **Unable to locate package** . 于是我就Google这个xx，才发现它的包名叫xx3 坑死你。比如在configure NetworManager的时候他说缺少nss 直接apt-get install nss 就是Unable to locate package 。Google之后发现它的包名叫nss3 ，汗！

经验：

1. dpkg -l package-name-pattern列出任何和模式相匹配的软件包。假如您不知道软件包的全名，您能够使用“*package-name-pattern*”。
2. 多Google
3. 还是多Google,比如在编译NetworkManager的时候他说缺少 pppd/pppd.h ，搞半天这个在包ppp中！

> Written with [StackEdit](https://stackedit.io/).