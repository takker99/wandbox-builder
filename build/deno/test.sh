#!/bin/bash

. ../init.sh

if [ $# -lt 1 ]; then
  echo "$0 <version>"
  exit 0
fi

VERSION=$1
PREFIX=/opt/wandbox/deno-$VERSION

test "`$PREFIX/bin/deno run $BASE_DIR/resources/test.ts`" = "Welcome to Deno!"
