---
layout: post
title: "LeetCode: Remove Duplicates from Sorted Array II"
description: ""
categories: ["算法","Leet Code"]
tags: ["LeetCode","Remove Duplicates"]
published: true
---

[Remove Duplicates from Sorted Array II ][1]

[Question]

> Follow up for "Remove Duplicates": What if duplicates are allowed at most twice?
> 
> For example, Given sorted array A = [1,1,1,2,2,3],
> 
> Your function should return length = 5, and A is now [1,1,2,2,3].

[Thought]

要保留最多2个，可以抽象出来让最多保留maxduplicates个。对数组遍历一遍就移除重复元素，使用pre和cur两个指示器，每次向前移动时判断cur位置的元素是否保留还是丢弃，若保留则复制到++pre位置，则pre cur分别表示无用区间的首尾，即(pre,cur]为移除元素，初始时都指0区间为空，判断当前元素的重复次数count， 若重复次数小于maxduplicates则一边复制一边移动两个指示器，将当前元素全部复制到pre的位置，若重复次数大于maxduplicates则只复制要保留的次数，然后把cur置于正确的位置，到最后pre指向最后一个剩余元素。
如图：

     pre
      ↓
    |   |   |   |   |   |   |   |
      ↑
     cur
     
         pre
          ↓
    |   |   |   |   |   |   |   |
                  ↑
                 cur

代码：


    class Solution {
    public:
        int removeDuplicates(int A[], int n,int maxduplicates=2) {
            if(n<=maxduplicates)return n;
            int pre=0;
            int cur=0;
            while(cur+1<n)
            {
                int count=0;//num of duplicates
                while(cur+1+count<n&&A[cur]==A[cur+1+count])++count;//count the duplicate
                if(count>maxduplicates-1)//重复次数大于maxduplicates,
                {
                    int temp=maxduplicates-1;
                    while(0<temp--)A[++pre]=A[++cur];pre只移动最大保留个数
                    cur+=count-maxduplicates+1;//移动count-duplicates cur置于正确位置
                }
                else while(0<(count--))A[++pre]=A[++cur];//重复次数小于阈值，完全移动
                
                if(cur+1<n) A[++pre]=A[++cur]; //移动到下一个不同元素位置
            }
            return pre+1;
        }
    };
> Written with [StackEdit](https://stackedit.io/).


  [1]: http://oj.leetcode.com/problems/remove-duplicates-from-sorted-array-ii/