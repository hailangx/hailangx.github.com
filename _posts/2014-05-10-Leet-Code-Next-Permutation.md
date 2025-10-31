---
layout: post
title: "Leet Code ：Next Permutation"
description: "description"
categories: ["Leet Code","算法"]
tags: ["Leet Code"]
published: true
---

**[Question]**

> Implement next permutation, which rearranges numbers into the
> lexicographically next greater permutation of numbers.
> 
> If such arrangement is not possible, it must rearrange it as the
> lowest possible order (ie, sorted in ascending order).
> 
> The replacement must be in-place, do not allocate extra memory.
> 
> Here are some examples. Inputs are in the left-hand column and its
> corresponding outputs are in the right-hand column.
> 
>     1,2,3 → 1,3,2
>     3,2,1 → 1,2,3
>     1,1,5 → 1,5,1

**[Thought]**

为了得到下一个排列，要尽可能小的增长这个序列。
例如对于 01 的下一个排列，我们应该对最右边的1进行加一得到 02，而不会对左边的0进行加1得到11.也就是说我们应该对右边的低位序列进行增长，这样才能保证最小的增长。

 - 首先就要找到右边最长的非递减子序列，如下图5330 ，这个后缀已经是最大的序列了我们无法对他进行增长，所以要对这个最长的非递减序列的左边的一个数2上进行增长。
 - 要保证最小增长，那么我们要从后缀5330中找到最小的那个大于2的数和2进行交换
 - 交换过后我们要保证后缀最小，才能保证最小增长，而后缀已经是非递减的了，所以逆序即可

 参考[ref][1]

![enter image description here][2]

**[Code]**

<script src="https://gist.github.com/HaiyangXu/e79e6f3cdb349fb7111e.js"></script>

  [1]: http://nayuki.eigenstate.org/page/next-lexicographical-permutation-algorithm
  [2]: https://lh5.googleusercontent.com/-9nYQ3upP5Tg/U25ETR1VnyI/AAAAAAAAAss/yUQd6BDgi9w/s500/next-permutation-algorithm-thumb.png