//
// File: cocoawindowing.mm
// Date: 2018.3.11
// Creator: Xavier S
//

#import <Cocoa/Cocoa.h>
#import "cocoawindowing.h"

//////////////////////////////
/////////////////////////////////////////////
static bool app_inited = false;
static bool window_created = false;
static bool temp_only_one_window = false; // NOTE(Xavier): This is a tempoary solution to the problem of not being able to free windows.
static bool window_fullscreen = false;
static bool cusror_hidden = false;
static NSString *working_directory = nullptr;

#define NUM_KEYS 128
#define NUM_CHAR_KEYS 128
#define NUM_MOUSE_BUTTONS 8

static struct {
	bool active_keys[NUM_KEYS];
	bool down_keys[NUM_KEYS];
	bool up_keys[NUM_KEYS];

	bool active_char_keys[NUM_CHAR_KEYS];
	bool down_char_keys[NUM_CHAR_KEYS];
	bool up_char_keys[NUM_CHAR_KEYS];

	bool active_mouse_buttons[NUM_MOUSE_BUTTONS];
	bool down_mouse_buttons[NUM_MOUSE_BUTTONS];
	bool up_mouse_buttons[NUM_MOUSE_BUTTONS];

	struct {
		float x;
		float y;
		float scroll_delta_x;
		float scroll_delta_y;
	} mouse;
} input_info;


//////////////////////////////
/////////////////////////////////////////////
@interface App_Delegate : NSObject <NSApplicationDelegate> {

}

@end

@interface App_Delegate ()

@end

@implementation App_Delegate

- (void) applicationWillFinishLaunching: (NSNotification *)notification {
	id menubar = [[NSMenu new] autorelease];
		id app_menu_item = [[NSMenuItem new] autorelease];
			id app_menu = [[NSMenu new] autorelease];
				id app_name = [[NSProcessInfo processInfo] processName];
				
				id quit_title = [@"Quit " stringByAppendingString:app_name];
				id quit_menu_item = [[[NSMenuItem alloc] initWithTitle:quit_title action:@selector(terminate:) keyEquivalent:@"q"] autorelease];
				[app_menu addItem:quit_menu_item];

				id close_title = @"Close Window ";
				id close_menu_item = [[[NSMenuItem alloc] initWithTitle:close_title action:@selector(closeWindow:) keyEquivalent:@"w"] autorelease];
				[app_menu addItem:close_menu_item];

			[app_menu_item setSubmenu:app_menu];
		[menubar addItem:app_menu_item];
	[NSApp setMainMenu:menubar];
}

- (void) applicationDidFinishLaunching: (NSNotification *)notification {
	[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
	[NSApp activateIgnoringOtherApps:YES];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication*)sender { return NO; }
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender { return NSTerminateNow; }

@end


//////////////////////////////
/////////////////////////////////////////////
@interface Window_Controller : NSWindowController {

}

@end

@interface Window_Controller ()

@end

@implementation Window_Controller

@end


//////////////////////////////
/////////////////////////////////////////////
@interface Window_Delegate : NSWindow <NSWindowDelegate> {

}

@end

@interface Window_Delegate ()

- (IBAction)closeWindow:(id)sender;

@end

@implementation Window_Delegate

- (BOOL) acceptsFirstResponder { return YES; }
- (BOOL) canBecomeKeyWindow { return YES; }
- (BOOL) canBecomeMainWindow { return YES; }
- (void) awakeFromNib { [self makeKeyAndOrderFront:nil]; }
- (void) becomeKeyWindow { [super becomeKeyWindow]; }

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
	return frameSize;
}

- (IBAction)closeWindow:(id)sender {
	[self performClose: sender];
}

- (BOOL)windowShouldClose:(NSWindow *)sender {	
	[sender autorelease];

	window_created = false;
	
	return YES;
}

@end


//////////////////////////////
/////////////////////////////////////////////
@interface OpenGL_View : NSOpenGLView {

}

@end

@interface OpenGL_View ()

@end

@implementation OpenGL_View

- (BOOL) acceptsFirstResponder { return YES; }

