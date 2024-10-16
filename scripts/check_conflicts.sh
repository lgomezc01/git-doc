#!/bin/bash

default_branch01="develop"
default_branch02="$(git branch --abbrev --show-current)"
branch01="$1"
branch02="$2"

if [ -z "$branch01" ] ; then
  read -p "Name of the first branch  [$default_branch01]: " branch01
  branch01=${branch01:-$default_branch01}
fi
if [ -z "$branch02" ] ; then
  read -p "Name of the second branch  [$default_branch02]: " branch02
  branch02=${branch02:-$default_branch02}
fi

ret=0
#Test to use:  --name-only (in merge-tree)
mergeTest=`git merge-tree --write-tree $branch01 $branch02` || ret=$?
if [ ! $ret -eq 0 ];then
   echo "Merge would result in conflicts:"
   echo "$mergeTest" | grep CONFLICT
   ## Do something useful here
   exit 1
fi