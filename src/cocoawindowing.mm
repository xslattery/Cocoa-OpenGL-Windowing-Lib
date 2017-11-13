#import <Cocoa/Cocoa.h>
#import <string>
#import "cocoawindowing.h"

//////////////////////////////////////
// Translation Unit Global Variables:

// Application Related:
static std::string s_workingDirectory = "";
static bool s_applicationInited = false;

// Window & View Related:
static NSWindow *s_window = nullptr;
static NSOpenGLView *s_glView = nullptr;
static bool s_windowCreated = false;
static bool s_windowShouldClose = true;
static bool s_windowFullscreen = false;
static bool s_srgbEnabled = false;

// Input Related:
// NOTE(Xavier): (2017.11.13) These values will have to 
// be changed depending on what keys / buttons are supported.
// NOTE(Xavier): (2017.11.13) KEY_COUNT has been extended to 
// support arrow keys this is a hacky solution. (The last 4 have
// been configured for the 4 directions)
#define KEY_COUNT 132
#define MBTN_COUNT 3
#define MOD_KEY_COUNT 4
static bool s_activeKeys [KEY_COUNT];
static bool s_downKeys [KEY_COUNT];
static bool s_upKeys [KEY_COUNT];
static bool s_modifierActiveKeys [MOD_KEY_COUNT];
static bool s_activeMouseButtons [MBTN_COUNT];
static bool s_downMouseButtons [MBTN_COUNT];
static bool s_upMouseButtons [MBTN_COUNT];
static float s_mousePositionX = 0;
static float s_mousePositionY = 0;
static float s_mouseScrollValueY = 0;
static float s_mouseScrollValueX = 0;


//////////////////////////
// This is the class for 
// the application:
@interface AppDelegate : NSObject<NSApplicationDelegate> {}
@end

@implementation AppDelegate

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

- (void) applicationDidFinishLaunching: (NSNotification *)notification { [NSApp activateIgnoringOtherApps:YES]; }

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication*)sender { return YES; }

- (void) applicationWillTerminate: (NSApplication*)sender 
{ 	
	s_windowShouldClose = true;
	s_windowCreated = false;
	s_applicationInited = false;
}

@end


//////////////////////////
// This is the class for 
// the window:
@interface WindowDelegate : NSObject<NSWindowDelegate> {}
@end

@implementation WindowDelegate

// NOTE(Xavier): (2017.11.13) this can be used to set a min / max size or maintain an aspect ratio.
- (NSSize) windowWillResize: (NSWindow*)window toSize:(NSSize)frameSize { return frameSize; }

- (void) windowWillClose: (id)sender 
{ 	
	s_windowShouldClose = true;
	s_windowCreated = false;
}

@end


//////////////////////////////////////
// This is the class for the windows
// OpenGL subview:
@interface OpenGLView : NSOpenGLView {}
@end

@implementation OpenGLView

- (id) init 
{ 
	self = [super init]; 
	return self; 
}

- (void) prepareOpenGL 
{ 
	[super prepareOpenGL]; 
	[[self openGLContext] makeCurrentContext];
}

- (void) reshape { [super reshape]; }