- (id) initWithFrame: (NSRect)frame {
	// NOTE(Xavier): Keep multisampling attributes at the start of the attribute 
	// lists since code below assumes they are array elements 0 through 4:
	unsigned int samples = 0;
	NSOpenGLPixelFormatAttribute windowedAttrs[] = {
		NSOpenGLPFAMultisample,
		NSOpenGLPFASampleBuffers, samples ? 1u : 0,
		NSOpenGLPFASamples, samples,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAColorSize, 32,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAAlphaSize, 8,
		NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
		0
	};

	NSOpenGLPixelFormat *pixel_format = [[NSOpenGLPixelFormat alloc] initWithAttributes:windowedAttrs];
	if (!pixel_format) {
		bool valid_format = false;
		while (!pixel_format && samples > 0) {
			samples /= 2;
			windowedAttrs[2] = samples ? 1 : 0;
			windowedAttrs[4] = samples;
			pixel_format = [[NSOpenGLPixelFormat alloc] initWithAttributes:windowedAttrs];
			if (pixel_format) {
				valid_format = true;
				break;
			}
		}
		
		if (!valid_format) {
			NSLog(@"ERROR: OpenGL pixel format not supported.");
			return nil;
		}
	}
	
	self = [super initWithFrame:frame pixelFormat:[pixel_format autorelease]];

	[self setWantsBestResolutionOpenGLSurface:YES];

	return self;
}

- (void) prepareOpenGL {
	[super prepareOpenGL];
		
	[[self window] setLevel: NSNormalWindowLevel];
	[[self window] makeKeyAndOrderFront: self];
	[[self openGLContext] makeCurrentContext];
	
	// Vsync On (1) / Off (0):
	GLint swapInt = 1; 
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
}

- (void) drawRect: (NSRect)dirtyRect {
	[super drawRect:dirtyRect];
}

- (void) keyDown: (NSEvent*)event {
	if ([event isARepeat] == NO) {
		size_t key_code = [event keyCode];		
		if (key_code < NUM_KEYS) {
			input_info.active_keys[key_code] = true;
			input_info.down_keys[key_code] = true;
			input_info.up_keys[key_code] = false;
		}

		// NSString *characters = [event charactersIgnoringModifiers];
		// DEBUG_LOG(characters << ", " << [characters characterAtIndex:0] << ", " << [event keyCode]);
		// NSLog(characters);
	}
}

- (void) keyUp: (NSEvent*)event {
	size_t key_code = [event keyCode];		
	if (key_code < NUM_KEYS) {
		input_info.active_keys[key_code] = false;
		input_info.down_keys[key_code] = false;
		input_info.up_keys[key_code] = true;
	}
}

- (void)mouseMoved:(NSEvent*)event {
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	input_info.mouse.x = point.x;
	input_info.mouse.y = point.y;
}

- (void) scrollWheel: (NSEvent*)event {
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	input_info.mouse.x = point.x;
	input_info.mouse.y = point.y;
	input_info.mouse.scroll_delta_x = [event deltaX];
	input_info.mouse.scroll_delta_x = [event deltaY];
}

- (void) mouseDown: (NSEvent*)event {
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	input_info.mouse.x = point.x;
	input_info.mouse.y = point.y;
	input_info.active_mouse_buttons[0] = true;
	input_info.down_mouse_buttons[0] = true;
	input_info.up_mouse_buttons[0] = false;
}

- (void) mouseUp: (NSEvent*)event {
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	input_info.mouse.x = point.x;
	input_info.mouse.y = point.y;
	input_info.active_mouse_buttons[0] = false;
	input_info.down_mouse_buttons[0] = false;
	input_info.up_mouse_buttons[0] = true;
}

- (void) rightMouseDown: (NSEvent*)event {
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	input_info.mouse.x = point.x;
	input_info.mouse.y = point.y;
	input_info.active_mouse_buttons[1] = true;
	input_info.down_mouse_buttons[1] = true;
	input_info.up_mouse_buttons[1] = false;
}

