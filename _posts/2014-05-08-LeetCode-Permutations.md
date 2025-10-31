---
layout: post
title: "Leet Code:Permutations"
description: "description"
categories: ["Leet Code","算法"]
tags: ["Leet Code","Permutations"]
published: true
---

**[Question]**

[link][1]

> Given a collection of numbers, return all possible permutations.
> 
> For example, [1,2,3] have the following permutations: [1,2,3],
> [1,3,2], [2,1,3], [2,3,1], [3,1,2], and [3,2,1].


**[Thought]**

给定一个序列abcd， 可能的排列情况如图所示：

![enter image description here][2]

进行排列时先把序列划分成两部分，第一个字符和剩余的n-1个字符，然后对剩余的n-1个字符进行全排列。

为了得到序列的全排列，第一个字符要分别为序列中的每一个字符，所以可以使用一个循环交换首字符，然后对后面n-1那一部分进行递归调用。这里实际上是一个深度优先搜索(DFS),搜索到叶节点之后往回回溯，数组记录了从根节点到叶节点的路径，得到的是依次递增的全排列（把图从左向右看，是不是一棵树？）。


**[Code]**

<script src="https://gist.github.com/HaiyangXu/37b862caac6b2a5c82cd.js"></script>

  [1]: http://oj.leetcode.com/problems/permutations/
  [2]: https://docs.google.com/drawings/d/10Q7Yf9JL0Iy_lreZUCFVRwP9Tr81yfh_6gbw4e7xETg/pub?w=480&h=360