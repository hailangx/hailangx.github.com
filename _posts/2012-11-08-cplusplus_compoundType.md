---
layout: post
title: "C++组合类型(compound type)"
description: ""
category: "C++"
tags: ["C++"]
published: true
---



C++中有一种"另类"的类型：compound type ，指针(`*`)、引用(`&`)等都是组合类型。把指针和引用看成是组合类型，也就是一种类型就会很容易理解一些概念。指针和引用都要和其它的内置类型一起构成组合类型。下面用组合类型来解释几个比较纠结的概念：

 - 常量指针和 指向常量的指针
 - 数组指针和 指针数组
 - 数组指针和指针数组
    
        int *matrix[10]; // an array of 10 int pointer elements
        int (*matrix)[10]; // a pointer to an array of 10 elements 
        int (matrix*)[10]; // equaval to int [][10]

 
    
第一样行是定义了数组，数组元素是整型指针，因为下标操作符优先级高所以先matrix[10] ,及matrix 是个数组，而类型为int * 型，即整型指针(组合类型)。第二行加了括号,先有*matrix 即matrix是指针，然后和下标结合为指向整型数组的指针。
常量指针和 指向常量的指针

    const int *p; // a pointer to const variable 
    int *const p; // a const pointer 
    const int *const p; a const pointer to const variable
把`int *` 看作组合类型，第一行，p先成为整型指针，然后是const 。因此p指针不是const ，指向的对象是const 。第二行，p显示const类型，然后是整型指针，因此p是const指针。