- (void) rightMouseUp: (NSEvent*)event {
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	input_info.mouse.x = point.x;
	input_info.mouse.y = point.y;
	input_info.active_mouse_buttons[1] = false;
	input_info.down_mouse_buttons[1] = false;
	input_info.up_mouse_buttons[1] = true;
}

- (void) otherMouseDown: (NSEvent*)event {
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	input_info.mouse.x = point.x;
	input_info.mouse.y = point.y;
	input_info.active_mouse_buttons[2] = true;
	input_info.down_mouse_buttons[2] = true;
	input_info.up_mouse_buttons[2] = false;
}

- (void) otherMouseUp: (NSEvent*)event {
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	input_info.mouse.x = point.x;
	input_info.mouse.y = point.y;
	input_info.active_mouse_buttons[2] = false;
	input_info.down_mouse_buttons[2] = false;
	input_info.up_mouse_buttons[2] = true;
}

- (void) mouseEntered: (NSEvent*)event {
	// ...
}

- (void) mouseExited: (NSEvent*)event {
	// ...
}

@end


//////////////////////////////
/////////////////////////////////////////////
static Window_Controller *window_controller;
static Window_Delegate *window_delegate;
static OpenGL_View *opengl_view;


///////////////
// App:
extern "C" void app_init () {
	if (!app_inited) {
		app_inited = true;
		
		[NSApplication sharedApplication];

		// Set the current working directory:
		// If using an app bundle, set it to the resources folder.
		NSFileManager *fileManager = [NSFileManager defaultManager];
		working_directory = [[NSFileManager defaultManager] currentDirectoryPath];
		
		NSString *app_bundle_path = [NSString stringWithFormat:@"%@/Contents/Resources", [[NSBundle mainBundle] bundlePath]];
		if ( [fileManager changeCurrentDirectoryPath:app_bundle_path] == YES ) {
			working_directory = app_bundle_path;
		}

		// TODO(Xavier): (2017.11.13) Remove this log:
		NSLog(@"Working directory: %@\n", working_directory);

		// Assign the Application Delegate:
		[NSApp setDelegate:[[App_Delegate alloc] init]];
		[NSApp finishLaunching];
	}
	else {
		// TODO(Xavier): This should result in some better form of warning / static assert.
		NSLog(@"The application has already been initalised.\n");
	}
}

extern "C" void app_quit () {
	// TODO(Xavier)
}


///////////////
// Screen:
extern "C" int screen_get_width () {
	return [[NSScreen mainScreen] frame].size.width;
}

extern "C" int screen_get_height () {
	return [[NSScreen mainScreen] frame].size.height;
}

extern "C" void screen_get_size ( int *x, int *y ) {
	*x = [[NSScreen mainScreen] frame].size.width;
	*y = [[NSScreen mainScreen] frame].size.height;
}


///////////////
// Window:
extern "C" void window_create ( const char *title, int width, int height ) {
	if (!window_created && !temp_only_one_window) {
		window_created = true;
		temp_only_one_window = true;

		NSRect screen_rect = [[NSScreen mainScreen] frame];
		NSRect view_rect = NSMakeRect(0, 0, width, height);
		NSRect window_rect = NSMakeRect( NSMidX(screen_rect) - NSMidX(view_rect), NSMidY(screen_rect) - NSMidY(view_rect), view_rect.size.width, view_rect.size.height );

		NSUInteger window_style = NSWindowStyleMaskTitled  | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable; 
		window_delegate = [[Window_Delegate alloc] initWithContentRect:window_rect styleMask:window_style backing:NSBackingStoreBuffered defer:NO]; 
		[window_delegate autorelease];

		// NOTE(Xavier): Hide title bar texture & set color:
		[window_delegate setBackgroundColor:[NSColor colorWithRed:0.2148 green:0.2148 blue:0.2539 alpha:1]];
		window_delegate.titlebarAppearsTransparent = true;
		window_delegate.titleVisibility = NSWindowTitleHidden;

		// NOTE(Xavier): Here you could instead load the window from a nib file.
		window_controller = [[Window_Controller alloc] initWithWindow:window_delegate]; 
		[window_controller autorelease];

		opengl_view = [[[OpenGL_View alloc] initWithFrame:window_rect] autorelease];
		[window_delegate setContentView:opengl_view];

		[window_delegate setAcceptsMouseMovedEvents:YES];
		[window_delegate setTitle:[[NSProcessInfo processInfo] processName]];
		[window_delegate setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];
		[window_delegate orderFrontRegardless];
		
		// This is done to prevent keys from beeping:
		[window_delegate setInitialFirstResponder:(NSView *)opengl_view]; 
		[window_delegate makeFirstResponder:(NSView *)opengl_view];

		// Set this at the active context:
		[[opengl_view openGLContext] makeCurrentContext];
	}
	else {
		// TODO(Xavier): This should result in some better form of warning / static assert.
		NSLog(@"A window has already been created.\n");
	}
}

