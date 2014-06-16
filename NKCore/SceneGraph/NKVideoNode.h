//
//  NKVideoNode.h
//  NodeKittenIOS
//
//  Created by Leif Shackelford on 6/14/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//

#import "NKSpriteNode.h"

#import <CoreVideo/CoreVideo.h>
#import <AVFoundation/AVFoundation.h>

# define ONE_FRAME_DURATION 0.03
# define LUMA_SLIDER_TAG 0
# define CHROMA_SLIDER_TAG 1

static void *AVPlayerItemStatusContext = &AVPlayerItemStatusContext;

@interface NKVideoNode : NKSpriteNode
{
    AVPlayer *_player;
	dispatch_queue_t _myVideoOutputQueue;
	id _notificationToken;
    id _timeObserver;
    
   	// The pixel dimensions of the CAEAGLLayer.
	GLint _backingWidth;
	GLint _backingHeight;
    
#if NK_USE_GLES
	CVOpenGLESTextureRef _lumaTexture;
	CVOpenGLESTextureRef _chromaTexture;
	CVOpenGLESTextureCacheRef _videoTextureCache;
#else
    CVOpenGLTextureRef _lumaTexture;
    CVOpenGLTextureRef _chromaTexture;
	CVOpenGLTextureCacheRef _videoTextureCache;
//    CVOpenGLBufferRef _buffer;
//    CVPixelBufferPoolRef pool;
#endif
	
    CGSize videoSize;
    CMTime videoDuration;
    
	GLuint _frameBufferHandle;
	GLuint _colorBufferHandle;
	
	const GLfloat *_preferredConversion;
}

@property AVPlayerItemVideoOutput *videoOutput;

@property GLfloat preferredRotation;
@property CGSize presentationRect;
@property GLfloat chromaThreshold;
@property GLfloat lumaThreshold;

-(instancetype)initWithVideoNamed:(NSString*)name size:(V3t)size;

- (void)setupBuffers;
- (void)cleanUpTextures;

@end
