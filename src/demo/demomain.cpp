#include <cocoawindowing.h>
#include <OpenGL/gl.h> // NOTE: Tempoary switch to legacy OpenGL.
#include <iostream>

int main ( int argc, char const *argv[] )
{
	
	init_application();
	create_window( "Cocoa Window", 640, 480 );

	std::cout << "OpenGL Version: " << glGetString(GL_VERSION) << '\n';

	glEnable( GL_FRAMEBUFFER_SRGB );

	glClearColor( 0.1f, 0.1f, 0.1f, 0.5f );

	float rotation = 0;

	while ( !window_is_closing() )
	{
		process_window_events();

		rotation += 1.0f;

		glClear( GL_COLOR_BUFFER_BIT );

		// NOTE: Tempoary switch to legacy OpenGL.
		glPushMatrix();
		glRotatef( rotation, 0, 0, 1.0 );
		glBegin( GL_TRIANGLES );
		glColor3f( 1.0f, 0.0f, 0.0f);
		glVertex3f( -0.5f, -0.5f, 0.0f );
		glColor3f( 0.0f, 1.0f, 0.0f);
		glVertex3f( 0.5f, -0.5f, 0.0f );
		glColor3f( 0.0f, 0.0f, 1.0f);
		glVertex3f( 0.0f, 0.5f, 0.0f );
		glEnd();
		glPopMatrix();
		
		refresh_window();
	}

	close_window();
	close_application();

	return 0;
}