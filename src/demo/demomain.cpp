#include <cocoawindowing.h>
#include <OpenGL/gl3.h>

int main ( int argc, char const *argv[] )
{
	
	init_application();
	create_window( "Cocoa Window", 640, 480 );

	glClearColor(0.1f, 0.1f, 0.1f, 0);

	while ( !window_should_close() )
	{
		process_window_events();

		glClear( GL_COLOR_BUFFER_BIT );
		
		refresh_window();
	}

	close_window();
	close_application();

	return 0;
}