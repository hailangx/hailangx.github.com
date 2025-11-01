---
layout: post
title: "LeetCode: Word Break"
description: ""
categories: ["算法","Leet Code"]
tags: ["DP","动态规划"]
published: true
---

LeetCode [Word Break][1] 题目如下：

>  Given a string s and a dictionary of words dict, determine if s can
> be segmented into a space-separated sequence of one or more dictionary
> words.
> 
> For example, given s = "leetcode", dict = ["leet", "code"]. Return
> true because "leetcode" can be segmented as "leet code".

暴力的解法就是对s中每一个可能组合查找一遍,先找前缀在不在词典，如果再递归后面的部分(Time Limit Exceeded)：
    
    class Solution {
    public:
        bool wordBreak(string s, unordered_set<string> &dict) {
            if(s.empty())return true;
            for(int i=1;i<s.length();i++)
            {
                if(dict.count(s.substr(0,i))) //如果前缀s[0-i]在字典中就查后缀s[i-end]
                {
                    if(wordBreak(s.substr(i),dict))return true;//后缀可分，就直接返回true
                }
            }
            return false;
        }
    };
    
这中解法有非常多的重复求解，比如说

 - s[0,3)在词典中
 - 于是，需要看s[3,end)是否可以被分割 假设递归一遍最后发现s[3,end)不可以被分割
 - 这时候，我们就要看s[0,4)了，假如s[0,4)还是在词典中
 - 再看 s[4,end) ，这时候就和之前s[3,end)有很大一部分是重复的了,但是算法还是从头到尾又递归一遍了 

如果说我们先求了`s[i,end)`可不可以被分割，再求`s[j,end) (j<i)`可不可分的时候其实就可以省掉很多事情了，假设用一个数组`dp[x]`表示`s[x,end)`可不可分。 那么 :

 1. `dp[j]=true  if s[j,end) `在词典中
 2. `dp[j]=true  if exist i>j  d[i]=true (means s[i,end) in the dict)  `且 `s[j,i)`在词典中的话 
 3. `dp[j]=false `

这样就有三种情况了，上面是根据递归解法分割问题的时候从s的后面往前进行判断的，这样可以保证先求解小问题，后面的问题可以根据小问题的解减小搜索范围，如果`d[i]=false`的时候，根本就不用查询`s[j,i)`是不是在词典中，对于上面第2种情况，就是动态规划的状态转移了。 

上面是从后往前说明了状态的转移，其实在分割的时候从后往前还是从前往后结果都是一样的，把递归改一下就可以实现，先找后缀是不是在词典里面，如果在就递归前半部分（Time Limit Exceeded）:

    class Solution {
    public:
        bool wordBreak(string s, unordered_set<string> &dict) {
            if(s.empty())return true;
            for(int i=s.length();i>0;i--)
            {
                if(dict.count(s.substr(i))) //第一次i=len 假，则i=len-1
                {
                    if(wordBreak(s.substr(0,i),dict))return true;
                }
            }
            return false;
        }
    };

这个时候重复求解的就是`s[0,i)`所以如果说我们先求了`s[0,i)`可不可以被分割，再求`s[0,j) (j>i)`可不可分的时候其实就可以去掉重复求解子问题了，假设用一个数组`dp[x]`表示`s[0,x)`可不可分。 那么 :

 1. `dp[j]=true  if s[0,j)  in the dict`
 2. `dp[j]=true  if exist i<j , let d[i]=true && s[i,j) in the dict`
 3. `dp[j]=false `

所以就先求解小问题`s[0,i)`依次往后递推就可以了，代码如下 (Submission Result: Accepted)：

    class Solution {
    public:
        bool wordBreak(string s, unordered_set<string> &dict) {
            vector<bool> dp(s.length()+1,false);
            dp[0]=true; //形式统一起来，不用处理边界，就是说最开始找的时候只要存在于词典就为true
            for(int j=1;j<=s.length();j++)
            {
                for(int i=0;i<j;i++)
                {
                //s.substr(i,j-i)就是s[i,j) 当i=0就是从头开始的时候dp[0]=true 就完全取决于s[0,j)
                    if(dp[i]&&dict.count(s.substr(i,j-i))) 
                        {
                            dp[j]=true;
                            break;
                        }
                }
            }
            return dp[s.length()];
        }
    };
 
 以上主要动态规划中的核心的状态转移三种情况主要借鉴于[水中的鱼博客][2]. 
 
 其实上面的算法还是有很大优化空间，比如说字典中单词的最短长度min，最长长度max，只需要在[min,max]范围查找就可以了，但是如果字典特别长的时候，最短长度单词应该没有意义，因为最短一个长度的单词a,但是限制最长长度应该是比较有意思的；字典不大的时候也可以限制在[min,max]查找.
 
本文还参考了[这里][3] [这里][4]  [这里][5] 。


  [1]: http://oj.leetcode.com/problems/word-break/
  [2]: http://fisherlei.blogspot.com/2013/11/leetcode-word-break-solution.html
  [3]: http://gongxuns.blogspot.com/2013/10/word-break.html
  [4]: http://zhaohongze.com/wordpress/2013/12/10/leetcode-word-break/#comments
  [5]: http://blog.csdn.net/ljphhj/article/details/21643391