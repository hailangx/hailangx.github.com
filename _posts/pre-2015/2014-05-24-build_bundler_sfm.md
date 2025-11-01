---
layout: post
title: "编译Bundler记录"
description: ""
categories: ["三维重建"]
tags: ["Bundler","SFM","三维重建"]
published: true
---


GitHub仓库 https://github.com/HaiyangXu/Bundler
仅仅是记录一下在Ubuntu 14.04下面编译Bundler时候遇到的问题：

cmake找不到：

-llapack  lapack库
-lblas    blas库
-lgfortran fortran 编译器

直接使用make编译：
gcc: error trying to exec 'f951': execvp:
缺少 -lgfortran 后面发现如果在linux下已经安装lapack blas库，根本没有用到gfortran，而windows使用f2c也不会用到。所以这个是个多于的依赖。在什么情况下需要使用gfortran呢 ？如果你从lapack 和blas 的fortran源代码编译的时候。


### lapack 和clapack

[Using CLAPACK][1] 这个里面说Matlab仅仅只是LAPACK的一个pretty warpper，并简要介绍了这个线性代数库如何使用。

LAPACK和CLAPACK的关系，[f2c][2] 是一个把Fortran语言翻译成c语言的程序，CLAPACK就是把LAPACK用f2c转换的C库。

安装：

sudo apt-get install libblas-dev liblapack-dev

 libblas-dev libblas3  (1.2.20110419-7) 
 liblapack-dev liblapack3  (3.5.0-2ubuntu1)

原始的cmake在linux下面使用上面安装的预编译lapack 和blas，而在windows下面需要使用f2c ，所以bundler中关于MATH_LIBS正确的依赖关系应该是：

    IF(WIN32)
    SET(MATH_LIBS clapack cblas cminpack f2c)
    ELSE(WIN32)
    #Clapack stuff is not the same under unix system
    SET(MATH_LIBS lapack blas cminpack )
    ENDIF(WIN32)


###处理时遇到的问题

安装ImageMagic处理图片，记住最后要使用ldconfig配置动态库，否则ImageMagick找不到动态库。具体见
ImageMagick-6.8.9-1
http://www.imagemagick.org/script/install-source.php


SIFT:
 util.c:330: ConvHorizontal: Assertion `cols + ksize < 8000' failed.

sift程序处理时，图片不能大于 4000*4000

std::vector<KeypointMatch>& MatchTable::GetMatchList(MatchIndex): Assertion `p.first != p.second' failed.

Bundler里面输出的，应该是不满足重建要求。

  [1]: http://www.cs.rochester.edu/~bh/cs400/using_lapack.html
  [2]: http://en.wikipedia.org/wiki/F2c