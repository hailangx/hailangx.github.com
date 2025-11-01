---
layout: post
title: "Ubuntu源更新时Hash Sum mismatch的原因及解决办法"
description: "description"
categories: ["Linux","遇到的问题"]
tags: ["Ubuntu更新源","Hash Sum mismatch","Hash校验和不符"]
published: true
---

今天在给Ubuntu安装PCL库的时候更新硬是出错，根据PCL官网的说明添加了deb源，在`apt-get update`的时候出现"Hash Sum mismatch" 即Hash校验和不符.因为没有更新成功，这个时候使用`apt-get install libpcl-all` 的话就找不到软件包。最后我用Goagent代理更新源，就解决这个mismatch问题了，然后就顺利安装好了。

为什么会出现这个问题呢？万能的Google告诉了我答案：

> 我们网络供应商，有些会设置一些透明缓存，以增加网络内部速度，减少出口的流量，你获取的某些文件不是源服务器上的真正文件，是从缓存中获取的，当缓存中获取的一些校验信息跟源中不一致的时候，自然提示校验失败，无法继续更新。[参考这里][1]

就是说是因为ISP设置了代理缓存（之前刚刚翻译过一篇文章，关于[WEB的运行原理简介][2] 里面介绍了代理缓存）, 这时候HTTP请求并没有直接发送到源服务器，而是被代理缓存截获了，代理缓存直接就把你请求的文件返回给你了，但是代理缓存还没及时更新，所以你得到的文件和源服务器是不一致的，导致了哈希校验和不一致。什么是哈希校验呢？参看[一致性hash算法释义][3]和[一致性哈希算法及其在分布式系统中的应用][4]。

解决办法就有两个：

 - **换一个源** 
 就是你请求别的服务器呗，这个服务器中的文件如果代理缓存没有缓存或者缓存是一致的，那么问题就解决了。
 - **使用代理**
使用代理就是你不直接请求源服务器，而是把请求发送到代理服务器，然后代理服务器去请求源服务器。这样就可以绕过ISP的代理缓存，直接从源服务器得到请求文件了。

Ubuntu下使用代理应该对于使用liunx的大神们来说是很容易的事情了，不过一般情况下我都是在windows下面使用goagent+chrome,所以我就再找了一下直接使用goagent给ubuntu进行代理的方法。具体就是根据goagent的文档配置一下goagent，然后在Ubuntu的设置->网络 设置goagent的代理地址和端口就好了。开着goagent，然后`sudo apt-get update` 就完事了。 

  [1]: http://forum.ubuntu.org.cn/viewtopic.php?f=52&t=423516
  [2]: ./2014-05-11-How_web_works_HTTP_and_CGI
  [3]: http://www.cnblogs.com/haippy/archive/2011/12/10/2282943.html
  [4]: http://blog.codinglabs.org/articles/consistent-hashing.html