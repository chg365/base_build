#!/bin/bash
 
VERSION1=$1
VERSION2=$2
 
# V1 > V2
function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
# V1 >= V2
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }
# V1 <= V2
function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }
# V1 < V2
function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }
 
if version_gt $VERSION1 $VERSION2; then
   echo "$VERSION1 > $VERSION2"
fi
    
if version_ge $VERSION1 $VERSION2; then
  echo "$VERSION1 >= $VERSION2"
fi
       
if version_le $VERSION1 $VERSION2; then
    echo "$VERSION1 <= $VERSION2"
fi

if version_lt $VERSION1 $VERSION2; then
    echo "$VERSION1 < $VERSION2"
fi