- (void) drawRect: (NSRect)bounds 
{
	// NOTE(Xavier): (2017.11.13) This is for transparent windows:
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

		// TODO(Xavier): (2017.11.13) Remove this printf:
		printf( "Working directory: %s\n", s_workingDirectory.c_str() );

		// Assign the Application Delegate:
		[NSApp setDelegate:[[AppDelegate alloc] init]];
		[NSApp finishLaunching];
	}
	else
	{
		// TODO(Xavier): (2017.11.13) This should result in some better form of warning / static assert.
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
	
	// TODO(Xavier): (2017.11.13) Implement this...
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
			NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
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
		[pixelFormat release]; // TODO(Xavier): (2017.11.13) Should this be done?
		[s_glView setOpenGLContext:openglContext];
		// NOTE(Xavier): (2017.11.13) This can be set to a custom CGRect to make the view
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

		// Set this at the active context:
		[[s_glView openGLContext] makeCurrentContext];

		// This enables (1) / disables (0) vsync:
		// TODO(Xavier): (2017.11.13) There is currenely an issue with getting 
		// vsync to enable / disable correctly.
		// IF: I can get this to work, I will abstract it away into a toggleable function.
		int swapInterval = 1; 
		[[s_glView openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];

		// Default the background color to white:
		[s_window setBackgroundColor:[NSColor colorWithRed:1 green:1 blue:1 alpha:1]];
	}
	else
	{
		// TODO(Xavier): (2017.11.13) This should result in some better form of warning / static assert.
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

	[s_window close];

	// TODO(Xavier): (2017.11.13) More may be needed here...
	// To clean up after the window so 
	// that a new window can be created.

	// BUG(Xavier): (2017.11.13) There is currently a bug where, when the window
	// is closed and a new one is opened the programs memory
	// footpring only increases. It appears to be a leak.
	// I am currently not sure what is causing this.
	// The only work around I have is to maintain a single window
	// for the lifetime of the program.
}

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
					if ( c >= 'A' && c <= 'Z' ) c += 32; // NOTE(Xavier): (2017.11.13) Makes caps & non-caps the same
					if ( c == 25 ) c = Keys::KEY_TAB; // NOTE(Xavier): (2017.11.13) Fixes tab when shift is pressed.
					if ( !s_activeKeys[c] ) s_downKeys[c] = true;
					s_activeKeys[c] = true;
				}

				// NOTE(Xavier): (2017.11.13) This is a hacky solution to allow for arrow keys:
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
					if ( c >= 'A' && c <= 'Z' ) c += 32; // NOTE(Xavier): (2017.11.13) Makes caps & non-caps the same
					if ( c == 25 ) c = Keys::KEY_TAB; // NOTE(Xavier): (2017.11.13) Fixes tab when shift is pressed.
					s_activeKeys[c] = false;
					s_upKeys[c] = true;
				}

				// NOTE(Xavier): (2017.11.13) This is a hacky solution to allow for arrow keys:
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
				s_mouseScrollValueY = static_cast<float>([event scrollingDeltaY]);
				s_mouseScrollValueX = static_cast<float>([event scrollingDeltaX]);

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
// NOTE(Xavier): (2017.11.13) App switching will not work while in fullscreen.
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
// NOTE(Xavier): (2017.11.13) This is the prefered method to set_window_complete_fullscreen()
extern "C" void set_window_fullscreen ( bool state )
{
	if ( state && !s_windowFullscreen ) { [s_window toggleFullScreen:nil]; s_windowFullscreen = true; }
	else if ( !state && s_windowFullscreen ) { [s_window toggleFullScreen:nil]; s_windowFullscreen = false; }
}

/////////////////////////////////////
// This sets the size of the window:
extern "C" void set_window_size ( float width, float height )
{
	if ( !s_windowFullscreen )
	{
		// NOTE(Xavier): (2017.11.13) The title bar had to be taken into account.
		// For some reason, this it different to when the window is first created.
		float titleBarHeight = [s_window frame].size.height - [[s_window contentView] frame].size.height;
		NSRect frame = [s_window frame];
		frame.origin.x = ([[NSScreen mainScreen] frame].size.width - width)/2;
		frame.origin.y = ([[NSScreen mainScreen] frame].size.height - height)/2;
		frame.size.width = width;
		frame.size.height = height + titleBarHeight;
		[s_window setFrame:frame display:YES animate:YES];
	}
}

///////////////////////////////////
extern "C" void set_window_position ( float x, float y )
{
	if ( !s_windowFullscreen )
	{
		NSRect frame = [s_window frame];
		frame.origin.x = x;
		frame.origin.y = y;
		[s_window setFrame:frame display:YES animate:YES];
	}
}

////////////////////////////////////////////////////////////
// NOTE(Xavier): (2017.11.13) This should be called before 
// 'set_window_background_color' or it will not be applied to the background.
extern "C" void set_window_background_enable_srgb ( bool state )
{
	s_srgbEnabled = state;
}

////////////////////////////////////////////////////////////
// This function sets the background color of the widow:
// This is imporant when the titlebar is hidden, because it
// will be the color that displays in place of the titlebar texture.
// NOTE(Xavier): (2017.11.13) If srgb colors are wanted it needs to be
// enabled before this function is called.
extern "C" void set_window_background_color ( float r, float g, float b, float a )
{
	auto to_srgb = []( float v ) -> float
	{
		if ( v <= 0.0031308 ) return v * 12.92;
		else return 1.055 * pow(v, 1.0/2.4) - 0.055;
	};

	if ( s_srgbEnabled ) [s_window setBackgroundColor:[NSColor colorWithRed:to_srgb(r) green:to_srgb(g) blue:to_srgb(b) alpha:a]];
	else [s_window setBackgroundColor:[NSColor colorWithRed:r green:g blue:b alpha:a]];
}

///////////////////////////////////
// Hides the title bar:
extern "C" void set_window_title_bar_hidden ( bool state )
{
	if ( state ) s_window.titlebarAppearsTransparent = true;
}

///////////////////////////////////
// Hides title bar text:
extern "C" void set_window_title_hidden ( bool state )
{
	if ( state ) s_window.titleVisibility = NSWindowTitleHidden;
}

