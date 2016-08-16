#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "usage $0 <start-commit..end-commit> [<version>]"
    exit 1
fi

# Do not generate cover letter for one commit
if [ $1 == "HEAD^" ]
  then
    COVER=""
  else
    COVER="--cover-letter"
fi

if [ -z "$2" ]
  then
    VERSION=""
  else
    VERSION=" $2"
fi

git send-email --dry-run --cc-cmd=cocci_cc.sh --annotate $COVER -n --subject-prefix="PATCH$VERSION" --thread=shallow ${1}
