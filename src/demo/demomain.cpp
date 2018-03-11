#include <cocoawindowing.h>
#include <OpenGL/gl3.h>
#include <iostream>

// NOTE(Xavier): (2017.11.14) This should be defined
// at compile time by argument, so it can be easily changed.
#define DEBUG 1

#if DEBUG
#define GLCALL check_opengl_errors(__LINE__);
#else
#define GLCALL ;
#endif

static inline void check_opengl_errors ( size_t line ) {
	while (GLenum error = glGetError()) {
		std::cout << "OpenGL Error: L:" << line << " : " << error << '\n';
	}
}

static unsigned int compile_shader ( unsigned int type, const std::string& source ) {
	unsigned int shader = glCreateShader(type); GLCALL;
	const char *src = source.c_str();
	glShaderSource(shader, 1, &src, nullptr); GLCALL;
	glCompileShader(shader); GLCALL;

	int result;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &result); GLCALL;
	if (result == GL_FALSE) {
		int length;
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length); GLCALL;
		char* message = (char*)alloca(length * sizeof(char));
		glGetShaderInfoLog(shader, length, &length, message); GLCALL;
		std::cout << "Shader Failed to Compile: " << '\n';
		std::cout << message << '\n';
	}

	return shader;
}

static unsigned int load_shader ( const std::string& vertexShader, const std::string& fragementShader ) {
	unsigned int program = glCreateProgram(); GLCALL;
	unsigned int vs = compile_shader(GL_VERTEX_SHADER, vertexShader);
	unsigned int fs = compile_shader(GL_FRAGMENT_SHADER, fragementShader);

	glAttachShader(program, vs); GLCALL;
	glAttachShader(program, fs); GLCALL;
	glLinkProgram(program); GLCALL;
	glValidateProgram(program); GLCALL;

	glDetachShader(program, vs); GLCALL;
	glDetachShader(program, fs); GLCALL;

	glDeleteShader(vs); GLCALL;
	glDeleteShader(fs); GLCALL;

	return program;
}

int main ( int argc, char const **argv ) {
	app_init();
	window_create("Cocoa Window", 640, 400);
	
	std::cout << "OpenGL Vendor: " << glGetString(GL_VENDOR) << '\n';
	std::cout << "OpenGL Renderer: " << glGetString(GL_RENDERER) << '\n';
	std::cout << "OpenGL Version: " << glGetString(GL_VERSION) << '\n';
	std::cout << "OpenGL Shading Language: " << glGetString(GL_SHADING_LANGUAGE_VERSION) << '\n';

	glEnable(GL_FRAMEBUFFER_SRGB); GLCALL;
	glEnable(GL_DEPTH_TEST); GLCALL;
	glEnable(GL_CULL_FACE); GLCALL;
	glCullFace(GL_BACK); GLCALL;

	glClearColor(0.1f, 0.1f, 0.15f, 1.0f); GLCALL;

	unsigned int shader = load_shader(
		R"(
			#version 330 core

			layout(location = 0) in vec4 position;
			layout(location = 1) in vec4 color;

			out vec4 vertColor;

			void main ()
			{
				gl_Position = position;
				vertColor = color;
			}
		)",
		R"(
			#version 330 core

			in vec4 vertColor;

			out vec4 color;

			void main ()
			{
				color = vertColor;
			}
		)"
	);

	glUseProgram(shader); GLCALL;

	float verts [] = {
		-0.5f, -0.5f, 	1.0f, 0.0f, 0.0f, 1.0f,
		0.5f, -0.5f, 	0.0f, 1.0f, 0.0f, 1.0f,
		0.0f, 0.5f, 	0.0f, 0.0f, 1.0f, 1.0f
	};

	unsigned int vao;
	glGenVertexArrays(1, &vao); GLCALL;
	glBindVertexArray(vao); GLCALL;

	unsigned int vbo;
	glGenBuffers(1, &vbo); GLCALL;
	glBindBuffer(GL_ARRAY_BUFFER, vbo); GLCALL;
	glBufferData(GL_ARRAY_BUFFER, sizeof(verts), verts, GL_STATIC_DRAW); GLCALL;

	glEnableVertexAttribArray(0); GLCALL;
	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(float)*6, 0); GLCALL;

	glEnableVertexAttribArray(1); GLCALL;
	glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, sizeof(float)*6, (void *)(sizeof(float)*2)); GLCALL;

	while (!window_get_is_closed()) {
		window_process_events();

		if (input_get_key_down(Key::K_SPACE)) {
			window_set_complete_fullscreen(!window_get_complete_fullscreen());
		}

		if (input_get_key_down(Key::K_F)) {
			window_set_fullscreen(!window_get_fullscreen());
		}

		if (input_get_key_down(Key::K_1)) {
			window_set_size(640, 480);
		}
		
		if (input_get_key_down(Key::K_2)) {
			window_set_size(1280, 720);
		}

		if (input_get_key_down(Key::K_C)) {
			window_close();
		}

		if (glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE) {
			glViewport(0, 0, window_get_width_hidpi(), window_get_height_hidpi()); GLCALL;
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); GLCALL;
			
			glDrawArrays(GL_TRIANGLES, 0, 3); GLCALL;
		}

		window_draw();
	}

	app_quit();

	return 0;
}