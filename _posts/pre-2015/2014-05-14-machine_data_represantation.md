---
layout: post
title: "数据机器级表示的缺陷"
description: ""
categories: ["基础知识"]
tags: ["数据的机器表示","C++"]
published: true
---


##1.一组例子
先看一组简单到不行的数学题：

    1e20+(-1e20)+3.14=  ?
    1e20+(-1e20+3.14)=  ?
           4000*4000>0  ?
         50000*50000>0  ?

只需要小学的知识就可以得到结果，但是如果是让计算机给我们算呢？

    #include <iostream>
    using namespace std;
    
    int main()
    {
        float i=1e20,j=-1e20,k=3.14;
        cout<<"1e20+(-1e20)+3.14="<<i+j+k<<endl;
        cout<<"1e20+(-1e20+3.14)="<<i+(j+k)<<endl;
        int m=4000,n=50000;
        cout<<"4000*4000>0 ? "<<(m*m>0)<<endl;
        cout<<"50000*50000>0 ? "<<(n*n>0)<<endl;
        cout << "Hello World!" << endl;
        return 0;
    }

用上面的c++代码计算出来的结果是这样的：

    1e20+(-1e20)+3.14= 3.14
    1e20+(-1e20+3.14)= 0
         4000*4000>0 ? 1
       50000*50000>0 ? 0

三个数不同顺序加出来的结果竟然不一样，两个正数相乘结果竟然为负了。这显然和我们通常的数学理论不一致。为什么会这样呢？因为在计算机中是用有限位来表示数据的，计算的时候并不一定能达到我们期望的精度，因此在编写程序的时候要注意，不能因为这种问题影响程序的正确性。

##2.整数的机器级表示

Unsigned :

$$ B2U(X)=\sum_{i=0}^{w-j}x_i \cdot  2^i$$

Signed Two's Complement:

$$ B2T(X)=-x_{w-1} \cdot 2^{w-1}+\sum_{i=0}^{w-2}x_i\cdot 2^i $$

`[0,w)`为二进制数位，为`w-1`符号位。

整形数值范围：

 - **无符号:** $$[0,2^{w}-1]$$
 - **有符号:** $$[-2^{w-1},2^{w-1}-1]$$
 
C/C++中的常数默认是有符号数，如果表示无符号数要加上后缀U。在涉及有符号和无符号数的运算时，有符号数会隐含转换成**无符号数**进行运算例如下面的代码：

        int i=-1;
        unsigned j=i;
        cout<<"  sizeof:"<<sizeof(i)<<endl;
        cout<<"  Signed:"<<i<<endl;
        cout<<"Unsigned:"<<j<<endl;
    
        i=-10;
        j=i;
        cout<<"  Signed:"<<i<<endl;
        cout<<"Unsigned:"<<j<<endl;
        cout<<"   -1<0 ?:"<<(-1<0)<<endl;
        cout<<"  -1<0U ?:"<<(0<0u)<<endl;
        cout<<"(int) 2147483648U :"<<(int)2147483648U<<endl;
        
得到的结果：

      sizeof:4
      Signed:-1
    Unsigned:4294967295
      Signed:-10
    Unsigned:4294967286
       -1<0 ?:1
      -1<0U ?:0
    (int) 2147483648U :-2147483648
    
###有符号数和无符号数的转换规则

 - 二进制位模式不变 
 - 但会重新解释
 - 导致为意料到的结果，加或减 $$2^w$$
 - 含有有符号和无符号的表达式中 有符号转换为无符号！( int -> unsigned )

###数位的扩展和缩减

在对不同二进制长度表示类型中进行转换时要进行二进制位的扩展或者缩减。

Expanding (e.g., short int to int)

 -  Unsigned: zeros added 
 -  Signed: sign extension 
 -  Both yield  expected result

Truncating (e.g., unsigned to unsigned short)

 - Unsigned/signed: bits are truncated Result reinterpreted 
 - Unsigned:   mod operation 
 - Signed: similar to mod 
 - For small numbers yields  expected behavior