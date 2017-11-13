#ifndef _COCOA_WINDOWING_H_
#define _COCOA_WINDOWING_H_

#include <cstddef> // For size_t.

extern "C" void init_application ();
extern "C" void close_application ();

extern "C" void create_window ( const char *title, int width, int height );
extern "C" void close_window ();
extern "C" void process_window_events ();	
extern "C" void refresh_window ();

extern "C" void set_cursor_hidden ( bool state );
extern "C" void set_window_fullscreen ( bool state );
extern "C" void set_window_complete_fullscreen ( bool state );
extern "C" void set_window_size ( float width, float height );

extern "C" void set_window_background_color ( float r, float g, float b, float a );
extern "C" void set_window_title_bar_hidden ( bool state );
extern "C" void set_window_title_hidden ( bool state );
extern "C" void set_window_enable_srgb ( bool state );
extern "C" void set_window_transparency ( bool state );

extern "C" bool get_key ( size_t keyCode );
extern "C" bool get_key_down ( size_t keyCode );
extern "C" bool get_key_up ( size_t keyCode );
extern "C" bool get_modifier_key ( size_t keyCode );

extern "C" bool get_mouse_button ( size_t button );
extern "C" bool get_mouse_button_down ( size_t button );
extern "C" bool get_mouse_button_up ( size_t button );
extern "C" float get_mouse_position_x ();
extern "C" float get_mouse_position_y ();
extern "C" float get_mouse_scroll_x ();
extern "C" float get_mouse_scroll_y ();

extern "C" bool get_window_is_closing ();
extern "C" float get_window_width ();
extern "C" float get_window_height ();

enum ModifierKeys : size_t
{
	COMMAND = 0,
	OPTION = 1,
	CONTROL = 2,
	SHIFT = 3
};

enum Keys : size_t
{
	KEY_A = 'a',
	KEY_B = 'b',
	KEY_C = 'c',
	KEY_D = 'd',
	KEY_E = 'e',
	KEY_F = 'f',
	KEY_G = 'g',
	KEY_H = 'h',
	KEY_I = 'i',
	KEY_J = 'j',
	KEY_K = 'k',
	KEY_L = 'l',
	KEY_M = 'm',
	KEY_N = 'n',
	KEY_O = 'o',
	KEY_P = 'p',
	KEY_Q = 'q',
	KEY_R = 'r',
	KEY_S = 's',
	KEY_T = 't',
	KEY_U = 'u',
	KEY_V = 'v',
	KEY_W = 'w',
	KEY_X = 'x',
	KEY_Y = 'y',
	KEY_Z = 'z',

	KEY_0 = 48,
	KEY_1 = 49,
	KEY_2 = 50,
	KEY_3 = 51,
	KEY_4 = 52,
	KEY_5 = 53,
	KEY_6 = 54,
	KEY_7 = 55,
	KEY_8 = 56,
	KEY_9 = 57,

	KEY_PLUS = '+',
	KEY_MINUS = '-',
	KEY_STAR = '*',
	KEY_EQUALS = '=',
	KEY_UNDERSCORE = '_',
	KEY_RIGHT_ROUNDBRACKET = ')',
	KEY_LEFT_ROUNDBRACKET = '(',
	KEY_RIGHT_CURLYBRACKET = '}',
	KEY_LEFT_CURLYBRACKET = '{',
	KEY_RIGHT_SQUAREBRACKET = ']',
	KEY_LEFT_SQUAREBRACKET = '[',
	KEY_AMPERSAN = '&',
	KEY_CARROT = '^',
	KEY_PERCENTSIGN = '%',
	KEY_DOLLARSIGN = '$',
	KEY_POUND = '#',
	KEY_AT = '@',
	KEY_EXCLIMATION = '!',
	KEY_TILDA = '~',
	// NOTE: '`' This key is still missing.
	KEY_SEMICOLON = ';',
	KEY_COLON = ':',
	KEY_SINGLEQUOTE = '\'',
	KEY_DOUBLEQUOTE = '\"',
	KEY_BACKSLASH = '\\',
	KEY_FORWARDSLASH = '/',
	KEY_QUESTIONMARK = '?',
	KEY_COMMA = ',',
	KEY_FULLSTOP = '.',
	KEY_LESSTHAN = '<',
	KEY_GREATERTHAN = '>',
	// NOTE: '|' This key is still missing.

	KEY_ENTER = 13,
	KEY_TAB = 9,
	KEY_DELETE = 127,
	KEY_UP = 63232,
	KEY_DOWN = 63233,
	KEY_LEFT = 63234,
	KEY_RIGHT = 63235,
};

enum Mouse : size_t
{
	LEFT = 0,
	RIGHT = 1,
};

#endif