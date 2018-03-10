#!/bin/bash

DIR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
cd "$DIR_PATH";

mkdir -p bin;

BUILD_FILES="src/*.mm";
INCLUDE_PATH="-I ./include";
OUTPUT="bin/libcocoawindowing_s.a";

clang++ -arch x86_64 -std=c++14 -Wall -O3 $INCLUDE_PATH -c $BUILD_FILES;

BUILD_OUTPUT_FILES="*.o"

libtool -static $BUILD_OUTPUT_FILES -o $OUTPUT;

rm $BUILD_OUTPUT_FILES;