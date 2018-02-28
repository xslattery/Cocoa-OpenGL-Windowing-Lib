#!/bin/bash

DIR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
cd "$DIR_PATH";

./build_dynamic.sh;

mkdir -p build;

CPP_FILES="src/demo/*.cpp";
BUILD_FILES="$CPP_FILES";

LIBS="-framework OpenGL -l cocoawindowing";
LIB_PATH="-L ./build";
INCLUDE_PATH="-I ./include";

R_PATH="-rpath @loader_path/"

OUTPUT="build/demo_dynamic";

clang++ -Wall -O3 -arch x86_64 -std=c++14 $R_PATH $LIBS $LIB_PATH $INCLUDE_PATH $BUILD_FILES -o $OUTPUT;