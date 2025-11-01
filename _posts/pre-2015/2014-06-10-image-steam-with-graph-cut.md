---
layout: post
title: Graph Cut的一个有趣应用
description: description
categories: 
  - 算法
  - 三维重建
tags: 
  - Graph Cut
  - 图像拼接
published: true
---


之前看了graph cut的问题，这里有一个简单又有趣的应用，问题是这样的：

给定两幅相似或者相同图像，二者相互overlay .找到一个最好的分割，让两幅图像拼接到一起，形成最好的“混合”效果，而不使用实际的alpha blending。

![graphcut_apple_example.jpg](/images/2014/graphcut_apple_example.jpg)

这里可以使用Graph Cut解决这个问题，具体来说就是把两幅图重合的部分使用一个Graph来建模，重叠部分对应的像素点作为一个节点，每个节点赋值为两个像素颜色的absolute difference norm ，就是两个像素值向量的[范数][2]；边的权重为边所连接两个节点的值的和，Graph的左边为SOURCE节点（代表左image），Graph的右边为SINK节点（代表右image）。对这个Graph求最小割，直观上就可以知道，这个最小割就是对两幅图像重叠部分最接近的位置进行拼接。

![enter image description here][3]


结果：

![graphcut_apple_result.jpg](/images/2014/graphcut_apple_result.jpg)

代码包含了maxflow library  [http://vision.csd.uwo.ca/code/][5] 


  
  [2]: http://zh.wikipedia.org/wiki/%E8%8C%83%E6%95%B0
  [3]: https://docs.google.com/drawings/d/1YwKtONVx6SIO4l9wBRAayzvc9No9g7-8D6pYUD6bx9w/pub?w=695&h=401
  
  [5]: http://vision.csd.uwo.ca/code/