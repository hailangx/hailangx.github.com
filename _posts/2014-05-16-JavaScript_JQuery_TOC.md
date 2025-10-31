---
layout: post
title: "用JQuery给文章生成目录"
description: "description"
categories: ["","category2"]
tags: ["TOC","JavaScript","JQuery"]
published: true
---

昨天写那篇关于编译连接的文章的时候有一个问题纠结了我很久，就是想用Google Spredsheet托管文章中的表格，直接用iframe嵌入进去，想让frame自适应大小，网上搜了一点资料死活没搞定，然后就一下午把w3cschool上关于JavaScript JQuery的简介看了个遍，想找个解决办法。结果最后结果发现这个涉及到跨域的信息传递，需要用代理frame可以解决这个办法，还有就是使用HTML5的一个postmessage的方法，可是我没办法修改Google提供的页面啊，所以最后选择把表格复制到google绘图，以图片的形式嵌入到文章中。

看了一下午的JavaScript简介、JQuery简介基本上就了解了个大概，就可以动手了。一直想给文章添加个目录，在StackEdit中直接用[TOC]标签就可以自动生成了，但是发表到GitHub上用kramdown处理，他不支持这个标签，kramdown实现目录的方式要在写作的时候添加太多标签了，不简洁。求助了一下Google，发现可以直接[用JQuery实现目录][1]。

然后根据我的博客改动了一下，基本就成功了。

具体是添加下面的JQuery函数到博客default模版的head中:

    <script type="text/javascript" >
	$(document).ready(function()
	{
		//$("#toc").append('<p>In this article:</p>');
		$("h1, h2, h3,h4").each(
		function(i) {
		var current = $(this);
		if(!current.hasClass('emphnext'))
		{
		current.attr("id", "title" + i);
		$("#toc").append("<a id='link" + i + "' href='#title" +
        i + "' title='" + current.attr("tagName") + "'>" + 
        current.html() + "</a>");
		}
		});
	})
    </script>

上面函数实现的功能具体就是找到h1 h2 h3 h4标签，给他们添加id属性，然后在toc节点下面添加连接。因为我的博客模版中标题和站名使用的是也是h1标签，但是他们有个class ="emphnext" 所以上面的代码把不需要出现在目录中的h1标签给排除了，当然可以更加优化一些，这是后面再折腾的了，今天先弄个样子出来。

然后因为文章使用的是post模版，就在post模版中添加一个id为toc的div标签，这样可以让文章产生目录，而其他页面不生成目录。
    
    <div id=toc></div>
    

最后在css中假如了下面的样式，让目录在屏幕的左边漂浮。

    /*TOC */
    #toc {width:250px; position:fixed; float:left; left:20px ;top:50px;}
    #toc a { display:block; color: #6C7479;}
    
这样一个目录就会生成了。下面来几个标题演示一下：

#一级目录演示

##二级目录演示

##再来一个二级目录

###三级目录演示

###再来一个三级目录
    
    
后续可以做的：给目录添加点效果，比如隐藏、显示，根据不同级别的目录显示缩进，优化上面的函数，让速度更快，比如上面先判断一下有没有toc再遍历h标签对于没有toc的页面加载会快很多吧。JavaScript还是很好玩的么，也很容易做出东西来，真的是让生活美好了很多。

  [1]: http://www.jankoatwarpspeed.com/automatically-generate-table-of-contents-using-jquery/