#include <cocoawindowing.h>
#include <OpenGL/gl.h> // NOTE: Tempoary switch to legacy OpenGL.
#include <iostream>

int main ( int argc, char const *argv[] )
{
	init_application();
	create_window( "Cocoa Window", 640, 480 );
	
	std::cout << " OpenGL Version: " << glGetString(GL_VERSION) << '\n';
	glEnable( GL_FRAMEBUFFER_SRGB );
	glClearColor( 0.5f, 0.5f, 0.5f, 1.0f );

	float rotation = 0;
	while ( !get_window_is_closing() )
	{
		process_window_events();

		if ( get_key_down(Keys::KEY_F) ) set_window_fullscreen( true );
		if ( get_key_down(Keys::KEY_G) ) set_window_fullscreen( false );
		if ( get_key_down(Keys::KEY_R) ) set_window_size( 1280, 720 );
		if ( get_key_down(Keys::KEY_E) ) set_window_size( 640, 480 );

		glClear( GL_COLOR_BUFFER_BIT );

		// NOTE: Tempoary switch to legacy OpenGL.
		glPushMatrix();
		rotation += 1.0f;
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