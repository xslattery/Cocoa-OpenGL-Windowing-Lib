#import <Cocoa/Cocoa.h>
#include "cocoawindowing.h"


static std::string 	s_workingDirectory = "";

static NSWindow * 	s_window = nullptr;
static NSOpenGLView * s_glView = nullptr;
static bool 		s_windowCreated = false;
static bool 		s_window_should_close = true;


@interface AppDelegate : NSObject<NSApplicationDelegate> {}
@end


@interface WindowDelegate : NSObject<NSWindowDelegate> {}
@end


@interface OpenGLView : NSOpenGLView {}
@end


@implementation AppDelegate

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication*)sender 
{ 
	return YES; 
}

- (void) applicationWillTerminate: (NSApplication*)sender 
{ 
	printf("Application Terminating.\n");
	s_window_should_close = true;
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


@implementation WindowDelegate

- (void) windowWillClose: (id)sender 
{ 
	printf("Window closing.\n");
	s_window_should_close = true;
}

- (NSSize) windowWillResize: (NSWindow*)window toSize:(NSSize)frameSize 
{ 
	return frameSize; 
}

@end


@implementation OpenGLView

- (id) init { self = [super init]; return self; }

- (void) prepareOpenGL 
{ 
	[super prepareOpenGL]; 
	[[self openGLContext] makeCurrentContext]; 
}

- (void) reshape 
{ 
	[super reshape];
}

- (void) drawRect: (NSRect)bounds 
{
	[[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1] set];
    NSRectFill(bounds);
}

@end


void init_application()
{
	// Initialize the application:
	[NSApplication sharedApplication];

	// Set the current working directory:
	// IF using an app bundle, set it to the resources folder.
	NSString *workingDirectory = [ [ NSFileManager defaultManager ] currentDirectoryPath ];
	NSString *appBundlePath = [ NSString stringWithFormat:@"%@/Contents/Resources", [ [ NSBundle mainBundle ] bundlePath ] ];
	NSFileManager *fileManager = [ NSFileManager defaultManager ];
	if ( [ fileManager changeCurrentDirectoryPath:appBundlePath ] == YES ) 
		workingDirectory = appBundlePath;
	s_workingDirectory = std::string( (char*)[ workingDirectory UTF8String ] );

	printf( "Working directory: %s\n", s_workingDirectory.c_str() );

	// Assign the Application Delegate:
	[NSApp setDelegate:[[AppDelegate alloc] init]];
	[NSApp finishLaunching];
}

void close_application ()
{
	// TODO: Implement this...
	// more is needed to clean up after the program.

	s_window_should_close = false;
}

void create_window ( const char *title, int width, int height )
{
	if ( !s_windowCreated )
	{
		s_windowCreated = true;
		s_window_should_close = false;

		// Create the main window and the content view.
		float windowWidth = (float)width;
		float windowHeight = (float)height;
		NSRect screenRect = [ [ NSScreen mainScreen ] frame ];
		NSRect windowFrame = NSMakeRect(( screenRect.size.width - windowWidth ) * 0.5f, 
										( screenRect.size.height - windowHeight ) * 0.5f, 
										windowWidth, windowHeight);
		
		NSWindowStyleMask windowStyleMask = NSWindowStyleMaskClosable | 
											NSWindowStyleMaskTitled |
											NSWindowStyleMaskMiniaturizable |
											NSWindowStyleMaskResizable;

		s_window = [ [ NSWindow alloc ] initWithContentRect:windowFrame 
										styleMask:windowStyleMask 
										backing:NSBackingStoreBuffered 
										defer:NO ];	

		[ s_window setDelegate:[ [ WindowDelegate alloc ] init] ];
		[ s_window setTitle:[ NSString stringWithUTF8String:title ] ];
		[ s_window makeKeyAndOrderFront:nil ];

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
		NSOpenGLPixelFormat *pixelFormat = [ [ NSOpenGLPixelFormat alloc ] initWithAttributes:openGLAttributes ];
		NSOpenGLContext *openglContext = [ [ NSOpenGLContext alloc ] initWithFormat:pixelFormat shareContext:nil ];

		// Set some properties for the windows main view:
		[ [ s_window contentView ] setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable ];
		[ [ s_window contentView ] setAutoresizesSubviews:YES ];

		// Create an OpenGL View and 
		s_glView = [ [ OpenGLView alloc ] init ];
		[ s_glView setPixelFormat:pixelFormat ];
		[ s_glView setOpenGLContext:openglContext ];
		[ s_glView setFrame:[ [ s_window contentView ] bounds ] ];
		[ s_glView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[ s_glView setWantsBestResolutionOpenGLSurface:YES ];
		
		[ pixelFormat release ];
			
		// Subview it to the windows main view:
		[ [ s_window contentView ] addSubview:s_glView ];

		// This enables (1) / disables (0) vsync
		int swapInterval = 1; 
		[[s_glView openGLContext] makeCurrentContext];
		[[s_glView openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
		[[s_glView openGLContext] setView:s_glView];
	}
	else
	{
		// TODO: This should result in some form of warning / static assert.
	}
}

void close_window ()
{
	s_window_should_close = true;
}

void process_window_events ()
{
	NSEvent* Event;
	do {
		Event = [ NSApp nextEventMatchingMask:NSEventMaskAny untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES ];
		
		switch ( [ Event type ] ) {
			
			case NSEventTypeKeyDown: 
			{ 
				[ NSApp sendEvent:Event ]; 
			} break;
			
			case NSEventTypeKeyUp: 
			{ 
				[ NSApp sendEvent:Event ]; 
			} break;
			
			case NSEventTypeScrollWheel: 
			{ 
				[ NSApp sendEvent:Event ]; 
			} break;
			
			default: { [ NSApp sendEvent:Event ]; } break;
		}

	} while ( Event != nil );

	// Mouse Position + in view + pressed button mask:
	CGPoint mouseLocationOnScreen = [ NSEvent mouseLocation ];
	NSRect windowRect = [ s_window convertRectFromScreen:NSMakeRect( mouseLocationOnScreen.x, mouseLocationOnScreen.y, 1, 1 ) ];
	NSPoint pointInWindow = windowRect.origin;
	
	NSPoint mouseLocationInView = [ s_glView convertPoint:pointInWindow fromView:nil ];
	
	bool mouseInWindowFlag = NSPointInRect( mouseLocationOnScreen, [ s_window frame ] );

	unsigned int mouseButtonMask = [ NSEvent pressedMouseButtons ];
}

void refresh_window () 
{ 
	[ [ s_glView openGLContext ] flushBuffer ]; 
}

bool window_should_close ()
{
	return s_window_should_close;
}

void hide_cursor ( bool state )
{	
	if ( state )
		[ NSCursor hide ];
	else
		[ NSCursor unhide ];
}






