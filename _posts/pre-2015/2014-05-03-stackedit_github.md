---
layout: post
title: "使用StackEdit写作备忘"
description: "description"
categories: ["效率"]
tags: ["StackEdit","GitHub"]
published: true
---

这个博客是用GitHub Pages托管的，具体来说是使用markdown写作后把md源文件提交到Github仓库，GitHub Pages使用Jekyll生成的这个静态站点，在刚开始使用的时候有很多不太方便的地方，现在熟悉了一些感觉用起来很方便，这篇博客就是记录一下用到的工具和需要注意的事情给自己备忘。

## YAML FrontMatter

YAML FrontMatter是源文件以三个`---`开头和结束的部分，例如这篇文章的FrontMatter是：

    ---
    layout: post
    title: "使用StackEdit写作备忘"
    description: "description"
    categories: ["效率"]
    tags: ["StackEdit","GitHub"]
    published: true
    ---
    
需要注意的是：

 - FrontMatter必须放在**文本最开头**，之前不能有任何内容包括空格
 - 每个变量后面的**冒号和值之间要空格**，否则Jekyll会无法提取FrontMatter。
 
##Mathjax支持

Jekyll的配置文件里面可以指定markdown的解析器，目前发现只有kramdown对Mathjax支持比较好，支持双美元`$$`作为间隔符。在文本中的公式会被解析为行内公式，前后有区间间隔（例如前后空行）的公式会被解析为区块公式。StackEdit中默认使用的是单个美元符号作为行内公式，双美元号作为区块公式，为了在StackEdit中公式显示和发表后基本一致，可以设置StackEdit的行内公式间隔为双美元号，在进行公式写作时，把要进行区块显示的公式前后空行。

##StackEdit写作

StackEdit是目前我见过最好的markdown编辑器了，所见即所得而且支持直接发表到GitHub。但是，它使用的markdown解析是基于JavaScript的Pagedown和kramdown语法并不完全一致，所以在StackEdit中看到的效果和发表到GitHub Pages上由kramdown解析的结果并不太一样，有时候还会有很大差别。

主要需要注意的就是，StackEdit中例如标题后面不空格也能很好的处理，但是kramdown并不一定，解决办法就是使用StackEdit的时候尽可能的清晰的使用空行来间隔各种元素。

##写作流程

避免如上的格式差异等困扰的一个很好的解决办法就是把html发布到Github Pages，但是我感觉这样就又回到了使用富文本编辑器写作(如Word)；和使用Wordpress博客系统没什么差别，文章内容和格式又混到一起去了，没有实现很好的分离。

所以我选择想办法解决这些差异，直接把md源文档提交到GitHub仓库，把写作的文章源文件直接版本管理起来，让GitHub Pages自动使用Jekyll生成静态的html站点，博文的md源文件进行了版本管理，格式和内容进行分离，很清爽。最后我GitHub仓库里面包存的就只有少许模版文件和我的纯markdown文章了，以后如果想要对博客进行调整的时候只需要对模版进行少许更改；要对文章进一步处理的话可以写一些脚本直接处理文章源文件，感觉就会很轻松。

至此，已经完全除去了后顾之忧了，放心写博客：

 1. 使用StackEdit写作，根据避免上面提到一些小问题
 2. 直接发布到GitHub
 3. GitHub Pages自动使用Jekyll处理更新

