#import <Cocoa/Cocoa.h>
#include "cocoawindowing.h"

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
	id menubar = [ [ NSMenu new ] autorelease ];
	id appMenuItem = [ [ NSMenuItem new ] autorelease ];
	[ menubar addItem:appMenuItem ];
	[ NSApp setMainMenu:menubar ];
	id appMenu = [ [ NSMenu new ] autorelease ];
	id appName = [ [ NSProcessInfo processInfo ] processName ];
	id quitTitle = [ @"Quit " stringByAppendingString:appName ];
	id quitMenuItem = [ [ [ NSMenuItem alloc ] initWithTitle:quitTitle action:@selector(terminate:) keyEquivalent:@"q" ] autorelease ];
	[ appMenu addItem:quitMenuItem ];
	[ appMenuItem setSubmenu:appMenu ];

	[ NSApp setActivationPolicy:NSApplicationActivationPolicyRegular ];
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

@end


///////////////////////////////////////
// This function sets up the NSApp so
// a NSWindow can be created:
void init_application()
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
void close_application ()
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
void create_window ( const char *title, int width, int height )
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
void close_window ()
{
	s_windowShouldClose = true;
	s_windowCreated = false;
	
	// TODO: More may be needed here...
	// To clean up after the window so 
	// that a new window can be created.
}

///////////////////////////////////////
// This function will process all
// input / events and store them to
// be accessed by other functions:
void process_window_events ()
{
	NSEvent* Event;
	do {
		Event = [NSApp nextEventMatchingMask:NSEventMaskAny untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES];
		
		switch ( [Event type] ) {
			
			case NSEventTypeKeyDown: 
			{ 
				[NSApp sendEvent:Event]; 
			} break;
			
			case NSEventTypeKeyUp: 
			{ 
				[NSApp sendEvent:Event]; 
			} break;
			
			case NSEventTypeScrollWheel: 
			{ 
				[NSApp sendEvent:Event];
			} break;
			
			default: { [NSApp sendEvent:Event]; } break;
		}

	} while ( Event != nil );

	// Mouse Position + in view + pressed button mask:
	CGPoint mouseLocationOnScreen = [NSEvent mouseLocation];
	NSRect windowRect = [s_window convertRectFromScreen:NSMakeRect( mouseLocationOnScreen.x, mouseLocationOnScreen.y, 1, 1 )];
	NSPoint pointInWindow = windowRect.origin;
	
	NSPoint mouseLocationInView = [s_glView convertPoint:pointInWindow fromView:nil];
	
	bool mouseInWindowFlag = NSPointInRect( mouseLocationOnScreen, [s_window frame] );

	unsigned int mouseButtonMask = [NSEvent pressedMouseButtons];
}

/////////////////////////////////////
// This function will display the
// OpenGL draw calls to the window:
void refresh_window () 
{ 
	[[s_glView openGLContext] flushBuffer]; 
}

/////////////////////////////////
// This function returns if the 
// window wants to close:
bool window_is_closing ()
{
	return s_windowShouldClose;
}

////////////////////////////////////////
// This function can be used
// to set the visibility of the cursor
void hide_cursor ( bool state )
{	
	if ( state ) [NSCursor hide];
	else [NSCursor unhide];
}






