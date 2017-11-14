#!/bin/bash

# Usage: ./$0 <hash-of-the-initial-commit>

COMMITS=$(git log $1^..HEAD --oneline  --reverse | cut -d " " -f 1)

echo "Start checking out every commit from $1"
git log -n 1 --pretty=format:%s 63b920d
echo "Press anything to contine"
read fence

for COMMIT in $COMMITS
do
    git checkout $COMMIT

    echo "Press anything to contine"
    read fence
done
