#import <Cocoa/Cocoa.h>
#import <string>
#import "cocoawindowing.h"

//////////////////////////////////////
// Translation Unit Local Variables:

// Application Related:
static std::string s_workingDirectory = "";
static bool s_applicationInited = false;

// Window Related:
static NSWindow *s_window = nullptr;
static NSOpenGLView *s_glView = nullptr;
static bool s_windowCreated = false;
static bool s_windowShouldClose = true;
static bool s_windowFullscreen = false;


//////////////////////
// Helper Functions:
static float to_srgb ( float v )
{
	if ( v <= 0.0031308 ) return v * 12.92;
	else return 1.055 * pow(v, 1.0/2.4) - 0.055;
}


//////////////////////////
// This is the class for 
// the application:
@interface AppDelegate : NSObject<NSApplicationDelegate> {}
@end

@implementation AppDelegate

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication*)sender 
{ 
	return YES; 
}

- (void) applicationWillTerminate: (NSApplication*)sender 
{ 	
	s_windowShouldClose = true;
	s_windowCreated = false;
	s_applicationInited = false;
}

- (void) applicationWillFinishLaunching: (NSNotification *)aNotification 
{
	id menubar = [[NSMenu new] autorelease];
	id appMenuItem = [ [ NSMenuItem new ] autorelease];
	[menubar addItem:appMenuItem];
	[NSApp setMainMenu:menubar];
	id appMenu = [[NSMenu new ] autorelease];
	id appName = [[NSProcessInfo processInfo] processName];
	id quitTitle = [@"Quit " stringByAppendingString:appName];
	id quitMenuItem = [[[NSMenuItem alloc] initWithTitle:quitTitle action:@selector(terminate:) keyEquivalent:@"q"] autorelease];
	[appMenu addItem:quitMenuItem];
	[appMenuItem setSubmenu:appMenu];

	[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
}

- (void) applicationDidFinishLaunching: (NSNotification *)notification 
{
	[NSApp activateIgnoringOtherApps:YES];
}

@end


//////////////////////////////
// This is the class for the
// window:
@interface WindowDelegate : NSObject<NSWindowDelegate> {}
@end

@implementation WindowDelegate

- (void) windowWillClose: (id)sender 
{ 	
	s_windowShouldClose = true;
	s_windowCreated = false;
}

- (NSSize) windowWillResize: (NSWindow*)window toSize:(NSSize)frameSize 
{ 
	return frameSize; 
}

@end


//////////////////////////////////////
// This is the class for the windows
// OpenGL subview:
@interface OpenGLView : NSOpenGLView {}
@end

@implementation OpenGLView

- (id) init { 
	self = [super init]; 
	return self; 
}

- (void) prepareOpenGL 
{ 
	[super prepareOpenGL]; 
	[[self openGLContext] makeCurrentContext];
}

- (void) reshape 
{ 
	[super reshape];

	// NOTE: this can be used to set a min size
	// or maintain an aspect ratio.

	// NSRect viewBounds = [self frame];
	// [self setFrame:viewBounds];
}

- (void) drawRect: (NSRect)bounds 
{
	[[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0] set];
    NSRectFill( bounds );
}

// These exist to prevent keys from beeping:
- (BOOL) acceptsFirstResponder { return YES; }
- (void) keyDown: (NSEvent *)theEvent {}

@end


///////////////////////////////////////
// This function sets up the NSApp so
// a NSWindow can be created:
extern "C" void init_application()
{
	if ( !s_applicationInited )
	{
		s_applicationInited = true;
		
		// Initialize the application:
		[NSApplication sharedApplication];

		// Set the current working directory:
		// If using an app bundle, set it to the resources folder.
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *workingDirectory = [[NSFileManager defaultManager] currentDirectoryPath];
		
		NSString *appBundlePath = [NSString stringWithFormat:@"%@/Contents/Resources", [[NSBundle mainBundle] bundlePath]];
		if ( [fileManager changeCurrentDirectoryPath:appBundlePath] == YES ) 
			workingDirectory = appBundlePath;
		
		s_workingDirectory = std::string( (char*)[ workingDirectory UTF8String ] );

		// TODO: Remove this printf:
		printf( "Working directory: %s\n", s_workingDirectory.c_str() );

		// Assign the Application Delegate:
		[NSApp setDelegate:[[AppDelegate alloc] init]];
		[NSApp finishLaunching];
	}
	else
	{
		// TODO: This should result in some better form of warning / static assert.
		printf( "The application has already been initalised.\n" );
	}
}

/////////////////////////////////////////
// This function will close the 
// application and all related windows:
extern "C" void close_application ()
{
	close_window();
	s_applicationInited = false;
	
	// TODO: Implement this...
	// More is needed to clean up
	// so that the application can be re-inited.
}

////////////////////////////////
// This function will create a 
// OpenGL capable window:
extern "C" void create_window ( const char *title, int width, int height )
{
	if ( !s_windowCreated )
	{
		s_windowCreated = true;
		s_windowShouldClose = false;

		// Create the main window and the content view:
		float windowWidth = (float)width;
		float windowHeight = (float)height;
		NSRect screenRect = [[NSScreen mainScreen] frame];
		NSRect windowFrame = NSMakeRect(( screenRect.size.width - windowWidth ) * 0.5f, 
										( screenRect.size.height - windowHeight ) * 0.5f, 
										windowWidth, windowHeight);
		
		NSWindowStyleMask windowStyleMask = NSWindowStyleMaskClosable | 
											NSWindowStyleMaskTitled |
											NSWindowStyleMaskMiniaturizable |
											// NSWindowStyleMaskFullSizeContentView | // For some reason this affects VSync??
											NSWindowStyleMaskResizable;

		s_window = [[NSWindow alloc] initWithContentRect:windowFrame styleMask:windowStyleMask backing:NSBackingStoreBuffered defer:NO];

		[s_window setDelegate:[[WindowDelegate alloc] init]];
		[s_window setTitle:[NSString stringWithUTF8String:title]];
		[s_window makeKeyAndOrderFront:nil];

		// This array defines what we want our pixel format to be like:
		NSOpenGLPixelFormatAttribute openGLAttributes [] = 
		{
			// NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core, NOTE: Tempoary switch to legacy OpenGL.
			NSOpenGLPFAAccelerated,
			NSOpenGLPFADoubleBuffer,
			NSOpenGLPFAColorSize, 24,
			NSOpenGLPFAAlphaSize, 8,
			NSOpenGLPFADepthSize, 24,
			0
		};

		// Create a pixel format & gl context based off our chosen attributes:
		NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:openGLAttributes];
		NSOpenGLContext *openglContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];

		// Set some properties for the windows main view:
		[[s_window contentView] setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[[s_window contentView] setAutoresizesSubviews:YES];

		// Create an OpenGL View: 
		s_glView = [[OpenGLView alloc] init];
		[s_glView setPixelFormat:pixelFormat];
		[pixelFormat release]; // TODO: Should this be done?
		[s_glView setOpenGLContext:openglContext];
		// NOTE: This can be set to a custom CGRect to make the view
		// only take up a portion or the window.
		[s_glView setFrame:[[s_window contentView] bounds]];
		[s_glView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[s_glView setWantsBestResolutionOpenGLSurface:YES];
		[[s_glView openGLContext] setView:s_glView];
		// Subview it to the windows main view:
		[[s_window contentView] addSubview:s_glView];
		
		// This is done to prevent keys from beeping:
		[s_window setInitialFirstResponder:(NSView *)s_glView]; 
		[s_window makeFirstResponder:(NSView *)s_glView];

		// This enables (1) / disables (0) vsync:
		// TODO: There is currenely an issue with getting 
		// vsync to enable / disable correctly.
		int swapInterval = 1; 
		[[s_glView openGLContext] makeCurrentContext];
		[[s_glView openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];

		// Hide the title bar texture & title:
		s_window.titlebarAppearsTransparent = true;
		s_window.titleVisibility = NSWindowTitleHidden;
		// Set the window's background color, this will be shown in the title bar:
		[s_window setBackgroundColor:[NSColor colorWithRed:to_srgb(0.5) green:to_srgb(0.5) blue:to_srgb(0.5) alpha:1]];

		// This enables transparency to the opengl view and window:
		int transparent = 0;
	    [[s_glView openGLContext] setValues:&transparent forParameter:NSOpenGLCPSurfaceOpacity];
    	[s_window setOpaque:NO];
	}
	else
	{
		// TODO: This should result in some better form of warning / static assert.
		printf( "A window has already been created.\n" );
	}
}

/////////////////////////////////
// This function will close the
// active window:
extern "C" void close_window ()
{
	s_windowShouldClose = true;
	s_windowCreated = false;
	
	// TODO: More may be needed here...
	// To clean up after the window so 
	// that a new window can be created.
}

#define KEY_COUNT 132		// NOTE: These values will have to be changed
#define MBTN_COUNT 3		// depending on what keys / buttons are supported.
#define MOD_KEY_COUNT 4			// NOTE: KEY_COUNT has been extended to support arrow keys this is a hacky solution.
static bool s_activeKeys [KEY_COUNT];
static bool s_downKeys [KEY_COUNT];
static bool s_upKeys [KEY_COUNT];
static bool s_modifierActiveKeys [MOD_KEY_COUNT];
static bool s_activeMouseButtons [MBTN_COUNT];
static bool s_downMouseButtons [MBTN_COUNT];
static bool s_upMouseButtons [MBTN_COUNT];
static float s_mousePositionX = 0;
static float s_mousePositionY = 0;

///////////////////////////////////////
// This function will process all
// input / events and store them to
// be accessed by other functions:
extern "C" void process_window_events ()
{
	for ( size_t k = 0; k < KEY_COUNT; ++k )
	{
		s_downKeys[k] = false;
		s_upKeys[k] = false;
	}

	for ( size_t b = 0; b < MBTN_COUNT; ++b )
	{
		s_downMouseButtons[b] = false;
		s_upMouseButtons[b] = false;
	}

	for ( size_t m = 0; m < MOD_KEY_COUNT; ++m )
	{
		s_modifierActiveKeys[m] = false;
	}

	NSEvent* event;
	do {
		event = [NSApp nextEventMatchingMask:NSEventMaskAny untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES];
		
		switch ( [event type] ) {
			
			case NSEventTypeKeyDown: 
			{
				size_t modifierFlags = [event modifierFlags];
				size_t commandKeyFlag = modifierFlags & NSEventModifierFlagCommand;
				size_t controlKeyFlag = modifierFlags & NSEventModifierFlagControl;
				size_t optionKeyFlag = modifierFlags & NSEventModifierFlagOption;
				size_t shiftKeyFlag = modifierFlags & NSEventModifierFlagShift;
				if ( commandKeyFlag ) s_modifierActiveKeys[ModifierKeys::COMMAND] = true;
				if ( controlKeyFlag ) s_modifierActiveKeys[ModifierKeys::OPTION] = true;
				if ( optionKeyFlag ) s_modifierActiveKeys[ModifierKeys::CONTROL] = true;
				if ( shiftKeyFlag ) s_modifierActiveKeys[ModifierKeys::SHIFT] = true;

				size_t c = [[event charactersIgnoringModifiers] characterAtIndex:0];
				if ( c < KEY_COUNT )
				{
					if ( c >= 'A' && c <= 'Z' ) c += 32; // NOTE: Makes caps & non-caps the same
					if ( c == 25 ) c = Keys::KEY_TAB; // NOTE: Fixes tab when shift is pressed.
					if ( !s_activeKeys[c] ) s_downKeys[c] = true;
					s_activeKeys[c] = true;
				}

				// NOTE: This is a hacky solution to allow for arrow keys:
				if ( c >= Keys::KEY_UP && c <= Keys::KEY_RIGHT )
				{
					c -= 63104;
					if ( !s_activeKeys[c] ) s_downKeys[c] = true;
					s_activeKeys[c] = true;
				}

				[NSApp sendEvent:event]; 
			} break;
			
			case NSEventTypeKeyUp: 
			{	
				int modifierFlags = [event modifierFlags];
				int commandKeyFlag = modifierFlags & NSEventModifierFlagCommand;
				int controlKeyFlag = modifierFlags & NSEventModifierFlagControl;
				int optionKeyFlag = modifierFlags & NSEventModifierFlagOption;
				int shiftKeyFlag = modifierFlags & NSEventModifierFlagShift;
				if ( commandKeyFlag ) s_modifierActiveKeys[ModifierKeys::COMMAND] = false;
				if ( controlKeyFlag ) s_modifierActiveKeys[ModifierKeys::OPTION] = false;
				if ( optionKeyFlag ) s_modifierActiveKeys[ModifierKeys::CONTROL] = false;
				if ( shiftKeyFlag ) s_modifierActiveKeys[ModifierKeys::SHIFT] = false;				

				size_t c = [[event charactersIgnoringModifiers] characterAtIndex:0];
				if ( c < KEY_COUNT )
				{
					if ( c >= 'A' && c <= 'Z' ) c += 32; // NOTE:Makes caps & non-caps the same
					if ( c == 25 ) c = Keys::KEY_TAB; // NOTE: Fixes tab when shift is pressed.
					s_activeKeys[c] = false;
					s_upKeys[c] = true;
				}

				// NOTE: This is a hacky solution to allow for arrow keys:
				if ( c >= Keys::KEY_UP && c <= Keys::KEY_RIGHT )
				{
					c -= 63104;
					s_activeKeys[c] = false;
					s_upKeys[c] = true;
				}

				[NSApp sendEvent:event];
			} break;
			
			case NSEventTypeScrollWheel: 
			{
				[NSApp sendEvent:event];
			} break;
			
			default: { [NSApp sendEvent:event]; } break;
		}

	} while ( event != nil );

	// Mouse Position:
	NSPoint mouseLocationOnScreen = [NSEvent mouseLocation];
	NSRect windowRect = [s_window convertRectFromScreen:NSMakeRect( mouseLocationOnScreen.x, mouseLocationOnScreen.y, 1, 1 )];
	NSPoint pointInWindow = windowRect.origin;	
	NSPoint mouseLocationInView = [s_glView convertPoint:pointInWindow fromView:nil];
	s_mousePositionX = static_cast<float>( mouseLocationInView.x );
	s_mousePositionY = static_cast<float>( [s_glView frame].size.height - mouseLocationInView.y );
	
	// Mouse Buttons:
	size_t mouseButtonMask = [NSEvent pressedMouseButtons];
	for ( size_t m = 0; m < MBTN_COUNT; ++m )
	{
		if ( mouseButtonMask & (1 << m) )
		{
			if ( !s_activeMouseButtons[m] ) s_downMouseButtons[m] = true;
			s_activeMouseButtons[m] = true;
		}
		else if ( !(mouseButtonMask & (1 << m) ) && s_activeMouseButtons[m] )
		{
			s_activeMouseButtons[m] = false;
			s_upMouseButtons[m] = true;
		}
	}
}

/////////////////////////////////////
// This function will display the
// OpenGL draw calls to the window:
extern "C" void refresh_window () 
{ 
	[[s_glView openGLContext] flushBuffer]; 
}


////////////////////////////////////////
// This function can be used
// to set the visibility of the cursor:
extern "C" void set_cursor_hidden ( bool state )
{	
	if ( state ) [NSCursor hide];
	else [NSCursor unhide];
}

///////////////////////////////////////////////////////////////////////////
// This function will make the OpenGLView enter complete fullscreen
// by making the NSView the full screen size & on top of everything else.
// NOTE: App switching will not work while in fullscreen.
// Because of this, set_window_fullscreen() is recomended instead.
extern "C" void set_window_complete_fullscreen ( bool state )
{
	if ( state && !s_glView.inFullScreenMode )
	{
		if ( !s_glView.inFullScreenMode )
			[s_glView enterFullScreenMode:[NSScreen mainScreen] withOptions:nil];
	}
	else if ( !state && s_glView.inFullScreenMode )
	{
		[s_glView exitFullScreenModeWithOptions:nil];
		[s_window makeKeyAndOrderFront:nil];

		// This is done to prevent keys from beeping:
		[s_window setInitialFirstResponder:(NSView *)s_glView]; 
		[s_window makeFirstResponder:(NSView *)s_glView];
	}
}

/////////////////////////////////////////////////////////////
// This function will move the window
// into a new fullscreen space or exit from one.
// NOTE: This is the prefered method to set_window_complete_fullscreen()
extern "C" void set_window_fullscreen ( bool state )
{
	if ( state && !s_windowFullscreen ) { [s_window toggleFullScreen:nil]; s_windowFullscreen = true; }
	else if ( !state && s_windowFullscreen ) { [s_window toggleFullScreen:nil]; s_windowFullscreen = false; }
}


/////////////////////////////////
// This function returns if the 
// window wants to close:
extern "C" bool get_window_is_closing ()
{
	return s_windowShouldClose;
}

///////////////////////////////////
extern "C" bool get_key ( size_t keyCode )
{
	if ( keyCode < KEY_COUNT )
	{
		if ( keyCode >= 65 && keyCode <= 90 ) keyCode += 32; // NOTE: Makes caps & non-caps the same
		if ( keyCode >= Keys::KEY_UP && keyCode <= Keys::KEY_RIGHT ) keyCode -= 63104; // NOTE: Hacky fix for arrow keys.
		return s_activeKeys[keyCode];
	}
	return false;
}

///////////////////////////////////
extern "C" bool get_key_down ( size_t keyCode )
{
	if ( keyCode < KEY_COUNT )
	{
		if ( keyCode >= 65 && keyCode <= 90 ) keyCode += 32; // NOTE: Makes caps & non-caps the same
		if ( keyCode >= Keys::KEY_UP && keyCode <= Keys::KEY_RIGHT ) keyCode -= 63104; // NOTE: Hacky fix for arrow keys.
		return s_downKeys[keyCode];
	}
	return false;
}

///////////////////////////////////
extern "C" bool get_key_up ( size_t keyCode )
{
	if ( keyCode < KEY_COUNT )
	{
		if ( keyCode >= 65 && keyCode <= 90 ) keyCode += 32; // NOTE: Makes caps & non-caps the same
		if ( keyCode >= Keys::KEY_UP && keyCode <= Keys::KEY_RIGHT ) keyCode -= 63104; // NOTE: Hacky fix for arrow keys.
		return s_upKeys[keyCode];
	}
	return false;
}

///////////////////////////////////
extern "C" bool get_modifier_key ( size_t keyCode )
{
	if ( keyCode < MOD_KEY_COUNT )
	{
		return s_modifierActiveKeys[keyCode];
	}
	return false;
}

///////////////////////////////////
extern "C" bool get_mouse_button ( size_t button )
{
	if ( button < MBTN_COUNT )
	{
		return s_activeMouseButtons[button];
	}
	return false;
}

///////////////////////////////////
extern "C" bool get_mouse_button_down ( size_t button )
{
	if ( button < MBTN_COUNT )
	{
		return s_downMouseButtons[button];
	}
	return false;
}

///////////////////////////////////
extern "C" bool get_mouse_button_up ( size_t button )
{
	if ( button < MBTN_COUNT )
	{
		return s_upMouseButtons[button];
	}
	return false;
}

///////////////////////////////////
extern "C" float get_mouse_position_x ()
{
	return s_mousePositionX;
}

///////////////////////////////////
extern "C" float get_mouse_position_y ()
{
	return s_mousePositionY;
}
