---
layout: post
title: "Algorithms: Week1"
description: ""
category: "Coursera"
tags: ["算法","Coursera","分治法"]
published: true
---


今天中午试用了一下 Coursera 批量下载的python代码coursera-dl，确实很好用。下载了[Algorithms: Design and Analysis, Part 1][1] 。



##Introduction
学习算法的好处是不言自明了，这个Standford的老师说他教算法并不是为了让你应付面试，不过他说学过算法课程的同学反馈说这门课对求职通过面试很有帮助，哈哈。

从乘法运算开始，$$5678*1234$$ 我们从小学就学会的做法就是每位相乘然后相加，

![enter image description here][2] 

总共需要 小于 $$n^2$$次乘法 ,有没有更好的办法呢 ？ 算法设计者的Mantra(咒语) 就是永远不要be content ，要永远问一句 Can we do better ?

[Karatsuba algorithm][3]就是一个快速计算n为数字相乘的算法，wiki了一下发现还有很多类似算法。Karatsuba algorithm的具体原理就是为了计算$$x*y $$ 若$$x=10^{n/2}a+b ,y=10^{n/2}c+d$$则 

$$x*y=(10^{n/2}a+b)*(10^{n/2}c+d)=10^{n}ac+10^{n/2}(bd+ad)+bd $$

则可以把x y拆成两半进行计算，然后继续把a b c  d拆成两半来计算，这样迭代下去进行计算直到只剩下一位相乘，这样就可以减少非常多的乘法运算次数了 。 另外可以把上面bd+ad 两次乘法减少为一次，因为 

$$(a+b)*(c+d)=ac+(bd+ad)+bd \\ (bd+ad)=(a+b)*(c+d)-ac-bd$$ 

而ac bd 我们已经算过了。所以只需要3次乘法就可以了：$$ac, bd, (a+b)*(c+d)$$ 
这里就是运用了分治法的思想，把n位数拆成两半减少乘法计算次数。


##Merge Sort
归并排序的思想就是把数组分成两部分排序，假定两部分已经排好序那么只需要把两部分合并就可以得到全部排序的序列了，分成的两个部分又可以继续使用这个思想进行分割和合并，这就是归并排序的主要思想了，递归到最底层的时候每一部分只有一个元素，合并的时候就直接得到排序的二元素序列了。

归并排序的时间复杂度分析 
归并的伪代码如下，可以看出对两个n/2长度的序列合并需要执行约4n+2 <=6n 行代码 (循环中for if 和两个赋值语句，和初始i j 赋值 )

    C = output [length = n]
    A = 1st sorted array [n/2]
    B = 2nd sorted array [n/2]
    i = 1
    j = 1
    for k = 1 to n
	if A(i) < B(j)
		C(k) = A(i)
		i++
	else 
		C(k) = B(j)
		j++
    end
    (ignores end cases)

容易知道长度为n(假定n为2的幂)的序列，递归深度为$$log_2(n)+1$$ ,如图第0层有1个序列长度为n ，1层有2个序列长度为n/2，... i 层有 $$2^i$$个序列 长度为 $$n/2^i$$ .则当长度为n 时深度为  $$log_2(n)+1$$ ，每层执行时间为  $$2^i*(6*n/2^i)=6n$$ ,总执行时间为

$$6n(log_2(n)+1)=6nlog_2(n)+6n$$

![enter image description here][4]



##Asymptotic Notation
渐进分析
算法的渐进分析就是估计当求解问题的规模 n 逐步增大时，时间开销 T(n)的增长趋势。为简化时间和空间复杂性的度量，可以只关注于复杂性的量级，而忽略量级的系数。而从数量级大小来考虑，当 n 增大到一定值以后，T(n) 计算公式中影响最大的就是 n 的幂次最高的项，其他的常数项和低幂次项都是可以忽略的。

渐进分析的结果是得到一个大 O 渐进表达式， 简写为


$$f(x)=O(g(x))\text{ as }x\to\infty $$ 

表示存在常数$$c$$ 使得

$$f(x)<=c* g(x)\text{  as }x\to\infty $$

 
##Guiding Principles of Algorithm Analysis
算法分析的三个指导原则：

 - 考虑最坏情况的时间复杂度
 - 不要过多考虑常系数、低次幂的项
     - 方便分析
     - 算法复杂度的常数项依赖于CPU、体系结构、编译器、程序员等任何因素
     - 只丢失了很小的精度，但保留了足够准确的预测能力
 - 渐进分析：考虑输入集较大时的运行时间



##Divide & Conquer Algorithms



  [1]: https://www.coursera.org/course/algo
  [2]: https://lh4.googleusercontent.com/-JqcjmJVWkLU/U0_h5AFfnYI/AAAAAAAAAqE/OdgL7QqtgEU/s450/G%257B%2524%255D78R1Y3T7HMH%2525U0%25287F5P.jpg
  [3]: http://en.wikipedia.org/wiki/Karatsuba_algorithm
  [4]: https://lh5.googleusercontent.com/-UGNKkRvdrEQ/U0_yI8tQ1yI/AAAAAAAAAqw/fAkapMQcQBE/w624-h324-no/merge.png