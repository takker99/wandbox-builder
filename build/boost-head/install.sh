#!/bin/bash

. ./init.sh

if [ $# -lt 2 ]; then
  echo "$0 <version> <compiler>"
  exit 0
fi

VERSION=$1
COMPILER=$2

check_version $VERSION $COMPILER

PREFIX=/opt/wandbox/boost-$VERSION/$COMPILER
COMPILER_PREFIX=/opt/wandbox/$COMPILER
VERSION_TARNAME=$(echo $VERSION | sed 's/\./_/g')

# set flags

WITHOUTS="--without-mpi --without-signals --without-python --without-test"
ADDFLAGS=""
if [ $COMPILER = "clang-head" ]; then
  ADDFLAGS="<cxxflags>-Wno-unused-local-typedefs"
fi
if [ $COMPILER = "gcc-head" ]; then
  ADDFLAGS="$ADDFLAGS <cxxflags>-Wno-unused-local-typedefs"
  ADDFLAGS="$ADDFLAGS <cxxflags>-std=gnu++11"
  ADDFLAGS="$ADDFLAGS <cxxflags>-Wno-deprecated-declarations"
fi

# get sources

cd ~/
mkdir boost-$VERSION-$COMPILER
cd boost-$VERSION-$COMPILER

wget_strict_sha256 \
  http://downloads.sourceforge.net/project/boost/boost/$VERSION/boost_$VERSION_TARNAME.tar.gz \
  $BASE_DIR/resources/boost_$VERSION_TARNAME.tar.gz.sha256
tar xf boost_$VERSION_TARNAME.tar.gz
cd boost_$VERSION_TARNAME

# apply patches

DIR=`pwd`
pushd $BASE_DIR
./apply-patch.sh $DIR $VERSION
popd

# build

PATH=$COMPILER_PREFIX/bin:$PATH ./bootstrap.sh --prefix=$PREFIX
if [ "$COMPILER" = "clang-head" ]; then
  sed "s#using[ 	]*gcc.*;#using clang : : $COMPILER_PREFIX/bin/clang++ : <cxxflags>-I$COMPILER_PREFIX/include/c++/v1 <cxxflags>-nostdinc++ <linkflags>-L$COMPILER_PREFIX/lib $ADDFLAGS <linkflags>-stdlib=libc++ <linkflags>-Wl,-rpath,$COMPILER_PREFIX/lib ;#" -i project-config.jam
  ./b2 toolset=clang stage release link=shared runtime-link=shared $WITHOUTS -j2
  ./b2 toolset=clang install release link=shared runtime-link=shared $WITHOUTS --prefix=$PREFIX
else
  sed "s#using[ 	]*gcc.*;#using gcc : : $COMPILER_PREFIX/bin/g++ : <linkflags>-Wl,-rpath,$COMPILER_PREFIX/lib,-rpath,$COMPILER_PREFIX/lib64 ;#" -i project-config.jam
  ./b2 stage release link=shared runtime-link=shared $WITHOUTS -j2
  ./b2 install release link=shared runtime-link=shared $WITHOUTS --prefix=$PREFIX
fi

if [ "$COMPILER" = "clang-head" ]; then
  EXTRA_FLAGS="-lc++abi"
  test_boost_clang $PREFIX $COMPILER_PREFIX $EXTRA_FLAGS
else
  test_boost_gcc $PREFIX $COMPILER_PREFIX
fi

cd ~/
rm -r boost-$VERSION-$COMPILER

# share boost header

./share-boost-header.sh $VERSION $COMPILER
