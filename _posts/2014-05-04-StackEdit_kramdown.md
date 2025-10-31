---
layout: post
title: "让StackEdit 和kramdown的MathJax兼容"
description: ""
categories: ["效率"]
tags: ["MathJax","kramdown","Jekyll"]
published: true
---

今天突然想到一个方法可以完全解决StackEdit的公式和kramdown公式不兼容的问题，而且不用像之前那样子麻烦，kramdown使用的是`$$`美元符号区别公式，以及是否有前后区块间隔判断是行内公式还是区块公式，经过kramdown处理后得到的html中已经给公式加上html标签是inline还是display的了。而StackEdit使用的是标准的MathJax配置，虽然可以自己定制但还是需要两种不同的间隔符。尝试设置MathJax使用`"$$","$$"`作为行内公式的分隔，`"\n$$","$$\n"`作为区分区块，可是MathJax不支持`\n`作为分隔符，如果这样子可以的话事情就简单很多了。

主要想法就是在StackEdit中设置`$$`作为行内公式，`$$$`作为区间公式间隔（为了和kramdown兼容前后空行），在向GitHub提交的时候可以给StackEdit编写一个插件自动将`$$$`替换为`$$`，这样在StackEdit中进行编辑时显示没问题，发布到GitHub上又符合了kramdown的语法，这样就和惬意了。

但是对JavaScript不熟，现在立马解决问题问题的办法是使用Template进行替换（虽然之前弄得Template解决办法现在看起来非常ugly，也是给现在这个解决办法打了基础）。

具体来说把StackEdit 中MathJax进行如下配置：

    TeX configuration { equationNumbers: { autoNumber: "all" } }
    tex2jax configuration { inlineMath: [["$$","$$"]],displayMath: [ ["$$$","$$$"] ], processEscapes: true }

> 其中Tex的配置是让公式自动编号，因为MathJax只支持区块公式自动编号，而在写作的时候公式全部用双美元号标记为行内公式就不能加label，那么想进行公式编号引用失去了及时预览的功能了，这是想到这个解决办法的动机来源。

发布时使用模版：

    <%print(documentMarkdown.replace(/(\$\$\$)/g,"$$$$") )%> 
    
`documentMarkdown`是StackEdit提供的变量表示markdown源文件，`replace()`是JavaScript中string的一个方法使用正则式[`/(\$\$\$)/g`][1]进行替换。后面`"$$$$"`其实是表示替换成两个美元号，因为美元号在这里具有[特殊含义][2],这里还可以用函数返回值方式解决美元号问题。

通过使用上述配置和模版，可以实现使用StackEdit写作是公式正常预览，发布后kramdown正确解析。后面有空可以写个插件看看。

> Written with [StackEdit](https://stackedit.io/).


  [1]: http://www.w3school.com.cn/jsref/jsref_obj_regexp.asp
  [2]: http://www.w3school.com.cn/jsref/jsref_replace.asp