extern "C" void window_close () {
	[window_delegate performClose: window_delegate];
}

extern "C" void window_process_events () {
	for (size_t i = 0; i < NUM_KEYS; ++i) {
		input_info.down_keys[i] = false;
		input_info.up_keys[i] = false;
	}

	for (size_t i = 0; i < NUM_CHAR_KEYS; ++i) {
		input_info.down_char_keys[i] = false;
		input_info.up_char_keys[i] = false;
	}
	
	for (size_t i = 0; i < NUM_MOUSE_BUTTONS; ++i) {
		input_info.down_mouse_buttons[i] = false;
		input_info.up_mouse_buttons[i] = false;
	}

	NSEvent *event;
	do {
		event = [NSApp nextEventMatchingMask:NSEventMaskAny untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES];
		switch ([event type]) {
			default: {
				[NSApp sendEvent:event];
			} break;
		}
	} while (event != nil);
}

extern "C" void window_draw () {
	[[opengl_view openGLContext] flushBuffer];
}


extern "C" bool window_get_is_closed () {
	return !window_created;
}


extern "C" void window_set_cursor_hidden ( bool state ) {
	if (!cusror_hidden && state) {
		cusror_hidden = true;
		[NSCursor hide];
	}
	else if (cusror_hidden && !state) {
		[NSCursor unhide];
	}
}

extern "C" bool window_get_cursor_hidden () {
	return cusror_hidden;
}


extern "C" bool window_get_fullscreen () {
	return window_fullscreen;
}

extern "C" void window_set_fullscreen ( bool state ) {
	if (!opengl_view.inFullScreenMode) {
		if ( state && !window_fullscreen ) { [window_delegate toggleFullScreen:nil]; window_fullscreen = true; }
		else if ( !state && window_fullscreen ) { [window_delegate toggleFullScreen:nil]; window_fullscreen = false; }
	}
}


extern "C" bool window_get_complete_fullscreen () {
	return opengl_view.inFullScreenMode;
}

extern "C" void window_set_complete_fullscreen ( bool state ) {
	if (state && !opengl_view.inFullScreenMode) {
		if (!opengl_view.inFullScreenMode) [opengl_view enterFullScreenMode:[NSScreen mainScreen] withOptions:nil];
	}
	else if (!state && opengl_view.inFullScreenMode) {
		[opengl_view exitFullScreenModeWithOptions:nil];
		[window_delegate makeKeyAndOrderFront:nil];

		// This is done to prevent keys from beeping:
		[window_delegate setInitialFirstResponder:(NSView *)opengl_view]; 
		[window_delegate makeFirstResponder:(NSView *)opengl_view];
	}
}


extern "C" int window_get_width () {
	return [opengl_view bounds].size.width;
}

extern "C" int window_get_height () {
	return [opengl_view bounds].size.height;
}

extern "C" void window_get_size ( int *width, int *height ) {
	*width = [opengl_view bounds].size.width;
	*height = [opengl_view bounds].size.height;
}

