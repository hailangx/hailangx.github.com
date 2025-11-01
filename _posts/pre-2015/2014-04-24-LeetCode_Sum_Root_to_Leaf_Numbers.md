---
layout: post
title: "LeetCode: Sum Root to Leaf Numbers"
description: ""
categories: ["算法","Leet Code"]
tags: ["Binary Tree","Sum Root to Leaf Numbers","Leet Code"]
published: true
---
中午回来刷Leetcode [Sum Root to Leaf Numbers][1] 

Question:

> Given a binary tree containing digits from 0-9 only, each root-to-leaf
> path could represent a number.
> 
> An example is the root-to-leaf path 1->2->3 which represents the
> number 123.
> 
> Find the total sum of all root-to-leaf numbers.
> 
> For example,
 
      1    
     / \   
    2   3 
 
>The root-to-leaf path 1->2 represents the number 12. The root-to-leaf path 1->3 represents the number 13.
> 
> Return the sum = 12 + 13 = 25.

这题，一次Accepted 哈哈，看来自己有进步啦！ 发现其实这个题目和之前做的很多二叉树是一个道理的，就是边遍历的时候要边保存当前节点的值和深度，遇到叶子节点根据保存的值和深度求出这个root-to-leaf 数字，把所有的root-to-leaft 数字加起来就是结果啦。

之前的题目有求最大深度，最小深度的其实都是一样了。具体怎么保存深度呢 ？递归遍历的时候传一个深度变量的引用，这样的话就知道当前的深度了，之前求最大最小深度的时候就是分别对左子树右子树求深度，然后比较大小这个思路。但是这一题不仅要叶子节点的深度，还要知道从根节点到叶子节点所有的值，这个时候其实用一个vector就可以既保存从根节点到叶子节点路径的值，vector的大小就是叶子节点的深度了，但是递归回溯到之前的节点时要把后面的路径值清空，看代码：

    /**
     * Definition for binary tree
     * struct TreeNode {
     *     int val;
     *     TreeNode *left;
     *     TreeNode *right;
     *     TreeNode(int x) : val(x), left(NULL), right(NULL) {}
     * };
     */
    class Solution {
    public:
        int sum=0;
        vector<int>numbers;//保存路径值的vector
        int sumNumbers(TreeNode *root) {
            if(!root) return 0;
            preTravel(root);
            return sum;
        }
        void preTravel(TreeNode *root)
        {
            numbers.push_back(root->val);
            int depth=numbers.size();//记住当前节点的depth
            if(!root->left&&!root->right)//leaf
            {
                int num=0;
                for(int i=0;i<depth;i++)
                {
                    num+=numbers[i]*pow(10,depth-1-i);
                }
                sum+=num;
                return ;
            }
            
            if(root->left)
            {
                preTravel(root->left);
                numbers.resize(depth); //递归完了把vector重置为到当前节点的路径值，后面的删掉
            }
            if(root->right)
            {
                preTravel(root->right);
                numbers.resize(depth);//好像不要也行。。。
            }
        }
    };


  [1]: http://oj.leetcode.com/problems/sum-root-to-leaf-numbers/