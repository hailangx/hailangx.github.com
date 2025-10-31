---
layout: post
title: "HTTP协议Hands On"
description: "description"
categories: ["网络编程"]
tags: ["HTTP协议","telnet"]
published: true
---

打算继续刷题的时候发现出现了这个：

![502 Bad Gateway][1]

不能刷题了，那就来了解一下HTTP协议，虽然本科上过计算机网络，但是记得的东西只能呵呵了，出来混总是要还得。搜索了一下，网络上文字说明很多也很好，这里主要记录一下理解过程和代码。

HTTP协议是TCP/IP协议簇中属于应用层的协议，至于为什么要弄这么多协议和分这么多层协议我觉得就是为了便于功能分离和实现，也便于理解。感觉协议这个东西就是和计算机接口编程里面一样，就是传一个命令规定格式然后传数据，基本原理上大同小异。

HTTP协议是超文本传输协议，是一种请求/响应式的协议。一个客户机与服务器建立连接后，发送一个请求给服务器；服务器接到请求后，给予相应的响应信息。也就是说也就是在客户端和服务器端进行超文本传输的协议。
HTTP是在客户端和服务器端进行超文本传输的请求/响应协议，既然是双方的请求/响应传输协议，那么就得对双方进行协议约定了，宏观上讲HTTP规定了客户端对服务器发送请求的**请求格式**、服务器响应客户端的**响应格式**。中间就进行了很多详细和严格的规定了，细节上参考文献已经写的很详细了，下面通过一个例子来解释：

在window的DOS窗口下使用telnet[^1]来观察HTTP协议的运行过程。

 1. 在dos中输入：`telnet `进入telnet模式
 2. 设置回显模式，以便后面可以看见输入的命令：`set localecho ` 
 3. 打开一个连接:`open www.baidu.com 80` 80是HTTP默认端口号
 4. 输入:`ctrl+]`进入命令模式，然后回车进行telnet响应模式
 5. 输入，把下面的请求头粘贴到窗口 按**两次**回车，发送请求(这里下面两行前面不能有空格，如果复制的时候出问题先复制到记事本删除前面的空格)

         GET /index.html HTTP/1.1
         HOST: www.baidu.com
         
    上面两行就是非常简单的请求格式了，第一行`GET`表示使用GET方式，`/index.html`表示请求的页面为根目录下的`index.html`斜杠表示根目录不可以省略，或者直接使用`www.baidu.com/index.html` ,`HOST:`表示请求的主机
    
 6. 这时候窗口显示：
 
        GET /index.html HTTP/1.1
        HOST: www.baidu.com
        
        HTTP/1.1 200 OK
        Date: Sun, 11 May 2014 10:57:37 GMT
        Content-Type: text/html; charset=utf-8
        Transfer-Encoding: chunked
        Connection: Keep-Alive
        Vary: Accept-Encoding
        Set-Cookie: BAIDUID=C764FF5A8A8AD30956E3DC9C217951AB:FG=1; expires=Thu, 31-Dec-3
        7 23:55:55 GMT; max-age=2147483647; path=/; domain=.baidu.com
        Set-Cookie: BDSVRTM=0; path=/
        Set-Cookie: H_PS_PSSID=5230_1448_5224_6504_4759_6018_6462_6427_6382_6503; path=/
        ; domain=.baidu.com
        P3P: CP=" OTI DSP COR IVA OUR IND COM "
        Cache-Control: private
        Expires: Sun, 11 May 2014 10:57:18 GMT
        X-Powered-By: HPHP
        Server: BWS/1.1
        BDPAGETYPE: 1
        BDQID: 0xf407de870017c2d0
        BDUSERID: 0
        
        
        <!DOCTYPE html><!--STATUS OK--><html><head><meta http-equiv="content-type" conte
        nt="text/html;charset=utf-8"><link rel="dns-prefetch" href="//s1.bdstatic.com"/>
        ...


    后面还有一大堆html源码就没有帖上来了。可以看到，上面的GET那一部分就是我们发送给服务器端的请求命令，而下面从`HTTP/1.1 200 OK`一直到结尾是服务端发回的响应头和数据，因为请求了index.html这个文档，所以发送了index.html的源文件。
    
