---
layout: post
title: "Leet Code : Median of Two Sorted Arrays "
description: "description"
categories: ["Leet Code","算法"]
tags: ["Leet Code","Median of Two Sorted Arrays"]
published: true
---

**[Question]**

http://oj.leetcode.com/problems/median-of-two-sorted-arrays/

There are two sorted arrays A and B of size m and n respectively. Find the median of the two sorted arrays. The overall run time complexity should be O(log (m+n)).

**[Thought]**

第一种解法是直接归并到一个数组 O(n) 时间复杂度。

较好的解法是把这个问题看成在两个排序数组中查找Kth 元素进行折半查找，折半的时候也有不同的做法：

 - 对[数组A 和B 折半][1]，判断大小去掉不可能区间
 - 对前K个元素进行折半，本文采用这种方法

查找函数定义为`double findKth(int A[],int m,int B[],int n,int k)`
本题求median，则奇数个时直接查找中间值，偶数个时返回中间两个数的平均值。

使用两个指示器pa、pb分别指向两个数组， 且使 pa+pb=k，直观上感觉如果让这k个元素为两个数组中的前k个元素，那么pa 、pb所指的其中一个就应该是Kth.

 
               pa
               ↓
    A    |    |   |   |   |   |   |   |
        
                   pb
                   ↓
    B    |    |   |   |   |   |   |   |   |   |
 

最坏情况下m 、n都大于 k/2 ，让pa=k/2  pb=k/2
则每次判断A[k/2-1] B[k/2-1]的大小，舍弃一半的查找区间，并减小k ，当k=1时返回区间头的最小值。

但是实际时可能出现的情况：

 - 一个数组为空，直接返回另一个数组中第k个元素即可
 - k=1 ，返回各个数组头中较小的
 - pa、pb所指相等了，这个时候pa、pb所指刚好是第k个元素
 - 根据pa、pb所指元素大小，舍弃部分区间减小k值进行迭代

**[Code]**

<script src="https://gist.github.com/HaiyangXu/c540a545c380fb25c070.js"></script>


  [1]: http://fisherlei.blogspot.com/2012/12/leetcode-median-of-two-sorted-arrays.html