---
layout: post
title: "C++自增运算符"
description: ""
category: "C++"
tags: ["C++"]
published: true
---


记得最初上C++课的时候老师说，`n=p++` 操作是先把p赋给n，然后p自增。这其实是个谬误，应该是老师不想给刚刚接触C++的我们增加麻烦，他也省了事，或者他真的不知道？

正确的理解应该是：

 - 根据优先级，后自增操作优先于赋值操作，所以先执行的是p++，即后自增操作。只是，后自增操作在对p进行自增操作前，会把当前值进行保存一个副本，然后对操作对象p进行自增操作.
 - 最后把保存的副本返回。 
 
因为有了额外的拷贝操作，也就不难理解为什么C++ Primer建议如非必要应该使用前自增以获得效率。相对于后自增，前自增直接对操作对象进行自增后返回，所以效率高。自减操作应该与此类同。

以前从来没有关注过效率问题，目前也还没碰到（代码敲的太少的过~）。C++ Primer中在循环测试中也一直倡导用!= 替换< 来判断结束，这二者之间是不是也应该有一些效率因素？

附上优先级

![enter image description here][1]



  [1]: https://lh4.googleusercontent.com/-Uunkc158XB4/UyQAdJR781I/AAAAAAAAApI/MgAcoms9n5k/s0/cplusplus_operator+precedence.png "cplusplus_operator precedence.png"
