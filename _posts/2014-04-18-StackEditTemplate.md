---
layout: post
title: "StackEdit With Github Pages"
description: ""
category: "效率"
tags: ["StackEdit","GitHub Pages","Jekyll","MathJax"]
published: true
---



 <p>今天终于捣鼓出了一个在 <a href="https://stackedit.io/">StackEdit</a>上写东西，直接发Github Pages的好办法了。</p>

<p>在GitHub上搭建个人博客是一件很有趣的事情，GitHub本是一个在线版本托管平台，发布博客到GitHub就可以把博客内容也用Git管理起来了。GitHub Pages 使用Jekyll生成静态的博客，主要流程就是：首先使用markdown写作博文发布到GitHub，然后Jekyll会解析YAML头，根据你的模版生成静态站点，其中博客内容会使用markdown解析器进行解析。因此，可以直接使用markdown写作然后发布markdown源文件到GitHub。</p>

<p>再之后呢陆续发现了StackEdit Mathjax等好东西，StackEdit 是一个在线markdown写作App，可以及时预览所以用起来非常爽，而且StackEdit直接支持MathJax的<code>$</code> <code>$$</code>标记的公式。直接使用StackEdit进行文档写作并且生成PDF一点问题没有，但是如果我用StackEdit写作时把包涵用<code>$</code> <code>$$</code>标记的Latex公式markdown发布到GitHub上就会有问题，因为Jekyll 的默认markdown解析器maruku 不支持MathJax的公式标记，转换时会导致公式中的一些字符变成HTML实体从而导致MathJax不能正确解析公式。</p>

<p>在网上查到的资料是更改配置文件，让Jekyll使用kramdown作为markdown解析器。Kramdown支持<code>$$</code>标记的公式，但是它并不是根据<code>$</code>的数目来决定公式是inline的还是不是的，这样本身没有什么问题，但是我使用StackEdit的时候就会有问题了。StackEdit使用MathJax的默认配置，根据<code>$</code>的数目来决定是不是行内公式。这样我用StackEdit写出来的包涵公式的markdown在StackEdit中看起来好好的，如果让kramdown来解析的话就又会出问题了，因为kramdown只支持<code>$$</code>来标记公式，根据<code>$$</code>前后是否空行来判断是行内公式还是显示型公式。</p>

<p>如果kramdown和StackEdit的markdown解析一样的话天下就太平了，可是他们就是不一样。但是我又不想放弃StackEdit这么好的写作体验，解决办法就是我是用StackEdit写作，保存文章成html标记的，然后再给html添加YAML头以便Jekyll可以处理它给他正确的模版和链接。</p>

<p>这样感觉很繁琐，于是我就想知道可不可以直接让StackEdit给我的html加上YAML头呢 ？捣鼓了好长时间未果，今天下午终于解决了！</p>

<p>StackEdit的模版功能貌似是用<a href="shttp://underscorejs.org/#template">underscorej</a> 这个库的template函数实现的，反正是对JavaScript没一点了解，捣鼓了一下发现StackEdit 提供给自定义模版使用的变量frontMatter 是一个object 然后直接frontMatter[“_frontMatter”] 就可以把markdown中的头输出到使用模版生成的html里面了，这样我就可以直接在StackEdit中书写的时候添加YAML头然后让它根据模版直接输出到html文件中就可以了。</p>

<p>在StackEdit中使用如下模版：</p>

<pre><code>&lt;%
if (frontMatter.hasOwnProperty("_frontMatter")) 
    print(frontMatter["_frontMatter"]);
%&gt;
&lt;%= documentHTML %&gt;
</code></pre>

