# Cocoa-OpenGLWindowing

![alt text](other/CocoaWindowImage_Transparent.png "Transparent Cocoa Window Image")

### About:
The purpose of this project is to create a template, which can be used for creating macos / osx OpenGL windows using the native Cocoa API. The primary goal for this project is for it to be usable in C++ projects.

### Dependencies:
As this project uses Apples API's it is macos / osx dependent.
The libraries / frameworks it requires are:

 - Cocoa framework
 - OpenGL framework

All the above libraries / frameworks can be found on all modern macos / osx installs.

### Build Process:
This project includes multiple **bash build scripts** that when run will build the project into a usable static or dynamic library.
In addition this project includes a demo build script that will create an executable demo that showcases the project.
The Compiler user by the build scripts is *Clang*, in addition *libtool* is used for creating the dynamic and static libraries. All these can be found if *Xcode's Command Line Tools* are installed.

- **./build_static**, will generate a static library. *Dependencies* will require linking when using this form of the library.
- **./build_dynamic**,  will generate a dynamic library.
- **./build_demo**, will create an demo executable.
- Build products can be found inside the builds directory.