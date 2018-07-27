# Cpp-Cocoa-OpenGL-Windowing-Lib

## About:
This project exists as a simple library for small C++ programs wanting a quick way to get a cocoa opengl window up and running.

<p aligh="center">
	<img src="other/CocoaWindowImageDouble.png" alt="Cocoa Window Image" height="219px" style="height: 219px;"/>
</p>

## Dependencies:
This project uses Apples API's so it is MacOSX dependent. The libraries / frameworks it requires are:

 - Cocoa framework
 - Quartz framework
 - OpenGL framework

## Build:
This project includes multiple **```shell scripts```** that when run will build the project into a usable static or dynamic library.
In addition, this project includes a demo build scripts that will create an executable demo to showcases the project.

The Compiler user by the build scripts is **```clang```**, in addition **```libtool```** is used for creating the static library. All these can be found if **```Xcode's Command Line Tools```** are installed.

The Build products can be found inside the builds directory.

- **```./build_static```**, will generate a static library. *Dependencies* will require linking when using this form of the library.
- **```./build_dynamic```**,  will generate a dynamic library.

- **```./build_demo_dynamic```**, will create an demo executable using the static library.
- **```./build_demo_dynamic```**, will create an demo executable using the dynamic library.

## Run:
Both demo exectuables can be run by double clicking them in finder or in terminal:

- **```./bin/demo_dynamic```**
- **```./bin/demo_static```**