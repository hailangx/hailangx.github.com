---
layout: post
title: "摄像机矩阵详解"
description: ""
categories: ["数学","三维重建"]
tags: ["摄像机矩阵","camera matrix","projection matrix"]
published: true
---


之前学习摄像机模型的时候弄得不是太清楚，现在记录一下。

##1.摄像机矩阵的分解
摄像机矩阵可以表示为如下形式：


$$ 
 P = [M  | -MC]  
$$


其中，$$C$$为摄像机在世界坐标系中的位置，求出摄像机的位置$$C$$只需要用$$-M^{-1}$$乘以摄像机矩阵最后一列。对摄像机矩阵进一步分解可得：

$$ 
 P = K [R | -RC ]=K [R | T ] 
$$

矩阵$$R$$是rotation矩阵，因此是正交的；$$K$$是上三角矩阵. 对P的前三列进行RQ分解就可得到$$KR$$ .一般的矩阵库里面都只有QR分解算法，所以可以使用QR分解替代。具体解释见[这里][1]，Richard Hartley and Andrew Zisserman's "Multiple View Geometry in Computer Vision"给的[code][2],其中`vgg_rq()`就是分解$$KR$$. RQ分解不为一，所以可以取使$$K$$的对角线元素都为正的分解，可以通过改变矩阵对应列/行的符号得到。

另外$$T=-RC $$ ,是摄像机坐标系下世界坐标系原点的位置，$$t_x, t_y, t_z$$的符号表示世界原点在摄像机的左右上下，前后关系。在三维重建中，一组标定好了的图片序列，它们摄像机矩阵计算出来的世界坐标系原点位置应该是相同了，因为所有的摄像机都校正到同一个坐标系了，(测试了数据集[3D Photography Dataset][3]中两个摄像机矩阵计算出来的世界坐标系原点确实是相同的，最起码说明标定没有错误).

其中$$K$$即为所谓的内参，$$R,T$$为外参。

##2.摄像机外参

摄像机外参数可以表示为3x3的旋转矩阵$$R$$和3x1的位移向量$$T$$:

$$[ R \, |\, \boldsymbol{t}] = 
\left[ \begin{array}{ccc|c} 
r_{1,1} & r_{1,2} & r_{1,3} & t_1 \\
r_{2,1} & r_{2,2} & r_{2,3} & t_2 \\
r_{3,1} & r_{3,2} & r_{3,3} & t_3 \\
\end{array} \right]$$

通常也会看到添加了额外一行(0,0,0,1)的版本： 

$$
\begin{align}
    \left [
        \begin{array}{c|c} 
            R & \boldsymbol{t} \\
            \hline
            \boldsymbol{0} & 1 
        \end{array}
    \right ] &= 
    \left [
        \begin{array}{c|c} 
            I & \boldsymbol{t} \\
            \hline
            \boldsymbol{0} & 1 
        \end{array}
    \right ] 
    \times
    \left [
        \begin{array}{c|c} 
            R & \boldsymbol{0} \\
            \hline
            \boldsymbol{0} & 1 
        \end{array}
    \right ] \\
        &=
\left[ \begin{array}{ccc|c} 
1 & 0 & 0 & t_1 \\
0 & 1 & 0 & t_2 \\
0 & 0 & 1 & t_3 \\
  \hline
0 & 0 & 0 & 1
\end{array} \right] \times
\left[ \begin{array}{ccc|c} 
r_{1,1} & r_{1,2} & r_{1,3} & 0  \\
r_{2,1} & r_{2,2} & r_{2,3} & 0 \\
r_{3,1} & r_{3,2} & r_{3,3} & 0 \\
  \hline
0 & 0 & 0 & 1
\end{array} \right] 
\end{align}
$$

这样做可以允许我们把矩阵分解为一个旋转矩阵跟着一个平移矩阵。这个矩阵描述了如何把点从世界坐标系转换到摄像机坐标系，平移矩阵$$T$$描述了在摄像机坐标系下，空间原点的位置；旋转矩阵$$R$$描述了世界坐标系的坐标轴相对摄像机坐标系的的方向。

如果以世界坐标系为中心，知道了摄像机的Pose，
$$[R_c|C]$$
即空间位置$$C$$和相对世界坐标系坐标轴的旋转$$R_c$$，怎么得到外参矩阵呢？给摄像机的pose矩阵添加(0,0,0,1)让它成为方阵，对pose矩阵求逆就可以得到外参矩阵。

$$
\begin{align}
\left[
\begin{array}{c|c}
R & \boldsymbol{t} \\
\hline 
\boldsymbol{0} & 1 \\
\end{array}
\right]
  &= 
\left[
\begin{array}{c|c}
R_c & C \\
\hline
\boldsymbol{0} & 1 \\
\end{array}
\right]^{-1} \\
  &= 
