#include <cocoawindowing.h>
#include <OpenGL/gl3.h>
#include <iostream>

// NOTE(Xavier): (2017.11.14) This should be defined
// at compile time by argument, so it can be easily changed.
#define DEBUG 1

#if DEBUG
#define GLCALL(x) x; check_opengl_errors( __LINE__ );
#else
#define GLCALL(x) x;
#endif

static void check_opengl_errors ( size_t line )
{
	while ( GLenum error = glGetError() )
	{
		std::cout << "OpenGL Error: L:" << line << " : " << error << '\n';
	}
}

static unsigned int compile_shader ( unsigned int type, const std::string& source )
{
	unsigned int shader = GLCALL( glCreateShader( type ) );
	const char *src = source.c_str();
	GLCALL( glShaderSource( shader, 1, &src, nullptr ) );
	GLCALL( glCompileShader( shader ) );

	int result;
	GLCALL( glGetShaderiv( shader, GL_COMPILE_STATUS, &result ) );
	if ( result == GL_FALSE )
	{
		int length;
		GLCALL( glGetShaderiv( shader, GL_INFO_LOG_LENGTH, &length ) );
		char* message = (char*)alloca( length * sizeof(char) );
		GLCALL( glGetShaderInfoLog( shader, length, &length, message ) );
		std::cout << "Shader Failed to Compile: " << '\n';
		std::cout << message << '\n';
	}

	return shader;
}

static unsigned int load_shader ( const std::string& vertexShader, const std::string& fragementShader )
{
	unsigned int program = GLCALL( glCreateProgram() );
	unsigned int vs = compile_shader( GL_VERTEX_SHADER, vertexShader );
	unsigned int fs = compile_shader( GL_FRAGMENT_SHADER, fragementShader );

	GLCALL( glAttachShader( program, vs) );
	GLCALL( glAttachShader( program, fs) );
	GLCALL( glLinkProgram( program ) );
	GLCALL( glValidateProgram( program ) );

	GLCALL( glDetachShader( program, vs ) );
	GLCALL( glDetachShader( program, fs ) );

	GLCALL( glDeleteShader(vs) );
	GLCALL( glDeleteShader(fs) );

	return program;
}

int main ( int argc, char const *argv[] )
{
	init_application();
	create_window( "Cocoa Window", 640, 480 );

	set_window_background_color (0.2, 0.2, 0.2, 0.7);
	set_window_background_enable_srgb (true);
	set_window_title_bar_hidden (true);
	set_window_title_hidden (true);
	set_window_transparency (true);
	
	std::cout << "OpenGL Vendor: " << glGetString(GL_VENDOR) << '\n';
	std::cout << "OpenGL Renderer: " << glGetString(GL_RENDERER) << '\n';
	std::cout << "OpenGL Version: " << glGetString(GL_VERSION) << '\n';
	std::cout << "OpenGL Shading Language: " << glGetString(GL_SHADING_LANGUAGE_VERSION) << '\n';

	GLCALL( glEnable( GL_FRAMEBUFFER_SRGB ) );
	GLCALL( glClearColor( 0.1f, 0.1f, 0.1f, 0.7f ) );

	unsigned int shader = load_shader(
		R"(
			#version 330 core

			layout(location = 0) in vec4 position;

			void main ()
			{
				gl_Position = position;
			}
		)",
		R"(
			#version 330 core

			out vec4 color;

			void main ()
			{
				color = vec4( 1.0, 0.0, 0.0, 1.0 );
			}
		)"
	);

	GLCALL( glUseProgram( shader ) );

	float positions [6] =
	{
		-0.5f, -0.5f,
		0.5f, -0.5f,
		0.0f, 0.5f
	};

	unsigned int vao;
	GLCALL( glGenVertexArrays( 1, &vao ) );
	GLCALL( glBindVertexArray( vao ) );

	unsigned int vbo;
	GLCALL( glGenBuffers( 1, &vbo ) );
	GLCALL( glBindBuffer( GL_ARRAY_BUFFER, vbo ) );
	GLCALL( glBufferData( GL_ARRAY_BUFFER, 6*sizeof(float), positions, GL_STATIC_DRAW ) );

	GLCALL( glEnableVertexAttribArray( 0 ) );
	GLCALL( glVertexAttribPointer( 0, 2, GL_FLOAT, GL_FALSE, sizeof(float)*2, 0 ) );

	while ( !get_window_is_closing() )
	{
		process_window_events();

		if ( get_key_down(Keys::KEY_F) ) set_window_fullscreen( true );
		if ( get_key_down(Keys::KEY_G) ) set_window_fullscreen( false );
		if ( get_key_down(Keys::KEY_R) ) set_window_size( 1280, 720 );
		if ( get_key_down(Keys::KEY_E) ) set_window_size( 640, 480 );

		GLCALL( glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT ) );
		
		GLCALL( glDrawArrays( GL_TRIANGLES, 0, 3 ) );

		refresh_window();
	}

	close_window();
	close_application();

	return 0;
}