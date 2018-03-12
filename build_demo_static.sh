#!/bin/bash

DIR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
cd "$DIR_PATH";

./build_static.sh;

mkdir -p bin;

CPP_FILES="src/demo/*.cpp";
BUILD_FILES="$CPP_FILES";

LIBS="-framework Cocoa -framework Quartz -framework OpenGL -l cocoawindowing_s";
LIB_PATH="-L ./bin";
INCLUDE_PATH="-I ./include";

R_PATH="-rpath @loader_path/"

OUTPUT="-o bin/demo_static";

clang++ -arch x86_64 -std=c++14 -Wall -O3 $R_PATH $LIBS $LIB_PATH $INCLUDE_PATH $BUILD_FILES $OUTPUT;