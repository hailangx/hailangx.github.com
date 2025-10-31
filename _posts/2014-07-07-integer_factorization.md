---
layout: post
title: "质数分解 "
description: ""
categories: ["算法",""]
tags: ["质数","因式分解",""]
published: true
---

将n分解质因数的高效代码

    for(int i=2;i<=sqrt(n);i++)  
    {
        if(n%i==0&&(n/=i))  
            {
                cout<< i--; //i可以被整除，i--抵消for中的i++继续除i
            }
    }
    cout<< n; // n最后也为一个质因数
 
一般方法:

i从2开始到sqrt(n)的每一个i由n试除，如果能整除就再判断i是不是素数,如果是则i是n的一个质因子,然后n=n/i ，再将i归位回2 再寻找n的质因子
 
优化:

大致思路不变，进行了一些剪枝，首先还是i从2开始到sqrt(n)的每一个i由n试除 ,如果i能整除n，那么不用判断i，i必为n的质因子，将n=n/i  ，
因为n可能有多个相同的质因子，为了避免遗漏，只需将i-- ，当跳到下一步循环的时候与i++抵消，i的值不变，由于由2~i的每一个数都已经判断过是否能整除n，所以不必要再将i回退到2，只需另i在跳到下步循环的时候值不变即可，最后n也会被约成质数，也是一个质因子,这个优化来自[ Here][1]。

上面for循环中，求开方每次都有计算可以优化一下：

    for(int i=2,sqr=sqrt(n);i<=sqr;i++)  
    {
        if(n%i==0&&(n/=i))  
            {
                sqr=sqrt(n);
                cout<< i--;
            }
    }
    cout<< n;  

再改进，因为质数中除2外都是奇数，所以i可以一次前进两步：

    while(n%2==0)
    {
        cout<<2;
        n/=2;
    }
    for(int i=3,sqr=sqrt(n);i<=sqr;i+=2)  
    {
        if(n%i==0&&(n/=i))  
            {
                sqr=sqrt(n);
                cout<< i;
                i-=2;
            }
    }
    cout<< n;  

  [1]: http://blog.csdn.net/xinghongduo/article/details/5809607