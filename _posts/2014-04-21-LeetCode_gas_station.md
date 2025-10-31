---
layout: post
title: "LeetCode: Gas Station"
description: ""
categories: ["算法","Leet Code"]
tags: ["Gas Station","动态规划"]
published: true
---
之前找别人的解体方案的时候总是习惯性的找有文字描述的，今天看到这个[Gas Station][1]的题目，文字说明到让我有点糊涂，代码加公式的描述竟然更好理解。

这篇博客里面说Gas Station的问题其实是[最大子段和][2] ，只不过是一个循环的。然后就Google了一下最大子段和的求法，发现这个[最大子段和详解（N种解法汇总）][3] 里面描述了各种解法，非常好。不过其中分治发和动态规划发的文字描述虽然很详细却并不好理解，而[这篇][4] 文章里面几个公式加代码让我一下就看懂了。具体就是：

> 问题：

>  给定n个整数（可能为负数）组成的序列a[1],a[2],a[3],…,a[n],求该序列如a[i]+a[i+1]+…+a[j]的子段和的最大值。当所给的整均为负数时定义子段和为0，依此定义，所求的最优值为：
    Max{0,a[i]+a[i+1]+…+a[j]},1<=i<=j<=n
    例如，当（a1,a2,a3,a4,a4,a6）=(-2,11,-4,13,-5,-2)时，最大子段和为20。
    
分治法：

> 将a[1n]分成a[1n/2]和a[n/2+1n],则a[1n]的最大字段和有三种情况:
    (1)a[1n]的最大子段和与a[1n/2]的最大子段和相同
    (2)a[1n]的最大子段和与a[n/2n]的最大子段和相同
    (3)a[1n]的最大子段和为ai++aj,1<=i<=n/2,n/2+1<=j<=n
    T(n)=2T(n/2)+O(n)
    T(n)=O(nlogn)
 
    
    int MaxSum_DIV(int *v,int l,int r)
    {
    int k,sum=0;
    if(l==r)
        return v[l]>=0?v[l]:0;
    else
    {
        int center=(l+r)/2;
        int lsum=MaxSum_DIV(v,l,center);
        int rsum=MaxSum_DIV(v,center+1,r);

        int s1=0;
        int lefts=0;
        for (k=center;k>=l;k--)
        {
            lefts+=v[k];
            if(lefts>s1)
                s1=lefts;
        }

        int s2=0;
        int rights=0;
        for (k=center+1;k<=r;k++)
        {
            rights+=v[k];
            if(rights>s2)
                s2=rights;
        }
        sum=s1+s2;
        if(sum<lsum)
            sum=lsum;
        if(sum<rsum)
            sum=rsum;
    }
    return sum;
    }

动态规划法：
>b[j]=max{a[i]+...+a[j]},1<=i<=j,且1<=j<=n,则所求的最大子段和为max b[j]，1<=j<=n。
> 由b[j]的定义可易知，当b[j-1]>0时b[j]=b[j-1]+a[j]，否则b[j]=a[j]。故b[j]的动态规划递归式为:
>b[j]=max(b[j-1]+a[j],a[j])，1<=j<=n。
> T(n)=O(n)

    
    int MaxSum_DYN(int *v,int n)
    {
    int sum=0,b=0;
    int i;
    for (i=1;i<=n;i++)
    {
        if(b>0)
            b+=v[i];
        else
            b=v[i];
        if(b>sum)
            sum=b;
    }
    return sum;
    }
    
这个[题要用反证法来理解][5]。算法：

 - 从i开始，j是当前station的指针，sum += gas[j] – cost[j] （从j站加了油，再算上从i开始走到j剩的油，走到j+1站还能剩下多少油）
 - 如果sum < 0，说明从i开始是不行的。那能不能从i..j中间的某个位置开始呢？假设能从k (i <=k<=j)走，那么i..j < 0，若k..j >=0，说明i..k – 1更是<0，那从k处就早该断开了，根本轮不到j。
所以一旦sum<0，i就赋成j + 1，sum归零。**如果最后total为正，则一定可以到达最后那个i就应该为起点**
 - 最后total表示能不能走一圈。
 - 这个题算法简单，写起来真是够呛。对数组一快一慢双指针的理解还是不行。注意千万不能出现while (i < 0) { i++, A[i]}这种先++然后取值的情况，必须越界。

代码：

    public class Solution {
        public int canCompleteCircuit(int[] gas, int[] cost) {
            // Note: The Solution object is instantiated only once and is reused by each test case.
            int N = gas.length, startIndex = -1;//为什么是-1 ？
            int sum = 0, total = 0;
            for(int i = 0; i < N; i++){
                sum += (gas[i] - cost[i]);
                total += (gas[i] - cost[i]);
                if(sum < 0){
                    startIndex = i; 
                    sum = 0;
                }
            }
            return total >= 0 ? startIndex + 1 : -1;
        }
    }


  [1]: http://oj.leetcode.com/problems/gas-station/
  [2]: http://www.cnblogs.com/TenosDoIt/p/3389924.html
  [3]: http://blog.csdn.net/zhong36060123/article/details/4381391
  [4]: http://www.cnblogs.com/hustcat/archive/2009/06/01/1493949.html
  [5]: http://leetcodenotes.wordpress.com/2013/11/21/leetcode-gas-station-%E8%BD%AC%E5%9C%88%E7%9A%84%E5%8A%A0%E6%B2%B9%E7%AB%99%E7%9C%8B%E8%83%BD%E4%B8%8D%E8%83%BD%E8%B5%B0%E4%B8%80%E5%9C%88/