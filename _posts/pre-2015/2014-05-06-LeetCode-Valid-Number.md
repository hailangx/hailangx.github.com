---
layout: post
title: "Leet Code: Valid Number"
description: ""
categories: ["Leet Code","算法"]
tags: ["Valid Number","Leet Code","有穷自动机"]
published: true
---


[QUESTION]

Validate if a given string is numeric.

Some examples:

    "0" => true
    " 0.1 " => true
    "abc" => false
    "1 a" => false
    "2e10" => true

Note: It is intended for the problem statement to be ambiguous. You should gather all requirements up front before implementing one.

[THOUGHT]

输入数据可划分为六类：

 - SIGN :   + -
 - DIGIT:   0-9
 - SPACE:   ' '
 - DOT  :    .
 - EXPONET: e E
 - INVALID: other

有两种比较好的解法：

 - **直接判断法：**根据e划分输入字符串，e前半部分为[SIGN]+[DIGIT]+[DOT]+[DIGIT]，后半部分为[SIGN]+[DIGIT] ，[这个家伙的解法][1]很好的把前后部分的判断合为一个函数，很简洁可以参考一下。
 - **有限状态机：**根据输入数据的种类，进行状态转移。具体的说就是列出所有可能的数字组成，画出状态转移图，合理的结束状态表示是合法数字。因为自从编译原理里面接触状态转移就从来没用过，这是第一次用有限状态机解决问题，所以详细画了个图，参考了[这里][2]。

合法的数字输入组合(方括号[ ]表示可有可无，无方括号表示必须具备)：

 - 无e数：
    - 小数点无：
        -  **[±]123 :** [SPACE] + [SIGN] + DIGIT + [SAPCE]
    - 小数点有：
        - **[±]123. :** [SPACE] +  [SIGN] + DIGIT  + DOT + [SAPCE]
        - **[±].123 :** [SPACE] +  [SIGN] + DOT    +  DIGIT  + [SAPCE]
        - **[±]1.23 :** [SPACE] + [SIGN] + DIGIT + DOT + DIGIT + [SAPCE]
 - 有e数：
    - 小数点无：
        - **[±]12e[±]3 :**  [SPACE] + DIGIT + e + [SIGN] + DIGIT + [SAPCE]
    - 小数点有：
        - **[±]123.e[±]4 :**  [SPACE] + [SIGN] +   DIGIT  + DOT + e + [SIGN] + DIGIT + [SAPCE]
        - **[±].123e[±]4 :** [SPACE] + [SIGN] +   DOT    +  DIGIT  + e + [SIGN] + DIGIT + [SAPCE]
        - **[±]12.3e[±]4 :** [SPACE] + [SIGN] +  DIGIT + DOT + DIGIT + e + [SIGN] + DIGIT + [SAPCE]

根据合法数字的情况可以画出状态转移图：

![数字识别有限状态机转移图][3]

[CODE]

使用-1表示非法状态，所有输入为INVALID都直接跳转到非法状态，状态转移表中表示状态转换。

<script src="https://gist.github.com/HaiyangXu/a10d25a21484fa5ab6d5.js"></script>
    
  [1]: http://leetcodenotes.wordpress.com/2013/11/23/leetcode-valid-number/
  [2]: http://www.cnblogs.com/chasuner/p/validNumber.html
  [3]: https://docs.google.com/drawings/d/1keoWD0g_tD5BgS5_CusVv19U6XCmXWlXo8oXQ4JC4SA/pub?w=480&amp;h=360