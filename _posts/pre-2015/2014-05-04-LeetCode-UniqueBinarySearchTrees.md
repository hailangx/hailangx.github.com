---
layout: post
title: "Leet Code: Unique Binary Search Trees I II"
description: "description"
categories: ["Leet Code","算法"]
tags: ["Leet Code","Unique Binary Search Trees"]
published: true
---

##Unique Binary Search Trees I 

###[Question]

[http://oj.leetcode.com/problems/unique-binary-search-trees/][1]

> Given n, how many structurally unique BST's (binary search trees) that
> store values 1...n?
> 
> For example, Given n = 3, there are a total of 5 unique BST's.
> 
     1         3     3      2      1
        \       /     /      / \      \
         3     2     1      1   3      2
        /     /       \                 \
       2     1         2                 3
       

###[Thought]

n个节点二叉搜索树的种类为$$f(n)$$，则左子树和右子树的节点个数可以分别为:

    0 n-1, 1 n-2 ,2 n-3,...,n-2 1,n-1 0

则，n个节点的二叉搜索树的种类等于每一种情况下左右子树种类乘积的和:

$$f(n)=f(0)*f(n-1)+f(1)*f(n-2)+...+f(n-2)*f(1)+f(n-1)*f(0)$$

其中，$$f(0)=1$$.

###[Code]

    class Solution {
    public:
        int numTrees(int n) {
            if(n<2)return 1;
            int sum=0;
            for(int i=0;i<n;++i)
            sum+=numTrees(i)*numTrees(n-i-1);
            
            return sum;
        }
    };
    
    
    
##Unique Binary Search Trees II

###[Question]

[http://oj.leetcode.com/problems/unique-binary-search-trees-ii/][2]

> Given n, generate all structurally unique BST's (binary search trees)
> that store values 1...n.
> 
> For example, Given n = 3, your program should return all 5 unique
> BST's shown below.
>
       1         3     3      2      1
        \       /     /      / \      \
         3     2     1      1   3      2
        /     /       \                 \
       2     1         2                 3
       
###[Thought]

和上一题不同的是要把所有情况输出，所以要知道所有左右子树的情况，对1..n中的每一个数都依次让它做root，然后分出左右区间，再递归求解。最后把左右区间求得的子结果依次分别作为root的左右孩子；当start>end时要返回null，使得每个re里面至少有一个元素（null），这样可以避免判断只有左区间或只有右区间的情况。

###[Code]

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
        vector<TreeNode *> generateTrees(int n) {
            return createBST(1,n);
            
        }
        
        vector<TreeNode *> createBST(int start,int end)
        {
            if(start>end)
            return vector<TreeNode*>(1,nullptr);
            vector<TreeNode *> re;
            for(int k=start;k<=end;++k)
            {
                
                vector<TreeNode *> lt=createBST(start,k-1);
                vector<TreeNode *> rt=createBST(k+1,end);
                for(int i=0;i<lt.size();++i)
                    for(int j=0;j<rt.size();++j)
                    {
                        TreeNode *root=new TreeNode(k);
                        root->left=lt[i];
                        root->right=rt[j];
                        re.push_back(root);
                    }
            }
            
            return re;
        }
        
    };


  [1]: http://oj.leetcode.com/problems/unique-binary-search-trees/
  [2]: http://oj.leetcode.com/problems/unique-binary-search-trees-ii/