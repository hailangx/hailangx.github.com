---
layout: post
title: "最长公共子序列和最长公共子串 "
description: ""
categories: ["算法"]
tags: ["动态规划","最长公共子序列","最长公共子串"]
published: true
---

**问题定义**：

最长公共子序列，序列的意思是顺序对就可以，并不需要是连续的。例如：

    ABCDE
    OALBLCLDLE

其中`ABCDE`就是这两个字符串的最长公共子序列。

容易知道一个长度为n的字符串的子序列有$$2^n$$个，假设两个字符串的长度都为n，直接去求解两个字符串的最长公共子序列需要用这$$2^n$$个序列串去匹配另外一个字符串，匹配一次的时间复杂度为$$O(n)$$，则总的时间复杂度为$$O(n·2^n)$$ ，显然效率非常之低。

最长公共子串，和上面最长公共子序列不同的地方在于需要匹配连续的字符串。直接求解的话，需要找到所有的公共子串，保留最长的即可。一个长度为n的字符串的子串个数可以有：

$$1+2+3+...+n=(n+1)n/2$$

上式每项分别对应于子串长度为$$n,n-1,n-2,n-3,...,1$$的子串个数。每个子串和另一个字符串进行匹配时间复杂度为$$O(mn)$$，`m`为子串长度，总时间复杂度约为$$O(n^4)$$.这样按子串长度排序，从最长开始匹配，如果匹配上了就退出。

简单的优化就是可以简单的通过记录子串的开始位置，然后依次进行比较找到最长，这样并不需要取出所有子串，如果不考虑字符串比较的时间，时间复杂度为$$O(n^2)$$, 但是进行串比较时，时间并不是$$O(1)$$所以总的时间应该在$$O(n^2)$$和$$O(n^3)$$ ,最坏情况出现在两个字符串完全相同的情况，这种情况下还是要比较完所有子串，每次子串比较耗时也最长。
上面这种考虑的代码：

    //from Ider's blog
    int longestCommonSubstring_n3(const string& str1, const string& str2)
    {   
        size_t size1 = str1.size();
        size_t size2 = str2.size();
        if (size1 == 0 || size2 == 0) return 0;
     
        // the start position of substring in original string
        int start1 = -1;
        int start2 = -1;
        // the longest length of common substring 
        int longest = 0; 
     
        // record how many comparisons the solution did;
        // it can be used to know which algorithm is better
        int comparisons = 0;
     
        for (int i = 0; i < size1; ++i)
        {
            for (int j = 0; j < size2; ++j)
            {
                // find longest length of prefix 
                int length = 0;
                int m = i;
                int n = j;
                while(m < size1 && n < size2)
                {
                    ++comparisons;
                    if (str1[m] != str2[n]) break;
     
                    ++length;
                    ++m;
                    ++n;
                }
     
                if (longest < length)
                {
                    longest = length;
                    start1 = i;
                    start2 = j;
                }
            }
        }
    #ifdef IDER_DEBUG
        cout<< "(first, second, comparisions) = (" 
            << start1 << ", " << start2 << ", " << comparisons 
            << ")" << endl;
    #endif
        return longest;
    }


最长公共子序列和最长公共子串的直接解法，显然不可取.时间复杂度都到4次方了。这两个问题都可以通过动态规划的思想来进行求解。

**动态规划解法**

使用动态规划的时候首先要找到最优子结构，即原问题的解可分解为求解子问题得到。这样就可以通过递归求解子问题而得到原问题的最优解。所以说这里是可以使用递归算法的，但是动态规划法比递归快的地方就是使用动态规划表记录子问题的解，因为较大规模子问题的求解包涵了对较小规模子问题的重复求解，通过子子问题的解可以求出子问题的解。

**最长公共子序列**

在最长公共子序列和最长公共子串中，用动态规划方法就要换个角度找到问题的最优子结构。前面的暴力法是从字符串的左边开始的，现在从字符串的右边开始考虑。

符号约定，S1,S2是两个字符串，LCS(S1,S2)表示S1,S2的最长公共子序列长度，C1是S1的最右侧字符，C2是S2的最右侧字符，S1'是从S1中去除C1的部分，S2'是从S2中去除C2的部分。

如果最右边字符相等，则LCS(S1,S2)=LCS(S1',S2')+1,如果不相等 LCS(S1,S2)=max(LCS(S1',S2),LCS(S1,S2')) ，当任意字符串长度为0时，返回0；

则LCS(S1,S2)等于：
    
 - LCS(S1,S2)=LCS(S1',S2')+1  若C1==C2
 
 - LCS(S1,S2)=max(LCS(S1',S2),LCS(S1,S2')) 若C1!=C2
 
 - LCS(S1,S2)=0 若S1或S2是空串

所以这里的结果需要使用一个二维表来记录，DP[X,Y] ，假设字符串S1,S2长度分别为m,n 则在程序中只需要开辟一个m*n的二维数组.DP[X,Y]就表示字符串S1(1,X),S2(1,Y)的最长公共子序列.则DP[X,Y]:

    if(X==0||Y==0)
        DP[X,Y]=0;
    else if(C1==C2)
        DP[X,Y]=DP[X-1,Y-1]= +1;
    else
        DP[X,Y]=max(DP[X-1,Y],DP[X,Y-1])

这样，可以先求解最小的子问题，然后查表求出较大子问题，最后求出最优解，消除递归。

**最长公共子串**

最长公共子串和上面最长公共子序列思想基本一样，只是最优子结构稍微不同。因为最长公共子串要求字符连续，所以当最后一个字符不同时**以这个字符结尾的最长公共子串长度**就变为0；还是简单的使用一个二维表来存储，LSUB(X,Y)表示S1中以X位置字符结尾,S2中以Y位置结尾的最长公共子串长度（这里的区别是，最长公共子串要**以这最后一个字符结尾**！)即二维表存储的是以当前字符结尾的最长公共子串的长度,所以在最后需要遍历二维表找到最长长度。

 - LSUB(X,Y)=LSUB(X-1,Y-1)+1 ;若S1[X]==S2[Y]

 - LSUB(X,Y)=0       ; 若S1[X]!=S2[Y]

最后遍历二维表，得到最大公共子串长度。


**动态规划时间复杂度**

从上面看出动态规划的整个求解过程就是对二维表进行填表，每个填表步骤都可以在$$O(1)$$内完成，则总的时间复杂度为$$O(n^2)$$ ,空间复杂度也为$$O(n^2)$$.

通过进一步压缩状态表，可以减少空间复杂度。可行的原因是，每次填表我们只用到了周边的表格数据,所以可以通过只保存需要用到的状态来压缩空间。

写的比较好的文章：

[从优化到再优化，最长公共子串][1]

[最长公共子序列][2]


  [1]: http://blog.iderzheng.com/longest-common-substring-problem-optimization/
  [2]: http://www.cnblogs.com/huangxincheng/archive/2012/11/11/2764625.html