extern "C" void window_set_size ( int width, int height ) {
	if (!window_fullscreen && !opengl_view.inFullScreenMode) {
		// NOTE(Xavier): (2017.11.13) The title bar had to be taken into account.
		// For some reason, this it different to when the window is first created.
		float titleBarHeight = [window_delegate frame].size.height - [[window_delegate contentView] frame].size.height;
		NSRect frame = [window_delegate frame];
		frame.origin.x = ([[NSScreen mainScreen] frame].size.width - width) / 2;
		frame.origin.y = ([[NSScreen mainScreen] frame].size.height - height) / 2;
		frame.size.width = width;
		frame.size.height = height + titleBarHeight;
		[window_delegate setFrame:frame display:YES animate:YES];
	}
}


extern "C" int window_get_width_hidpi () {
	return [opengl_view convertRectToBacking:[opengl_view bounds]].size.width;
}

extern "C" int window_get_height_hidpi () {
	return [opengl_view convertRectToBacking:[opengl_view bounds]].size.height;
}

extern "C" void window_get_size_hidpi ( int *width, int *height ) {
	*width = [opengl_view convertRectToBacking:[opengl_view bounds]].size.width;
	*height = [opengl_view convertRectToBacking:[opengl_view bounds]].size.height;
}

extern "C" int window_get_x () {
	return [window_delegate frame].origin.x;
}

extern "C" int window_get_y () {
	return [window_delegate frame].origin.y;
}

extern "C" void window_get_position ( int *x, int *y ) {
	*x = [window_delegate frame].origin.x;
	*y = [window_delegate frame].origin.y;
}

extern "C" void window_set_position ( int x, int y ) {
	if (!window_fullscreen) {
		NSRect frame = [window_delegate frame];
		frame.origin.x = x;
		frame.origin.y = y;
		[window_delegate setFrame:frame display:YES animate:YES];
	}
}


extern "C" void window_set_title_hidden ( bool state ) {
	// TODO(Xavier)
}

extern "C" void window_set_title_bar_transparent ( bool state ) {
	// TODO(Xavier)
}

extern "C" void window_set_background_srgb ( bool state ) {
	// TODO(Xavier)
}

extern "C" void window_set_background_color ( float r, float g, float b, float a ) {
	// TODO(Xavier)
}

extern "C" void window_set_transparent ( bool state ) {
	// TODO(Xavier)
}


///////////////
// Input:
extern "C" bool input_get_key ( Key key ) {
	if (static_cast<size_t>(key) >= NUM_KEYS) { return false; }
	if (input_info.active_keys[static_cast<size_t>(key)]) { return true; }
	return false;
}

extern "C" bool input_get_key_down ( Key key ) {
	if (static_cast<size_t>(key) >= NUM_KEYS) { return false; }
	if (input_info.down_keys[static_cast<size_t>(key)]) { return true; }
	return false;
}

extern "C" bool input_get_key_up ( Key key ) {
	if (static_cast<size_t>(key) >= NUM_KEYS) { return false; }
	if (input_info.up_keys[static_cast<size_t>(key)]) { return true; }
	return false;
}


extern "C" bool input_get_any_key () {
	for (size_t i = 0; i < NUM_KEYS; ++i) {
		if (input_info.active_keys[i]) return true;
	}
	return false;
}

extern "C" bool input_get_any_key_down () {
	for (size_t i = 0; i < NUM_KEYS; ++i) {
		if (input_info.down_keys[i]) return true;
	}
	return false;
}

extern "C" bool input_get_any_key_up () {
	for (size_t i = 0; i < NUM_KEYS; ++i) {
		if (input_info.up_keys[i]) return true;
	}
	return false;
}


extern "C" bool input_get_char ( char key ) {
	return false; // TODO(Xavier)
}

extern "C" bool input_get_char_down ( char key ) {
	return false; // TODO(Xavier)
}

extern "C" bool input_get_char_up ( char key ) {
	return false; // TODO(Xavier)
}


extern "C" bool input_get_mouse ( Mouse button ) {
	if (static_cast<size_t>(button) >= NUM_MOUSE_BUTTONS) { return false; }
	if (input_info.active_mouse_buttons[static_cast<size_t>(button)]) { return true; }
	return false;
}

