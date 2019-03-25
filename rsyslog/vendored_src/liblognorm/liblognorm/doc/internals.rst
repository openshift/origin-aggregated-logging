Liblognorm internals
====================

Parse-tree
----------

A parse-tree is generated each time when normalization process is set up.

You could also call it a optimized rulebase. Each message runs through 
this tree consisting of parsers and fields and will be compared to it. The 
message can either fit into a branch or not. If it fits, it can be 
normalized. If it does not fit any branch in the tree, then a fitting 
sample has to be created for this message.
 
The tree is built from branches. These branches consist of 3 things: 
nodes, paths and parser.

A node is typically a literal part from a message where either a parser 
follows or there are several subsequent literals which are different, so 
one of the paths must be selected. After a parser, a node will always 
follow. Parsers are like variables and thus the core structure of a 
sample. With these a property field can be filled, which in the end is 
needed to normalize the message. 

A few notes on optimization of a parse-tree.

A parse-tree is always optimized, whether or not the samples of a similar 
kind are next to each other or not. Even if you make the order totally 
random, it should always result in the same parse-tree. Therefore, no 
optimization efforts have to be made to the tree itself. It reuses 
equivalent prefixes of messages which are already in the tree. Only if a 
difference occurs, then a new node must follow. 

One case where rule order can be significant is when a message can match
two or more different rules. This can occur when the rules differ in
parsers. If in doubt, use :doc:`lognormalizer <lognormalizer>` tool to 
debug.
