#ifndef _COCOA_WINDOWING_H_
#define _COCOA_WINDOWING_H_

#include <string>

void init_application();
void close_application();

void create_window( const char *title, int width, int height );
void close_window();

void process_window_events();	
void refresh_window();

bool window_is_closing();

void hide_cursor( bool state );

#endif