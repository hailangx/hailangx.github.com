---
layout: post
title: "IOS离线WEB APP"
description: "description"
categories: ["前端技术","网络编程"]
tags: ["IOS","Web App","HTML 5","Python 服务器"]
published: true
---

下午加晚上折腾了一下，竟然就把我一直想弄成的一件事给弄成功了。可以把StackEdit 这个在线编辑器离线到ipad上去了。下面来整理一下过程吧。

##1. 一个简单的服务器

首先呢，假设app只有一个静态页面，我们先让这个静态的页面可以离线。需要一个服务器来托管呀，不能为了这个简单的需求我就去按个大型服务器吧，用Python来弄个小巧的HTTP服务器吧,下面的代码是我找了好久资料来回在Python 2.7和 3.4之间折腾，折腾出来的一个小服务器，反正目前已经满足了我的实验用途,主要折腾的地方是让服务器要正确的返回[MIME 类型][1]。下面代码中已经处理了实验需要用到的类型。

<script src="https://gist.github.com/HaiyangXu/ec88cbdce3cdbac7b8d5.js"></script>

把这个`server.py`脚本放置到要成为web服务器根目录的目录中，在终端(windows下就是dos咯)里切换到这个目录下面，运行：

    python server.py
    
好了，服务器就弄好了，地址是`localhost:8080` ，不过现在服务器我们啥也没放。

##2.增加一个web程序

这里只做实验用，就直接用一个静态的html页面来表示一个web应用吧。首先在服务器根目录增加一个`index.html`,内容如下：

    <!DOCTYPE html>
    <html>
    <head> 
    <title>APP</title>
    </head>
    <body>
    this is a offline app of ipad.
    </body>
    </html>

嗯，这个时候在浏览器打开`localhost:8080` 就可以看到这个简陋的web app了，知识简单的显示了:

    this is a offline app of ipad.
    
这个时候把服务器关掉，然后再打开`localhost:8080`刷新页面会出现什么呢？说无法打开这个连接了，因为我们把服务器关掉了，就相当于断网了。

##3.增加应用程序缓存Application Cache

HTML5中支持[应用程序缓存][2]，具体就是在html 上增加一个属性` manifest` ，把上面的`index.html`更改成:

    <!DOCTYPE html>
    <html manifest="local.manifest">
    <head> 
    <title>APP</title>
    </head>
    <body>
    this is a offline app of ipad.
    </body>
    </html>

然后在服务器根目录新建一个文本文件`local.manifest'，内容为：

    CACHE MANIFEST
    /index.html

这时候，再打开服务器，打开web地址`localhost:8080`，这个时候再关掉服务器和页面，然后重新打开`localhost:8080`会发现还是会显示`this is a offline app of ipad.` 也就是说页面内容离线了，即使无法连接到服务器浏览器还是可以得到web app的内容。

##4.应用程序缓存和浏览器缓存的区别

上面简单的例子说明了如何利用HTML5的特性让web应用离线，在用户暂时没有联网时也可以使用web应用。那么具体是怎么实现的呢？这里简单的介绍一下我的理解。有一个腾讯团队的blog对相关的问题有一个很详细的[文章系列][3]，可以参考一下。

浏览器缓存是通过判断缓存有效期和是否修改等信息来决定是否直接使用浏览器缓存，上面的服务器没有对这些信息进行处理。所以浏览器应该是默认不缓存，具体没有查证，不过根据上面之处的文章系列里面如果是用F5刷新是会让缓存控制失效，会向服务器直接请求资源。

应用程序缓存主要就是上面那个`local.manifest'里面的内容，如果设置了manifest属性，浏览器会把`local.manifest'里面的所有文件下载到本地存储起来，下次进行访问的时候会首先查看`local.manifest'这个文件是否更改，如果没有更改就直接使用存储起来的文件，如果有更改就重新下载，如果没有网的情况下，浏览器不知道`local.manifest'是否更改，就仍旧使用已经存储的文件，这样就达到了web app离线使用。

在设置了manifest之后，通过刷新页面观察服务器响应请求记录发现每次都只是`GET /local.manifest HTTP/1.1` ，浏览器会比较manifest文件是否有更改，如果没有更改就不进行任何请求了，直接使用存储的文件，如果manifest有更改就会把列表里的文件全部重新下载一遍。

##5.增加IOS 特定标签让app运行于standalone模式

给index.html增加标签

    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="black" />
    
其中apple-mobile-web-app-capable让web可以运行于全屏模式，apple-mobile-web-app-status-bar-style设置全屏时状态栏的样式。具体可以参考[这里][4]和[这里][5]
    
    <!DOCTYPE html>
    <html manifest="local.manifest">
    <head> 
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="black" />
    <title>APP</title>
    </head>
    <body>
    this is a offline app of ipad.
    </body>
    </html>

用ipad自带的Safari浏览器打开`localhost:8080` ，然后点击分享按钮->添加到主屏幕 完成后主屏幕就有一个指向这个web app的图标了，打开就像一个通常的native app一样全屏使用了，而且有独立的进程。



  [1]: http://www.w3school.com.cn/media/media_mimeref.asp
  [2]: http://www.w3school.com.cn/html5/html_5_app_cache.asp
  [3]: http://www.alloyteam.com/2012/03/web-cache-1-web-cache-overview/
  [4]: http://weizhifeng.net/make-web-app-more-native.html
  [5]: http://ecd.tencent.com/ios-webapp-icon.html