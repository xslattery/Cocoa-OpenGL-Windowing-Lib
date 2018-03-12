//
// File: cocoawindowing.h
// Date: 2018.3.11
// Creator: Xavier S
//

#ifndef _COCOA_WINDOWING_H_
#define _COCOA_WINDOWING_H_

#include "stddef.h"

///////////////
// App:
extern "C" void app_init ();
extern "C" void app_quit ();

///////////////
// Screen:
extern "C" int screen_get_width ();
extern "C" int screen_get_height ();
extern "C" void screen_get_size ( int *x, int *y );

///////////////
// Window:
extern "C" void window_create ( const char *title, int width, int height );
extern "C" void window_close ();
extern "C" void window_process_events ();
extern "C" void window_draw ();

extern "C" bool window_get_is_closed ();

extern "C" bool window_get_cursor_hidden ();
extern "C" void window_set_cursor_hidden ( bool state );

extern "C" bool window_get_fullscreen ();
extern "C" void window_set_fullscreen ( bool state );

extern "C" bool window_get_complete_fullscreen ();
extern "C" void window_set_complete_fullscreen ( bool state );

extern "C" int window_get_width ();
extern "C" int window_get_height ();
extern "C" void window_get_size ( int *width, int *height );
extern "C" void window_set_size ( int width, int height );

extern "C" int window_get_width_hidpi ();
extern "C" int window_get_height_hidpi ();
extern "C" void window_get_size_hidpi ( int *width, int *height );

extern "C" int window_get_x ();
extern "C" int window_get_y ();
extern "C" void window_get_position ( int *x, int *y );
extern "C" void window_set_position ( int x, int y );

extern "C" void window_set_title_hidden ( bool state );
extern "C" void window_set_title_bar_transparent ( bool state );
extern "C" void window_set_background_srgb ( bool state );
extern "C" void window_set_background_color ( float r, float g, float b, float a );
extern "C" void window_set_transparent ( bool state );

///////////////
// Input:
enum Key : size_t;
enum Mouse : size_t;

extern "C" bool input_get_key ( Key key );
extern "C" bool input_get_key_down ( Key key );
extern "C" bool input_get_key_up ( Key key );

extern "C" bool input_get_any_key ();
extern "C" bool input_get_any_key_down ();
extern "C" bool input_get_any_key_up ();

extern "C" bool input_get_char ( char key );
extern "C" bool input_get_char_down ( char key );
extern "C" bool input_get_char_up ( char key );

extern "C" bool input_get_mouse ( Mouse mouse );
extern "C" bool input_get_mouse_down ( Mouse mouse );
extern "C" bool input_get_mouse_up ( Mouse mouse );

extern "C" bool input_get_mouse_num ( int mouse );
extern "C" bool input_get_mouse_num_down ( int mouse );
extern "C" bool input_get_mouse_num_up ( int mouse );

extern "C" int input_get_mouse_x ();
extern "C" int input_get_mouse_y ();
extern "C" void input_get_mouse_position ( int *x, int *y );

extern "C" int input_get_mouse_x_hidpi ();
extern "C" int input_get_mouse_y_hidpi ();
extern "C" void input_get_mouse_position_hidpi ( int *x, int *y );

extern "C" float input_get_scroll_delta_x ();
extern "C" float input_get_scroll_delta_y ();
extern "C" void input_get_scroll_delta ( float *x, float *y);

///////////////
// Util:
extern "C" const char* util_get_application_support_directory ( const char *appName );
extern "C" const char* util_get_executable_directory ();
extern "C" const char* util_get_resource_directory ();

extern "C" void util_create_directory_at ( const char* dir );
extern "C" void util_remove_file_at ( const char* filename );

///////////////
enum Key : size_t {
	K_A = 0,
	K_B = 11,
	K_C = 8,
	K_D = 2,
	K_E = 14,
	K_F = 3,
	K_G = 5,
	K_H = 4,
	K_I = 34,
	K_J = 38,
	K_K = 40,
	K_L = 37,
	K_M = 46,
	K_N = 45,
	K_O = 31,
	K_P = 35,
	K_Q = 12,
	K_R = 15,
	K_S = 1,
	K_T = 17,
	K_U = 32,
	K_V = 9,
	K_W = 13,
	K_X = 7,
	K_Y = 16,
	K_Z = 6,

	K_0 = 29,
	K_1 = 18,
	K_2 = 19,
	K_3 = 20,
	K_4 = 21,
	K_5 = 23,
	K_6 = 22,
	K_7 = 26,
	K_8 = 28,
	K_9 = 25,

	K_SPACE = 49,
	K_MINUS = 27,
	K_EQUALS = 24,
	K_LEFT_SQUARE_BRACKET = 33,
	K_RIGHT_SQUARE_BRACKET = 30,
	K_BACKSLASH = 42,
	K_FORWARDSLASH = 44,
	K_COMMA = 43,
	K_PERIOD = 47,
	K_QUOTE = 39,
	K_SEMICOLON = 41,
	K_ENTER = 36,
	K_BACKSPACE = 51,
	K_TAB = 48,

	K_OTHER_THING = 50, // This is for ` <-- That key (I don't know what its called)

	K_UP = 126,
	K_DOWN = 125,
	K_LEFT = 123,
	K_RIGHT = 124,

	// TODO(Xavier): Make these Keys work:
	K_SHIFT = 0,
	K_CONTROL = 0,
	K_OPTION = 0, K_ALT = 0,
	K_COMMAND = 0, K_HOME = 0, K_WINDOWS = 0,
};

enum Mouse : size_t {
	M_LEFT = 0,
	M_RIGHT = 1,
	M_OTHER = 2,
};

#endif