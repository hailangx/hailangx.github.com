---
layout: post
title: "LeetCode: Triangle"
description: "动态规划 Aha moment"
categories: ["算法","Leet Code"]
tags: ["动态规划","算法","顿悟"]
published: true
---

之前在一个[Better Explained][1]的网站中看到过关于常见数学的intuition解释，非常棒。"Aha" moment 就是作者说他文章的目的就是让人看了有一种"Aha" 的感觉，中文的意思就是让人顿悟、醐醍灌顶的时刻。之前本科在看书的过程中，对于计算机系统某些实现我也曾经有过几次这种感觉，但是由于没有记录下来已经不知道具体是对哪个部分有这种顿悟的感觉，给人的感觉就是：原来如此，原理原来很简洁，但是确实就是那样子，相当的巧妙，对于先驱们的智慧犹然升起一种敬佩之情。 如果学习的时候总是能体会到"Aha"的感觉，学习也就肯定是一种乐趣了，不过大多数时候我们都没有主动去寻找那种顿悟，总是被动的接受，而且我们接触到的老师们大多自己也并没有这种透彻的理解也就不太可能给我们解释清楚了。

扯远了，今天在刷LeetCode的时候看到这道[Triangle][2]的题目：

> Given a triangle, find the minimum path sum from top to bottom. Each step you may move to adjacent numbers on the row below.

>For example, given the following triangle

    [
         [2],
        [3,4],
       [6,5,7],
      [4,1,8,3]
    ]
    
>The minimum path sum from top to bottom is 11 (i.e., 2 + 3 + 5 + 1 = 11).

>Note:
Bonus point if you are able to do this using only O(n) extra space, where n is the total number of rows in the triangle.

刚看到这个题目，感觉有点复杂，可以用递归来做么，当前节点到底部的最短路径不就等于他的两个相邻后续的最短路径中最小的值加上当前值么，题目用了一个`vector<vector<int>>`来存储这个三角形，递归的话感觉有点繁琐，不过花点时间捣鼓一下边界处理应该就可以递归出来了，后来发现其实[递归代码][3]也很简洁。

偷了一下懒，就Google了一下，[别人][4]说可以用动态规划来做。不过他的代码太多，想到了用动态规划然后我就花了一点点时间就把代码给写出来了，而且比在网上看到的都要简洁很多：

    class Solution {
    public:
    int minimumTotal(vector<vector<int> > &triangle) {
        if(triangle.empty())return 0;
        
        int max=triangle.back().size();
        
        //最后一行拷贝到额外空间，并作为动态规划的表格
        vector<int> dp(triangle.back().begin(),triangle.back().end());
        
        for(int i=triangle.size()-2;i>=0;i--)
        {
            int s=triangle.at(i).size();
            for(int j=0;j<s;j++)
            {
                //每一行中当前位置的最小路径等于当前值加上他下一级的最小路径
                dp[j]=triangle[i][j]+min(dp[j],dp[j+1]);
            }
        }
        return dp[0];
        }
    };

主要思想是：

 - 如果知道下一行节点的最短路径值，就可以直接找到相邻两个节点的最短路径中的小值
 - 那么从最末行开始计算最短路径，并且开辟一个数组存储当前的最短路径值
 - 最后一行的长度最长，直接开辟一个这么大的数组来作为dp的存储 ，可以避免内存分配的开销

写出这不到20行的代码把问题解决之后，有一种很不可思议的感觉。算法/思维方式的转变可以让问题思路如此清晰，而且效率比复杂的递归更高。突然就发现动态规划这个思想是相当的牛B啊，之前看《数学之美》中介绍说维特比就是使用动态规划的思想。

递归里面有子问题的重复求解、函数递归调用代价，效率底，而且层数太多递归调用栈可能会溢出。动态规划就是把递归问题掉了个头，先计算递归问题的最底层，然后记录下了，层层网上迭代计算。最开始看到动态规划也是在LeetCode上的[Climbing Stairs][5]问题，这个爬楼梯问题其实就是一个斐波那契数列`F(n)=F(n-1)+F(n-2)`问题，通过递归的方式可以求解，但是由于子问题重复求解使得递归方法效率很低,用动态规划的方法就是依次求解，并且记录下结果`F(1), F(2), ... F(n)` 得到最后结果。


  [1]: http://betterexplained.com/about/
  [2]: http://oj.leetcode.com/problems/triangle/
  [3]: http://blog.csdn.net/zjull/article/details/11786643
  [4]: http://blog.unieagle.net/2012/10/31/leetcode%E9%A2%98%E7%9B%AE%EF%BC%9Atriangle%EF%BC%8C%E5%8A%A8%E6%80%81%E8%A7%84%E5%88%92/
  [5]: http://oj.leetcode.com/problems/climbing-stairs/