\left[
\left[
\begin{array}{c|c}
I & C \\
\hline
\boldsymbol{0} & 1 \\
\end{array}
\right]
\left[
\begin{array}{c|c}
R_c & 0 \\
\hline
\boldsymbol{0} & 1 \\
\end{array}
\right]
\right]^{-1} & \text{(decomposing rigid transform)} \\
&= 
\left[
\begin{array}{c|c}
R_c & 0 \\
\hline
\boldsymbol{0} & 1 \\
\end{array}
\right]^{-1} 
\left[
\begin{array}{c|c}
I & C \\
\hline
\boldsymbol{0} & 1 \\
\end{array}
\right]^{-1} & \text{(distributing the inverse)}\\
&= 
\left[
\begin{array}{c|c}
R_c^T & 0 \\
\hline
\boldsymbol{0} & 1 \\
\end{array}
\right]
\left[
\begin{array}{c|c}
I & -C \\
\hline
\boldsymbol{0} & 1 \\
\end{array}
\right] & \text{(applying the inverse)}\\
&= 
\left[
\begin{array}{c|c}
R_c^T & -R_c^TC \\
\hline
\boldsymbol{0} & 1 \\
\end{array}
\right] & \text{(matrix multiplication)}
\end{align}
$$

即：

$$\begin{align}
R  &= R_c^T \\
 \boldsymbol{t} &= -RC 
\end{align}$$

##3.摄像机内参

$$K = \left ( 
                \begin{array}{ c c c}
                f_x & s   & x_0 \\
                 0  & f_y & y_0 \\
                 0  & 0   & 1 \\
                \end{array}
            \right )
$$

其中$$f_x$$,$$f_y$$为焦距，一般情况下$$f_x=f_y$$ , $$x_0 ,y_0$$为主点坐标(相对成像平面),$$ s $$为坐标轴倾斜参数，理想情况应该为0.

内参$$K$$是2D的变换

$$\begin{align}
    K &= \left ( 
                \begin{array}{ c c c}
                f_x & s   & x_0 \\
                 0  & f_y & y_0 \\
                 0  & 0   & 1 \\
                \end{array}
            \right ) 
        \\[0.5em]
        &=
            \underbrace{
                \left (
                \begin{array}{ c c c}
                 1  &  0  & x_0 \\
                 0  &  1  & y_0 \\
                 0  &  0  & 1
                \end{array}
                \right )
            }_\text{2D Translation}
            \times
            \underbrace{
                \left (
                \begin{array}{ c c c}
                f_x &  0  & 0 \\
                 0  & f_y & 0 \\
                 0  &  0  & 1
                \end{array}
                \right )
            }_\text{2D Scaling}
            \times
            \underbrace{
                \left (
                \begin{array}{ c c c}
                 1  &  s/f_x  & 0 \\
                 0  &    1    & 0 \\
                 0  &    0    & 1
                \end{array}
                \right )
            }_\text{2D Shear}
    \end{align}
$$

 综合起来，摄像机矩阵可以由外参的3D变换和内参的2D变换组合起来：

$$
\begin{align}
    P &= \overbrace{K}^\text{Intrinsic Matrix} \times \overbrace{[R \mid  \mathbf{t}]}^\text{Extrinsic Matrix} \\[0.5em]
     &= 
        \overbrace{
            \underbrace{
                \left (
                \begin{array}{ c c c}
                 1  &  0  & x_0 \\
                 0  &  1  & y_0 \\
                 0  &  0  & 1
                \end{array}
                \right )
            }_\text{2D Translation}
            \times
            \underbrace{
                \left (
                \begin{array}{ c c c}
                f_x &  0  & 0 \\
                 0  & f_y & 0 \\
                 0  &  0  & 1
                \end{array}
                \right )
            }_\text{2D Scaling}
            \times
            \underbrace{
                \left (
                \begin{array}{ c c c}
                 1  &  s/f_x  & 0 \\
                 0  &    1    & 0 \\
                 0  &    0    & 1
                \end{array}
                \right )
            }_\text{2D Shear}
        }^\text{Intrinsic Matrix}
        \\&
        \times \qquad
        \overbrace{
        \underbrace{
             \left( \begin{array}{c | c} 
            I & \mathbf{t}
             \end{array}\right)
        }_\text{3D Translation}
        \times
        \underbrace{
             \left( \begin{array}{c | c} 
            R & 0 \\ \hline
            0 & 1
             \end{array}\right)
        }_\text{3D Rotation}
        }^\text{Extrinsic Matrix}
    \end{align}
$$


本文主要参考于[The Perspective Camera - An Interactive Tour][4]. 作者还提供了可以交互的demo.


  [1]: http://ksimek.github.io/2012/08/14/decompose/
  [2]: http://www.robots.ox.ac.uk/~vgg/hzbook/code/
  [3]: http://www.cs.wustl.edu/~furukawa/research/mview/index.html
  [4]: http://ksimek.github.io/2012/08/13/introduction/