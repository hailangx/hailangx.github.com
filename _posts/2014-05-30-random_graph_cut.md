---
layout: post
title: "Karger's Random Contraction Graph Cut"
description: "description"
categories: ["算法"]
tags: ["Graph Cut","Karger's Random Contraction Algorithm"]
published: true
---

在Coursera的Standford算法上有一题是让实现[Karger's Random Contraction Algorithm][1] for Min Graph Cuts.

粗略的给出了一个实现，优化空间非常大。现在记录一下遇到的问题。
Karger's Random Contraction Algorithm主要思想就是随机选择一条边，把这条边的两个node合并，一直到只剩下两个节点，节点之间的边数就是这个cut经过的边数。这样就随机得到图的一个cut，那么最小cut怎么得到呢？重复这个步骤多次，得到的最小的cut就认为是这个图的最小割，理论上可以证明这个概率还是很大的。

在实现Karger's Random Contraction的时候首先是数据结构的选择，因为使用邻接表的存储方式，所以我考虑使用一个二维数组`vector<vector <int>>` 按给的邻接表数据来存储。

每次随机的时候，先随机选择一个node，然后在这个node的临近边中随机选择一条边`<node,_node>`，最后把`_node`合并到`node`上。

合并的时候：

 1. 遍历邻接表，所有指向`_node`的替换成`node`
 2. 把节点`_node`的连接表添加到节点`_node`上
 3. 删除节点`_node`
 4. 去除`node`节点的环(即自己指向自己)

因为使用的是`vector<vector <int>>`数据结构，所以在上面步骤1的时候需要注意的问题是：

 - `_node`节点后面会被删除，索引会改变
 - vector删除元素的时候会把后面位置向前移动
 - 所以位置大于`_node`的节点索引都要减去一个1 
 - 所以在步骤1的时候遍历的同时要判断是否大于`_node`，进行减1操作 替换成`node`的时候也要考虑是替换成`node `or `node-1`

合并步骤基本就完了，然后就是不断进行合并直到节点数为2.

代码在Gist上[https://gist.github.com/HaiyangXu/93df14ae616adc764ee6][2]
 
想过的优化：

 - 把存放边的vector改成排序的链表，这样在找是否等于`_node`的时候时间复杂度就只有logn，但是因为索引要改变，不管你排不排序都要全部遍历一遍，干脆不用排序了，也不用链表
 - 删除操作是否要优化？使用vector进行删除的时候，就是把后面的向前移动了，没有进行内存分配
 - 在这种数据存储下还没有想到更好的优化方法，要进一步优化应该要使用其他的数据存储方式。

随机性：
    使用rand得到的随机一点也不随机，后面研究一下随机数生成问题。

  [1]: http://en.wikipedia.org/wiki/Karger%27s_algorithm
  [2]: https://gist.github.com/HaiyangXu/93df14ae616adc764ee6