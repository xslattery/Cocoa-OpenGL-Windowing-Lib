#!/bin/bash

DIR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
cd "$DIR_PATH";

mkdir -p bin;

BUILD_FILES="src/*.mm";

LIBS="-framework Cocoa -framework Quartz -framework OpenGL";
INCLUDE_PATH="-I ./include";

OUTPUT="-o bin/libcocoawindowing_d.dylib";
INST_NAME="-install_name @rpath/libcocoawindowing_d.dylib";
VERSIONS="-compatibility_version 1.0.0 -current_version 1.0.0";

clang++ -arch x86_64 -std=c++14 -Wall -O3 -dynamiclib $INST_NAME $INCLUDE_PATH $LIBS $BUILD_FILES $OUTPUT $VERSIONS;