---
layout: post
title: "C++的const变量"
description: ""
category: "C++"
tags: ["C++"]
published: true
---





最初接触C++的时候，一直没有弄明白const变量有什么作用，怎么用，通过看C++Primer有了一点了解总结如下：

 
####1.const变量的定义
const变量即所谓常量，定义格式为：

    const type name=xx; 
    type const name=xx;
type 为变量类型 ，name为变量名。需要注意的是const变量类型在定义的时候要进行初始化，因为const变量定义之后就不允许修改了。

####2.const变量的作用域
在全局作用域（应该是函数体外）定义的const变量是定义该对象文件的局部变量，要使const变量在其它的文件中访问，必须显示的指定为extern ，而非const的变量默认为extern 。

####3.const引用
引用（&）在定义时必须绑定到对象即初始化，const引用是指向const对象的引用。非const引用只能绑定到与该引用同类型的对象，而const引用可以初始化不同类型的对象或者初始化为右值。使用非const变量初始化const引用也是可以的，实际上是发生了隐式类型转换，如果使用相同类型的变量初始化const引用，则该引用可以正确读取引用对象的值，但若使用不同类型，则有可能不能正确读取到引用对象被修改后的值了。因为在初始化时已经发生了转换，例如：

    double i=10.5;
    const int &x=i;
    cout<< i <<" "<< x <<endl; //10.5 10
    i=3.14;
    cout<< i <<" "<< x <<endl; //3.14 10
    
####4.const和指针
有const指针和指向const对象的指针两种。

    int w=0,y=1;
    int *const p=&w; //const指针/常量指针 必须初始化
    const int *q=&w; //指向const对象的指针
    
 -  const指针即常量指针，是指 指针值不可以更改，而可以改变指针指向的对象，即可以通过解引用（*）操作获取指向的对象并进行修改；
 -  指向const对象的指针，是指：指向的对象是常量的指针，指针值可以修改，即可以把指针指向其它const对象，但不能修改通过解引用（*）操作获取指向的const对象。

实际上，可以用非const变量地址初始化指向const对象的指针，只不过我们不能使用这个指针去修改所指向对象的值，因为编译器认为指向const对象的指针所指向的对象是const变量。

C++ Primer上还有一个关于指针和typedef的例子：

    typedef string *pstring;
    const pstring cstr;

这个cstr是什么呢 ？ 指向常量的指针（`const string *cstr`） ？ 错！ 由上面定义的实际上是个const指针，而非指向const变量的指针。为什么呢 ？因为我们错误的把typedef当作文本替换的作用了，认为 pstring 就是`string *`的替换，所以`const pstring cstr`就是 `const string *cstr `，所以是指向常量的指针。
正确的理解应该是上面定义了一个string类型的常量指针，*typedef定义了一个string类型的指针 pstring*，所以const修饰的是指针类型，把pstring看成一个类型，就很容易理解了。而且由于const标识符和类型名称前后次序都是正确的，所以就更加让人混淆了。pstring const cstr; 等同于上面的定义。实际上上面的定义在编译器中会报错的，别忘了const变量在定义的时候要初始化！

####5.const变量的位置
使用常理表达式初始化的const变量可以放在头文件中，因为在实际中编译器会把引用该const变量的地方改用常量表达式替换。若不是常理表达式初始化的const变量就不应该放在头文件中。

####6.const和形参
每次调用函数时，都会重新创建该函数的所有的形参，此时所传递的实参会初始化对应的形参。
对于非引用的形参，无论形参是const或者非const ，在调用时因为初始化复制了实参的值，所以对于函数调用来说实际上是一样的。若是引用形参，如果不是要改变传入的实参，一般都应该使用const引用，因为普通的非const引用形参在使用时不太灵活，因为不能使用const对象初始化非const引用，也不能用字面值和产生右值的表达式来初始化。如：

    string::size_type find_char(string &s,char c )
    {
    string::size_type i=0;
    while(i != s.size()&&s[i] !=c)
    i++;
    return i;
    }
    int i=find_char("this is a sample !",'i'); // 因为形参s是非const引用，不能使用字面值调用 ，改为const引用就可以
    
####7.const和类
const成员函数定义：只需要在成员函数的函数体前面，参数表括号后面 加上const关键字， int func() const {}
类的const成员函数不可以修改调用该该函数的对象。此外const对象、指向const对象的指针、const对象引用只能调用其const成员函数，如果调用非const成员函数则是错误的。

####8.const迭代器
迭代器有const和const_iterator ，const_iterator 可为const型容器的迭代器，不可使用迭代器解引用来更改容器中的值。
暂时只有这些了，后面有知道的再补充。 Update 2012-11-08