通过上面的列子，基本上已经知道HTTP协议的运作过程了(如果不成功，下载Xshell 输入`telnet www.baidu.com 80` 然后进行第5步操作)。客户端连接到服务器的80端口（连接这里用到了TCP协议，这里先不涉及），然后发送请求，服务器收到客户端的请求解析请求后发回响应，各种请求方式和格式规定参考连接里面写的非常详细了。

服务器返回状态码做个笔记：

 - 1xx：表明服务端接收了客户端请求，客户端继续发送请求；
 - 2xx：客户端发送的请求被服务端成功接收并成功进行了处理；  
 - 3xx：服务端给客户端返回用于重定向的信息；   
 - 4xx：客户端的请求有非法内容； 
 - 5xx：服务端未能正常处理客户端的请求而出现意外错误。

 
举例：

 -  “100”  ; 服务端希望客户端继续； 
 -  “200”  ; 服务端成功接收并处理了客户端的请求；
 -  “301”  ; 客户端所请求的URL已经移走，需要客户端重定向到其它的URL； 
 -  “304”  ; 客户端所请求的URL未发生变化； 
 -  “400”  ; 客户端请求错误； 
 -  “403”  ; 客户端请求被服务端所禁止； 
 -  “404”  ; 客户端所请求的URL在服务端不存在； 
 -  “500”  ; 服务端在处理客户端请求时出现异常； 
 -  “501”  ; 服务端未实现客户端请求的方法或内容； 
 -  “502”  ; 此为中间代理返回给客户端的出错信息，表明服务端返回给代理时出错； 
 -  “503”  ; 服务端由于负载过高或其它错误而无法正常响应客户端请求；
 -  “504”  ; 此为中间代理返回给客户端的出错信息，表明代理连接服务端出现超时。

在Leetcode上看到的那个502就是LeetCode使用的nginx代理返回的，nginx是啥 ？后面慢慢看。

下面是一个python下的简单HTTP请求演示函数（要在python 2下面用,2.7是没问题的，3.x就不行）：

    # Simple Python function that issues an HTTP request
    
    from socket import *
    
    def http_req(cmd,server, path):
    
        # Creating a socket to connect and read from
        s=socket(AF_INET,SOCK_STREAM)
    
        # Finding server address (assuming port 80)
        adr=(gethostbyname(server),80)
    
        # Connecting to server
        s.connect(adr)
    
        # Sending request
        request=cmd+" "+path+" HTTP/1.0\nHOST: "+server+"\n\n"
        s.send(request)
        
    
        # Printing response
        resp=s.recv(1024)
        while resp!="":
            print resp
            resp=s.recv(1024)
    
    
    http_req("GET","haiyangxu.github.io,"/about.html")



参考：

[HTTP 协议简介][2]  

[HTTP协议详解][3]

[How the web works: HTTP and CGI explained][4][^2]

  
  


  [^1]: 因为使用的win7，默认telnet关闭了；去控***制面板->程序->打开或关闭windows功能***  . 选中 **Telnet客户端**确定即可打开telnet了。但是在实际用的时候发现自带的telnet不太好用，显示的时候会出现覆盖，虽然后来解决了但是感觉还是不太好用，下了个Xshell用起来还不错。

[^2]: 后面打算把这个文章翻译一下，写的真不错


  [1]: https://lh3.googleusercontent.com/-zcH1HAcU2wY/U282k-g8NmI/AAAAAAAAAtA/unhHB9jH3_o/s500/~$2%5D%25CCD%5DUO%2828O%7BKR_IXH7.jpg "~$2]%CCD]UO&#40;28O{KR_IXH7.jpg"
  [2]: http://zsxxsz.iteye.com/blog/568250
  [3]: http://blog.csdn.net/gueter/article/details/1524447
  [4]: http://www.garshol.priv.no/download/text/http-tut.html