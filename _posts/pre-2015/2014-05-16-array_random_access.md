---
layout: post
title: "数组真的是随机访问吗 ？"
description: ""
categories: ["基础知识"]
tags: ["存储结构","计算机的缓存机制","随机访问"]
published: true
---


我们都知道，数组是连续分配的内存，对数组的访问是随机的。也就是说不管我访问数组中的哪个元素，应该是相同的常数时间。书上是这么说的，老师也是这么教的，可是在计算机中真的是这样的吗 ？ 

下面的程序代码对数组分别进行按列和按行访问，为了避免内存初始化等的影响，把两个数组都在全局变量区定义。下面的代码统计了，对两个数组写一遍0的时间。

    #include <iostream>
    #include <ctime>
    using namespace std;
    
    int arrya[1024][1024];
    int arryb[1024][1024];
    void test()
    {
    
        clock_t start=clock();
        for(int i=0;i<1024;++i)
            for(int j=0;j<1024;++j)
                arrya[i][j]=0;
        clock_t end =clock();
        cout<<"T1:"<<end-start<<endl;
    
        for(int i=0;i<1024;++i)
            for(int j=0;j<1024;++j)
                arryb[j][i]=0;
        start=clock();
        cout<<"T2:"<<start-end<<endl;
    }
    
    int main()
    {
        test();
        return 0;
    }
    
看看结果吧：
    
    T1:0
    T2:50000

当然，用这个内置c函数统计出来的时间不是很精确，即使多试几次，总是会得到相似的情况，T2远大于T1，为什么呢 ？

这是因为数组在内存中是按列存储的，然后虽然理论上他们是连续分配的，但是由于计算机的缓存、页面调度等机制，按列访问数组时只会有很少的页面调度，而按行访问时会造成颠簸，即会频繁的把相同的页面掉进调出内存。当然了，数组比较小可能页面调度也不是问题，但是同样的理论也应用与CPU的高速缓存，所以不同方式访问时CPU的缓存命中率也不同。这样，访问速度差距会大的惊人。