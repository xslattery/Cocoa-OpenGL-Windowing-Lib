#!/bin/bash

DIR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
cd "$DIR_PATH";

mkdir -p build;

OBJCPP_FILES="src/*.mm";
BUILD_FILES="$OBJCPP_FILES";

LIBS="-framework Cocoa";
INCLUDE_PATH="-I ./include";

OUTPUT="build/libcocoawindowing.dylib";
INST_NAME="-install_name @rpath/libcocoawindowing.dylib";

clang++ -Wall -O3 $INST_NAME -dynamiclib -arch x86_64 -std="c++14" $INCLUDE_PATH $LIBS $BUILD_FILES -o $OUTPUT -compatibility_version 1.0.0 -current_version 1.0.0;