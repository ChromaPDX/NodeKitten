//
//  NKVideoTexture.h
//  NodeKittenIOS
//
//  Created by Leif Shackelford on 6/21/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//

#import "NKTexture.h"
#import <CoreVideo/CoreVideo.h>
#import <AVFoundation/AVFoundation.h>

# define ONE_FRAME_DURATION 0.03
# define LUMA_SLIDER_TAG 0
# define CHROMA_SLIDER_TAG 1

static void *AVPlayerItemStatusContext = &AVPlayerItemStatusContext;

@interface NKVideoTexture : NKTexture <AVPlayerItemOutputPullDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVPlayer *_player;
    AVCaptureSession * _session;
	dispatch_queue_t _myVideoOutputQueue;
	id _notificationToken;
    id _timeObserver;
    
   	// The pixel dimensions of the CAEAGLLayer.
	GLint _backingWidth;
	GLint _backingHeight;
    
#if TARGET_OS_IPHONE
	CVOpenGLESTextureRef _lumaTexture;
	CVOpenGLESTextureRef _chromaTexture;
    CVOpenGLESTextureCacheRef _videoTextureCache;

#else
    NSDictionary *bufferAttributes;
    CVOpenGLTextureRef _lumaTexture;
    CVOpenGLTextureRef _chromaTexture;
    CVOpenGLTextureCacheRef _videoTextureCache;
#endif
    CGSize videoSize;
    CMTime videoDuration;
    
	GLuint _frameBufferHandle;
	GLuint _colorBufferHandle;
	
	const GLfloat *_preferredConversion;
    
    bool playing;
    bool isCameraSource;
}

+(instancetype) textureWithVideoNamed:(NSString*)name;
+(instancetype) textureWithCameraSource:(id)source;

@property AVPlayerItemVideoOutput *videoOutput;

@property GLfloat preferredRotation;
@property CGSize presentationRect;
@property GLfloat chromaThreshold;
@property GLfloat lumaThreshold;

-(void)play;
-(void)pause;

@end
