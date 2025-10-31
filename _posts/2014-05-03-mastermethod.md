---
layout: post
title: "递归式的解法：主方法"
description: ""
categories: ["算法","Coursera"]
tags: ["递归式","主方法"]
published: true
---


#1.递归式时间复杂度解法

在计算算法渐进时间复杂度时，通常是需要求解递归式，递归式的解法主要有三种：

 1. 带入法： 对递归式猜测一个上界，然后使用数学归纳法证明上界的准确性。就可以得到递归式的渐进上界了，这种方法需要对递归式上界有一个较好的预测。
 2. 递归树解法： 画出递归式的递归调用树，计算每层子问题个数、子问题规模，对每层时间消耗求出总和，根据递归关系求出树高，然后对所有层进行求和得到递归式的总体规模。
 3. 主方法：对符合特定递归条件的递归式使用解析解法，递归式需为$$ T(n)=aT(n/b)+f(n) $$


本文主要对主方法进行直观的证明，以便理解主方法中三种情况的具体表现；对主方法的证明，可以更好的理解主方法并且在不需要死记硬背的前提下就记住了主方法的结论。 

#2.主方法

主方法使用的情况是递归式满足$$ T(n)=aT(n/b)+f(n) $$，在这种情况下主方法假设子问题具有相同的大小，主方法是一个用来解递归式渐进时间复杂度的黑盒工具。

递归式满足：


$$T(n)\le \begin{cases}
constant&for\ small\quad n\\
aT(\frac{n}{b})+O(n^d)&for general\quad n \end{cases}\label{master:asumption} $$     


 - a：子问题的数量
 - b：子问题大小的缩减系数
 - d：“归并”步骤运行时间对问题规模n的指数系数
 - a、b、d独立于n

这种情况下，根据主方法递归式的渐进时间复杂度为：

$$T(n)=\begin{cases}
O(n^dlogn)& if\quad a=b^d\ (Case 1)\\ 
O(n^d) &if\quad a<b^b\ (Case2)\\ 
O(n^{log_ba})&if\quad a>b^d\ (Case 3)
\end{cases} $$

> Case1中的log函数没有写base，因为这里的base仅仅对时间复杂度的影响仅仅在常系数下，而Case3中的log函数在指数上，所以不能忽略。

#3.主方法的直观证明

##前提

式$$\eqref{master:asumption}$$给定了主方法使用的条件，这里仅仅对主方法进行直观证明，所以可以假定`n is power of b`.

##基本推论

递归树总共有$$\log_bn$$层，层高为$$j$$ 时，有$$a^j$$个子问题，每个子问题的大小为$$n/b^j$$ .

这里先引入等比数列和公式：

$$  \text{for r}\ne\text{ 1 ,we have }\\ SUM=1,r,r^2,r^3,...,r^k=\frac{r^{k+1}-1}{r-1}$$

容易推出：

$$SUM\le\begin{cases} \frac{1}{1-r}=\text{a constant} & \text{for r<1} \\
r^k\cdot(1+\frac{1}{r-1})\le C\cdot r^k &\text{for r>1, C is a constant}
\end{cases}
\label{master:sum}$$

##分解证明

对递归树单独的一层来看，层高为j的时间复杂度为当前层的子问题数目与子问题规模的乘积：

$$L(j)\le a^j\cdot c\cdot(\frac{n}{b^j})^d=cn^d\cdot(\frac{a}{b^d})^j$$

定义：

 - a= 子问题的增长系数 rate of subproblem proliferation (RSP) 
 - $$b^d$$= 子问题规模缩减系数 rate of work shrinkage (RWS)

这里可以直观的发现，

 - 若RSP=RWS ，每一层时间相同；直观上，期望的时间复杂度为$$cn^dlog_bn$$
 - 若RSP< RWS，则主要的工作是在第一层 ；直观上，期望的时间复杂度为$$cn^d$$
 - 若RSP> RWS，则主要的工作是在叶节点 ；直观上，期望的时间复杂度和叶节点数目有关

下面进行具体的推导：

总的时间复杂度$$ T(n)$$为对递归树中层$$j=0,1,2,...,log_bn$$求和：

$$ T(n)\le cn^d\cdot \sum_{j=0}^{log_bn}(\frac{a}{b^d})^j \label{master:total} $$


则对于上面公式$$\eqref{master:total}$$中的$$m=\sum_{j=0}^{log_bn}(\frac{a}{b^d})^j $$, 可以让 $$r=\frac{a}{b^d}$$

根据$$\eqref{master:sum} $$, 可以推出：

$$m\le\begin{cases} log_bn &\text{for r=1}\\
\frac{1}{1-r}=\text{a constant} & \text{for r<1}\\
C\cdot r^{log_bn} &\text{for r>1, C is a constant}
\end{cases} $$

则总的时间复杂度：

$$ T(n)\le cn^d\cdot \sum_{j=0}^{log_bn}(\frac{a}{b^d})^j=cn^d\cdot m\\ 
\le\begin{cases}
cn^d\cdot log_bn =O(n^dlogn)&\text{for r=}\frac{a}{b^d}=1 &\text{Case1}\\
cn^d\cdot constant=O(n^d)  &\text{for r=}\frac{a}{b^d}<1 &\text{Case2}\\
cn^d\cdot C\cdot r^{log_bn}=O(n^d(\frac{a}{b^d})^{log_bn}) &\text{for r=}\frac{a}{b^d}>1  &\text{Case3}
\end{cases} $$

现在，Case1和Case2已经证明完毕，Case3的数学形式需要进一步推导。

$$n^d(\frac{a}{b^d})^{log_bn}=n^d\cdot a^{log_bn}\cdot(b^d)^{-log_bn}\\
=n^d\cdot a^{log_bn}\cdot(b^{log_bn})^{-d}=n^d\cdot a^{log_bn}\cdot n^{-d}\\
= a^{log_bn}$$

这里可以看到对于Case3，$$ T(n)\le a^{log_bn}$$ ,而这个$$a^{log_bn}$$正是叶子节点的数目。

$$a^{log_bn}$$更直观，但是$$n^{log_ba}$$更容易使用，二者其实是相等的：

$$a^{log_bn}=a^{(\frac{log_an}{log_ab})}=n^{\frac{1}{log_ab}}=n^{log_ba}$$

至此，对主定理的直观证明已经完成。

参考：
[Tim Roughgarden: Algorithms: Design and Analysis, Part 1][1]

  [1]: https://www.coursera.org/course/algo