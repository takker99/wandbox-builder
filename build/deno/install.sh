#!/bin/bash

. ../init.sh

if [ $# -lt 1 ]; then
  echo "$0 <version>"
  exit 0
fi

VERSION=$1
PREFIX=/opt/wandbox/deno-$VERSION

curl -fsSL https://deno.land/x/install/install.sh | DENO_INSTALL=$PREFIX sh -s "v$VERSION"
