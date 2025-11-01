---
layout: post
title: "#1039 : 字符消除"
description: "description"
categories: ["hihoCoder"]
tags: ["字符消除","hihocoder"]
published: true
---

from http://hihocoder.com/problemset/problem/1039

**描述**
小Hi最近在玩一个字符消除游戏。给定一个只包含大写字母"ABC"的字符串s，消除过程是如下进行的：



1)如果s包含长度超过1的由相同字母组成的子串，那么这些子串会被同时消除，余下的子串拼成新的字符串。例如"ABCCBCCCAA"中"CC","CCC"和"AA"会被同时消除，余下"AB"和"B"拼成新的字符串"ABB"。

2)上述消除会反复一轮一轮进行，直到新的字符串不包含相邻的相同字符为止。例如”ABCCBCCCAA”经过一轮消除得到"ABB"，再经过一轮消除得到"A"



游戏中的每一关小Hi都会面对一个字符串s。在消除开始前小Hi有机会在s中任意位置(第一个字符之前、最后一个字符之后以及相邻两个字符之间)插入任意一个字符('A','B'或者'C')，得到字符串t。t经过一系列消除后，小Hi的得分是消除掉的字符的总数。



请帮助小Hi计算要如何插入字符，才能获得最高得分。



输入
输入第一行是一个整数T(1<=T<=100)，代表测试数据的数量。

之后T行每行一个由'A''B''C'组成的字符串s，长度不超过100。



输出
对于每一行输入的字符串，输出小Hi最高能得到的分数。



提示
第一组数据：在"ABCBCCCAA"的第2个字符后插入'C'得到"ABCCBCCCAA"，消除后得到"A"，总共消除9个字符(包括插入的'C')。

第二组数据："AAA"插入'A'得到"AAAA"，消除后得到""，总共消除4个字符。

第三组数据：无论是插入字符后得到"AABC","ABBC"还是"ABCC"都最多消除2个字符。



样例输入

> 3 
> ABCBCCCAA
>  AAA
>   ABC

样例输出

> 9
> 4
> 2
 
 基本思路是模拟消除，先写一个reduce函数出来进行字符串消除；然后在每一个字符直接分别插入 `A B C`，进行消除。

使用一个指针对字符串从左到右进行处理，每一次只处理当前字符：根据上一次的标记以及与后一个字符是否相等，并对后一个字符保留一个标记。
如果当前字符`i`和后一个字符`i+1`相同，那么这两个字符都不要了,标记`keep=false`；如果不同则复制当前字符`i`并标识`keep=true`，移动指针。
Note: 初始化`keep=true` ,并再最后结束时需要对最后一个字符根据标记进行处理。

    int reduce(string &arr){
        if(arr.empty())return 0;
        int pos=0;
        bool keep=true;//flag
        for(int i=0;i<arr.size()-1;i++){
            if(arr[i]==arr[i+1]){
                keep=false;
            }
            else{
                if(keep)arr[pos++]=arr[i];
                keep=true;
            }
        }
        if(last)arr[pos++]=arr[arr.size()-1];
        if(arr.size()==pos)return pos;
        arr.resize(pos);
        return reduce(arr);
    }

然后对输入的字符进行插入，模拟缩减即可；这里有一个疑惑：开始想着要优化一下代码，先对字符串进行reduce，然后对剩余的进行插入reduce，这样可以减少不少计算，可是为什么不对呢？还没有想到一个反例，可以hihoCoder上的测试用例跑不过, 下面注释掉的代码就是先进行reduce然后对剩余依次插入。

    int main(){
        int nums=0;
        cin>>nums;
        while(nums--){
            string str;
            cin>>str;
            int maximum=1;
            //int before=str.size()-reduce(str);//remove duplicate first
            //cout<<before<<" ";
            char arr[]="ABC";
            for(int i=0;i<str.size();i++){
            	for(int j=0;j<3;j++){
            		string strdup(str);
    	            strdup.insert(i,1,arr[j]);
    	            int num=strdup.size()-reduce(strdup);
    	            maximum=max(maximum,num);
            	}
    
            }
            //cout<<maximum+before<<endl;
            cout<<maximum<<endl;
        }
        
    } 


完整代码Gist https://gist.github.com/86fe534fc3baaa26470d.git

 Written with [StackEdit](https://stackedit.io/).

