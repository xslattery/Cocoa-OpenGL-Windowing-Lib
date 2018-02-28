#!/bin/bash

DIR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
cd "$DIR_PATH";

mkdir -p build;

OBJCPP_FILES="src/*.mm";
BUILD_FILES="$OBJCPP_FILES";

INCLUDE_PATH="-I ./include";

BUILD_OUTPUT_FILES="*.o"
OUTPUT="build/libcocoawindowing.a";

clang++ -Wall -O3 -arch x86_64 -std="c++14" $INCLUDE_PATH -c $BUILD_FILES;
libtool -static $BUILD_OUTPUT_FILES -o $OUTPUT;

rm $BUILD_OUTPUT_FILES;