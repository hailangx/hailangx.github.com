---
layout: post
title: " LeetCode: Word Break Ⅱ "
description: ""
categories: ["算法","Leet Code"]
tags: ["动态规划","Word Break Ⅱ","LeetCode"]
published: true
---


最开始看到LeetCode Word Break I II 的时候，除了穷举法没有其他的思路，折腾了一下用一维动态规划把第一题[Word Break][1]做了。 而[Word Break II][2]就不是仅仅判断是不是可分了，还要把所有可分结果求出来。

首先还是可以用完全递归的方法，但是这个必然通不过，而且刚开始的时候递归也不怎么写的明白,主要问题就是递归的时候怎么保存结果。具体来说是这样子，从开头开始找，找到一个单词把他记录下来，然后就继续往后迭代找，假如说很顺利的找到了末尾一个完整的句子就保存了；可是，在每找到一个单词这一步可能还有其他单词的可能性，迭代返回的时候要在句子中删除这个单词，继续寻找新的可能。

迭代的时候对句子的保存可以使用一个 `string cur` ，在添加一个新单词的时候先保存`cur `的大小`size`，然后继续迭代；在迭代返回当前层的时候，将`cur`上次迭代时增加的单词去掉，返回当前状况，继续寻找新的可能性。这里用到的部分想法来自于[这里][3]的启发。

纯递归的代码如下：

    class Solution {
    public:
    vector<string> result;
    string cur;// current sentence
    vector<string> wordBreak(string s, unordered_set<string> &dict) { 
        int start=0;
        dfs(s,dict,start);
        return result;
    }
    void dfs(string &s,unordered_set<string> &dict,int &pos)
        {
            if(pos==s.length())
            {
                cur.pop_back();//remove the last blank
                result.push_back(cur);
                return;
            }
            for(int i=pos;i<=s.length();++i)
            {
                if(dp[i]&&dict.count(s.substr(pos,i-pos)))//if dp[i]=false will not recurse
                {
                    int size=cur.size();
                    cur+=s.substr(pos,i-pos)+' ';
                    dfs(s,dict,i);
                    cur.resize(size);
                }
            }
        }
        };


上面完全纯迭代的方法，效率肯定很低。可以用[Word Break][4]里动态规划的思想先求出一个`dp`数组，`dp[x]`表示`s[x,len)`是否可分，这和Word Break里表示`s[0,x)`是否可分刚好反过来了，即是判断尾部是否可分,所以求解`dp`的时候也是从字符串后面往前算的。在迭代的时候判断一下`dp[i]`，如果不可分就没有必要往下迭代了，代码如下：

    class Solution {
    public:
        vector<string> result;
        vector<bool> dp;// dynamic programming table
        string cur;// current sentence
        vector<string> wordBreak(string s, unordered_set<string> &dict) {
            dp=vector<bool> (s.length()+1,false);//dp[x]=true->s[x,len) in dict
            dp[s.length()]=true; //形式统一起来，不用处理边界，就是说最开始找的时候只要存在于词典就为true
            for(int j=s.length()-1;j>=0;--j)
                {
                    for(int i=s.length();i>j;--i)
                    {
                        if(dp[i]&&dict.count(s.substr(j,i-j))) 
                        {
                            dp[j]=true;
                            break;
                        }
                    }
                }
            if(!dp[0]) return result;//不可分
            int start=0;
            dfs(s,dict,start);
            return result;
        }
        //Deep First Search with dp hints ,if dp[i]=false will not recurse
        void dfs(string &s,unordered_set<string> &dict,int &pos)
        {
            if(pos==s.length())
            {
                cur.pop_back();//remove the last blank
                result.push_back(cur);
                return;
            }
            for(int i=pos;i<=s.length();++i)
            {
                if(dp[i]&&dict.count(s.substr(pos,i-pos)))//if dp[i]=false will not recurse
                {
                    int size=cur.size();
                    cur+=s.substr(pos,i-pos)+' ';
                    dfs(s,dict,i);
                    cur.resize(size);
                }
            }
        }
    };

但是后来发现，在LeetCode上会超时的就是那些本来就不可以被分割的的输入，就在`if(!dp[0]) return result;`这里起作用，如果不可分就直接返回了。后面递归判断`if(dp[i]&&dict.count(s.substr(pos,i-pos)))`去掉对`dp[i]`的判断也可以被Accepted ，具体的运行时间在LeetCode上不好比较，但是理论上来说加上`dp[i]`的判断，应该减少了很多递归次数。还看到一个，用[二维表的动态规划][5]，记录每个可分割位置的方法，感觉理论上比较快，但是测试运行了一下速度也没有特别快（也要36ms，和上面的一样），可能是应为LeetCode 的原因或者是数据集不够大.


  [1]: ./2014-04-23-leetcode_word_break
  [2]: http://oj.leetcode.com/problems/word-break-ii/
  [3]: http://blog.csdn.net/cs_guoxiaozhu/article/details/14104789
  [4]: /2014-04-23-leetcode_word_break
  [5]: http://blog.csdn.net/kenden23/article/details/19543349