#!/bin/bash

set -e

# Path-conversion for Windows
FSTAR_HOME="$(dirname $(which fstar.exe))/.."
if which cygpath >/dev/null 2>&1; then
  FSTAR_HOME=$(cygpath -m "$FSTAR_HOME")
fi

# Couldn't get clang to work on Windows...
if which clang >/dev/null 2>&1; then
  HAS_CLANG=true
else
  HAS_CLANG=false
fi

# Detection
KREMLIB="../kremlib"
OPTS="-Wall -Werror -Wno-parentheses -Wno-unused-variable -std=c11 -I $KREMLIB"
CLANG_UB="-fsanitize=undefined,integer"
if $HAS_CLANG && clang $CLANG_UB main.c >/dev/null 2>&1; then
  CLANG="clang $CLANG_UB $OPTS"
else
  CLANG="clang $OPTS"
fi

# On OSX, to get GCC, one needs to call gcc-5; on other systems, the gcc command
# is wired to a recent GCC.
if which gcc-5 >/dev/null 2>&1; then
  GCC=gcc-5
elif which x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
  GCC=x86_64-w64-mingw32-gcc
else
  GCC=gcc
fi
GCC="$GCC $OPTS"

echo GCC is $GCC
if $HAS_CLANG; then
  echo "CLANG is $CLANG"
else
  echo "CLANG was not detected"
fi

LOWLEVEL_LIB="$FSTAR_HOME/examples/low-level/"
CRYPTO_LIB="$FSTAR_HOME/examples/low-level/crypto/"
FSTAR_OPTIONS="--lax --trace_error --codegen Kremlin --include $KREMLIB"
FSTAR="fstar.exe --include $LOWLEVEL_LIB --include $CRYPTO_LIB $FSTAR_OPTIONS"

function compile_libs () {
  # The "kremlib", i.e. the glue code that realizes various functions modelized in F*
  $GCC -c $KREMLIB/kremlib.c
  # Some utilities to compare expected/actual outputs, etc.
  $GCC -c testlib.c
}

OBJS="kremlib.o testlib.o"

function color () {
  echo -e "\033[0;31m$1\033[0m"
}

count=0

function log_if () {
  if [ "$CI" != "" ]; then
    count=$(( $count + 1 ))
    echo "travis_fold:start:log$count"
    cat log
    echo "travis_fold:end:log$count"
  fi
}

function test () {
  local fstar_file=$1
  local c_main=$2
  local krml_options=$3
  local out=${fstar_file%fst}exe
  echo "Extracting [$krml_options] $fstar_file + $c_main => $out"
  $FSTAR $fstar_file > log 2>&1 || (cat log && exit 1)
  log_if

  ../Kremlin.native -write out.krml $krml_options
  if $HAS_CLANG; then
    $CLANG $OBJS $c_main -o $out
    ./$out
    color "$out/clang exited with $?"
  fi
  $GCC $OBJS $c_main -o $out
  ./$out
  color "$out/gcc exited with $?"
}

# Kremlib, testlib
compile_libs

# These files currently sitting in examples/low-level
test Crypto.Symmetric.Poly1305.fst main-Poly1305.c "-vla"
test Crypto.Symmetric.Chacha20.fst main-Chacha.c
test Crypto.AEAD.Chacha20Poly1305.fst main-Aead.c "-vla"

# Some unit-tests
TEST_ARGS="-no-prefix -add-include \"testlib.h\" -add-include \"kremlib.h\""
test Hoisting.fst Hoisting.c "$TEST_ARGS"
test Renaming.fst Renaming.c "$TEST_ARGS"
test Flat.fst Flat.c "$TEST_ARGS"