//////////////////////////////////////////////////
// Enables transparency for the view and window:
extern "C" void set_window_transparency ( bool state )
{
	int transparent = !state;
    [[s_glView openGLContext] setValues:&transparent forParameter:NSOpenGLCPSurfaceOpacity];
	[s_window setOpaque:(state == true ? NO : YES)];
}


///////////////////////////////////
extern "C" bool get_key ( size_t keyCode )
{
	if ( keyCode < KEY_COUNT )
	{
		if ( keyCode >= 65 && keyCode <= 90 ) keyCode += 32; // NOTE(Xavier): (2017.11.13) Makes caps & non-caps the same
		if ( keyCode >= Keys::KEY_UP && keyCode <= Keys::KEY_RIGHT ) keyCode -= 63104; // NOTE(Xavier): (2017.11.13) Hacky fix for arrow keys.
		return s_activeKeys[keyCode];
	}
	return false;
}

///////////////////////////////////
extern "C" bool get_key_down ( size_t keyCode )
{
	if ( keyCode < KEY_COUNT )
	{
		if ( keyCode >= 65 && keyCode <= 90 ) keyCode += 32; // NOTE(Xavier): (2017.11.13) Makes caps & non-caps the same
		if ( keyCode >= Keys::KEY_UP && keyCode <= Keys::KEY_RIGHT ) keyCode -= 63104; // NOTE(Xavier): (2017.11.13) Hacky fix for arrow keys.
		return s_downKeys[keyCode];
	}
	return false;
}

///////////////////////////////////
extern "C" bool get_key_up ( size_t keyCode )
{
	if ( keyCode < KEY_COUNT )
	{
		if ( keyCode >= 65 && keyCode <= 90 ) keyCode += 32; // NOTE(Xavier): (2017.11.13) Makes caps & non-caps the same
		if ( keyCode >= Keys::KEY_UP && keyCode <= Keys::KEY_RIGHT ) keyCode -= 63104; // NOTE(Xavier): (2017.11.13) Hacky fix for arrow keys.
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

///////////////////////////////////
extern "C" float get_mouse_scroll_y ()
{
	return s_mouseScrollValueY;
}

///////////////////////////////////
extern "C" float get_mouse_scroll_x ()
{
	return s_mouseScrollValueX;
}

///////////////////////////////////
extern "C" bool get_window_is_closing ()
{
	return s_windowShouldClose;
}

///////////////////////////////////
extern "C" float get_window_width ()
{
	return static_cast<float>( [s_glView frame].size.width );
}

///////////////////////////////////
extern "C" float get_window_height ()
{
	return static_cast<float>( [s_glView frame].size.height );
}

///////////////////////////////////
extern "C" float get_window_hidpi_width ()
{
	return static_cast<float>( [s_glView convertRectToBacking:[s_glView bounds]].size.width );
}

///////////////////////////////////
extern "C" float get_window_hidpi_height ()
{
	return static_cast<float>( [s_glView convertRectToBacking:[s_glView bounds]].size.height );
}

///////////////////////////////////
extern "C" float get_screen_width ()
{
	return static_cast<float>( [[NSScreen mainScreen] frame].size.width );
}

///////////////////////////////////
extern "C" float get_screen_height ()
{
	return static_cast<float>( [[NSScreen mainScreen] frame].size.height );
}


//////////////////////////////////////////////////
// NOTE(Xavier): (2017.11.13) This function will 
// return a nullptr if there are any errors.
// IF: The program is not in an app bundle, the passed
// name will be used.
extern "C" const char* get_application_support_directory ( const char *appName )
{	
	NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
	if ( bundleID == nil && appName == nullptr ) return nullptr;
	else bundleID = [NSString stringWithUTF8String:appName];

	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *dirPath = nil;
	NSArray *appSupportDir = [fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
	if ( [appSupportDir count] > 0 )
	{
		dirPath = [[appSupportDir objectAtIndex:0] URLByAppendingPathComponent:bundleID];
		NSError *theError = nil;
		if ( ![fm createDirectoryAtURL:dirPath withIntermediateDirectories:YES attributes:nil error:&theError] )
		{
			return nullptr;
		}
	}

	// NOTE(Xavier): (2017.11.13) There may be a memory leak here:
	return (const char*)[[dirPath.path stringByAppendingString:@"/"] UTF8String];
}

///////////////////////////////////
extern "C" void create_directory_at ( const char* dir )
{
	NSString *directory = [NSString stringWithUTF8String:dir];
	NSError	*error = nil;
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:NO attributes:nil error:&error];
}

///////////////////////////////////
extern "C" void remove_file_at ( const char* filename )
{
	NSString *fileRemoval = [NSString stringWithUTF8String:filename];
	[[NSFileManager defaultManager] removeItemAtPath:fileRemoval error:NULL];
}