extern "C" bool input_get_mouse_down ( Mouse button ) {
	if (static_cast<size_t>(button) >= NUM_MOUSE_BUTTONS) { return false; }
	if (input_info.down_mouse_buttons[static_cast<size_t>(button)]) { return true; }
	return false;
}

extern "C" bool input_get_mouse_up ( Mouse button ) {
	if (static_cast<size_t>(button) >= NUM_MOUSE_BUTTONS) { return false; }
	if (input_info.up_mouse_buttons[static_cast<size_t>(button)]) { return true; }
	return false;
}


extern "C" bool input_get_mouse_num ( int button ) {
	if (button >= NUM_MOUSE_BUTTONS) { return false; }
	if (input_info.active_mouse_buttons[button]) { return true; }
	return false;
}

extern "C" bool input_get_mouse_num_down ( int button ) {
	if (button >= NUM_MOUSE_BUTTONS) { return false; }
	if (input_info.down_mouse_buttons[button]) { return true; }
	return false;
}

extern "C" bool input_get_mouse_num_up ( int button ) {
	if (button >= NUM_MOUSE_BUTTONS) { return false; }
	if (input_info.up_mouse_buttons[button]) { return true; }
	return false;
}


extern "C" int input_get_mouse_x () {
	return input_info.mouse.x;
}

extern "C" int input_get_mouse_y () {
	return input_info.mouse.y;
}

extern "C" void input_get_mouse_position ( int *x, int *y ) {
	*x = input_info.mouse.x;
	*y = input_info.mouse.y;
}


extern "C" int input_get_mouse_x_hidpi () {
	NSRect point;
	point.size.width = input_info.mouse.x;
	point.size.height = input_info.mouse.y;
	return [opengl_view convertRectToBacking:point].size.width;
}

extern "C" int input_get_mouse_y_hidpi () {
	NSRect point;
	point.size.width = input_info.mouse.x;
	point.size.height = input_info.mouse.y;
	return [opengl_view convertRectToBacking:point].size.height;
}

extern "C" void input_get_mouse_position_hidpi ( int *x, int *y ) {
	NSRect point;
	point.size.width = input_info.mouse.x;
	point.size.height = input_info.mouse.y;
	point = [opengl_view convertRectToBacking:point];
	*x = point.size.width;
	*y = point.size.height;
}


extern "C" float input_get_scroll_delta_x () {
	return input_info.mouse.scroll_delta_x;
}

extern "C" float input_get_scroll_delta_y () {
	return input_info.mouse.scroll_delta_y;
}

extern "C" void input_get_scroll_delta ( float *x, float *y) {
	*x = input_info.mouse.scroll_delta_x;
	*y = input_info.mouse.scroll_delta_y;
}


///////////////
// Util:
extern "C" const char* util_get_application_support_directory ( const char *appName ) {
	NSString *bundleID = [NSString stringWithUTF8String:appName];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *dirPath = nil;
	NSArray *appSupportDir = [fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
	if ([appSupportDir count] > 0) {
		dirPath = [[appSupportDir objectAtIndex:0] URLByAppendingPathComponent:bundleID];
		NSError *theError = nil;
		if (![fm createDirectoryAtURL:dirPath withIntermediateDirectories:YES attributes:nil error:&theError]) {
			return nullptr;
		}
	}

	// NOTE(Xavier): (2017.11.13) There may be a memory leak here:
	return (const char*)[[dirPath.path stringByAppendingString:@"/"] UTF8String];
}

extern "C" const char* util_get_executable_directory () {
	return ""; // TODO(Xavier)
}

extern "C" const char* util_get_resource_directory () {
	return ""; // TODO(Xavier)
}


extern "C" void util_create_directory_at ( const char* dir ) {
	NSString *directory = [NSString stringWithUTF8String:dir];
	NSError	*error = nil;
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
}

extern "C" void util_remove_file_at ( const char* filename ) {
	NSString *fileRemoval = [NSString stringWithUTF8String:filename];
	[[NSFileManager defaultManager] removeItemAtPath:fileRemoval error:NULL];
}
