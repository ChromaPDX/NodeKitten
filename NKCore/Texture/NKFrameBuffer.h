//
//  NKFrameBuffer.h
//  NKNikeField
//
//  Created by Leif Shackelford on 5/7/14.
//  Copyright (c) 2014 Chroma Developer. All rights reserved.
//

#import "NKpch.h"

#define GetGLError()									\
{														\
GLenum err = glGetError();							\
while (err != GL_NO_ERROR) {						\
NSLog(@"GLError %s set in File:%s Line:%d\n",	\
GetGLErrorString(err),					\
__FILE__,								\
__LINE__);								\
err = glGetError();								\
}													\
}

#define glHasError()    (_glHasError(__PRETTY_FUNCTION__, __LINE__))
#ifdef DEBUG
# define glCheckAndClearErrorsIfDEBUG() glCheckAndClearErrors()
#else
# define glCheckAndClearErrorsIfDEBUG()
#endif

#define glCheckAndClearErrors() (_glCheckAndClearErrors(__PRETTY_FUNCTION__, __LINE__))

static inline const char * GetGLErrorString(GLenum error)
{
	const char *str;
	switch( error )
	{
		case GL_NO_ERROR:
			str = "GL_NO_ERROR";
			break;
		case GL_INVALID_ENUM:
			str = "GL_INVALID_ENUM";
			break;
		case GL_INVALID_VALUE:
			str = "GL_INVALID_VALUE";
			break;
		case GL_INVALID_OPERATION:
			str = "GL_INVALID_OPERATION";
			break;
#if defined __gl_h_ || defined __gl3_h_
		case GL_OUT_OF_MEMORY:
			str = "GL_OUT_OF_MEMORY";
			break;
		case GL_INVALID_FRAMEBUFFER_OPERATION:
			str = "GL_INVALID_FRAMEBUFFER_OPERATION";
			break;
#endif
#if defined __gl_h_
		case GL_STACK_OVERFLOW:
			str = "GL_STACK_OVERFLOW";
			break;
		case GL_STACK_UNDERFLOW:
			str = "GL_STACK_UNDERFLOW";
			break;
		case GL_TABLE_TOO_LARGE:
			str = "GL_TABLE_TOO_LARGE";
			break;
#endif
		default:
			str = "(ERROR: Unknown Error Enum)";
			break;
	}
	return str;
}

static inline void _glCheckAndClearErrors(const char *function, int line)
{
    GLenum error;
    while ((error = glGetError()) != GL_NO_ERROR)
    {
        NSLog(@"%s, line %d: Error, OpenGL error: %s", function, line, GetGLErrorString(error));
    }
}

static inline bool _glHasError(const char *function, int line)
{
    GLenum error;
    BOOL errors = NO;
    
    while ((error = glGetError()) != GL_NO_ERROR)
    {
        errors = YES;
        NSLog(@"%s, line %d: Error, OpenGL error: %s", function, line, GetGLErrorString(error));
    }
    
    return errors;
}

@class NKTexture;
@class NKByteColor;

@interface NKFrameBuffer : NSObject

@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) GLuint frameBuffer;
@property (nonatomic, readonly) GLuint renderBuffer;
@property (nonatomic, readonly) GLuint depthBuffer;

@property (nonatomic) GLint width;
@property (nonatomic) GLint height;

@property (nonatomic,strong) NKTexture *renderTexture;

#if NK_USE_GLES
- (id)initWithContext:(EAGLContext *)context layer:(id <EAGLDrawable>)layer;
#else
#endif

-(instancetype)initWithWidth:(GLuint)width height:(GLuint)height;

- (void)bind;
- (void)bind:(void(^)())drawingBlock;

- (void)unbind;
- (void)unload;
- (GLuint)bindTexture:(int)texLoc;
- (NKImage *)imageAtRect:(CGRect)cropRect;

- (NKByteColor*)colorAtPoint:(P2t)point;
- (void)pixelValuesInRect:(CGRect)cropRect buffer:(GLubyte *)pixelBuffer;

@end
