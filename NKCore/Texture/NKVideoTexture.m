//
//  NKVideoTexture.m
//  NodeKittenIOS
//
//  Created by Leif Shackelford on 6/21/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//



#import "NodeKitten.h"

@implementation NKVideoTexture

+(instancetype) textureWithImageNamed:(NSString *)name {
    return [NKVideoTexture textureWithVideoNamed:name];
}
+(instancetype) textureWithVideoNamed:(NSString*)name {
    
    if  (!name) return nil;
    
    if (![[NKTextureManager imageCache] objectForKey:name]) {
        NKVideoTexture *newTex = [[NKVideoTexture alloc] initWithVideoNamed:name];
        
        if (newTex){
            NSLog(@"adding video texture to cache named:%@", name);
            [[NKTextureManager imageCache] setObject:newTex forKey:name];
        }
        else {
            return nil;
        }
    }
    
    return [[NKTextureManager imageCache] objectForKey:name];
    
}

-(instancetype)initWithVideoNamed:(NSString*)name {
    
    self = [super init];
    
    if (self) {
        
        self.textureMapStyle = NKTextureMapStyleRepeat;
        
        NKImage* request = [NKImage imageNamed:name];
        
        if (!request) {
            request = [NKImage imageNamed:@"chromeKittenSmall.png"];
            //NSLog(@"can't load tex, , using default");
        }
        
        NSAssert(request != nil, @"MISSING DEFAULT TEX IMAGE OR SOMETHING ELSE BROKE !!");
        
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:nil];
        if (path) {
            NSURL *pathURL = [NSURL fileURLWithPath : path];
            
            // Create CVOpenGLESTextureCacheRef for optimal CVPixelBufferRef to GLES texture conversion.
            if (!_videoTextureCache) {
#if NK_USE_GLES
                CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [[NKGLManager sharedInstance] context], NULL, &_videoTextureCache);
#else
                CVReturn err = CVOpenGLTextureCacheCreate(kCFAllocatorDefault, NULL,
                                                          [[[NKGLManager sharedInstance] context] CGLContextObj],
                                                          [[[NKGLManager sharedInstance] pixelFormat] CGLPixelFormatObj],
                                                          NULL,
                                                          &_videoTextureCache);
#endif
                if (err != noErr) {
                    NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
                    return Nil;
                }
                else {
                    NSLog(@"created CVGLTextureCache successfully");
                }
            }
            //_videoTextureCache = [[NKGLManager sharedInstance] videoTextureCache];
            
            _player = [[AVPlayer alloc] init];
            
            [self setupPlaybackForURL:pathURL];
            
            self.videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:[self sourcePixelBufferAttributes]];
            
            _myVideoOutputQueue = dispatch_queue_create("myVideoOutputQueue", DISPATCH_QUEUE_SERIAL);
            
            [[self videoOutput] setDelegate:self queue:_myVideoOutputQueue];
            
            [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:AVPlayerItemStatusContext];
            [self addTimeObserverToPlayer];
            
            [_player play];
        }
        else {
            NSLog(@"NKVideoNode bad file name, %@", name);
        }
        
        
        
    }
    
    return self;
}

- (void)setupPlaybackForURL:(NSURL *)URL
{
	/*
	 Sets up player item and adds video output to it.
	 The tracks property of an asset is loaded via asynchronous key value loading, to access the preferred transform of a video track used to orientate the video while rendering.
	 After adding the video output, we request a notification of media change in order to restart the CADisplayLink.
	 */
	
	// Remove video output from old item, if any.
	[[_player currentItem] removeOutput:self.videoOutput];
    
	AVPlayerItem *item = [AVPlayerItem playerItemWithURL:URL];
	AVAsset *asset = [item asset];
	
	[asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
        
		if ([asset statusOfValueForKey:@"tracks" error:nil] == AVKeyValueStatusLoaded) {
			NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
			if ([tracks count] > 0) {
				// Choose the first video track.
				AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
				[videoTrack loadValuesAsynchronouslyForKeys:@[@"preferredTransform"] completionHandler:^{
					
					if ([videoTrack statusOfValueForKey:@"preferredTransform" error:nil] == AVKeyValueStatusLoaded) {
						//CGAffineTransform preferredTransform = [videoTrack preferredTransform];
						
						/*
                         The orientation of the camera while recording affects the orientation of the images received from an AVPlayerItemVideoOutput. Here we compute a rotation that is used to correctly orientate the video.
                         */
						//self.playerView.preferredRotation = -1 * atan2(preferredTransform.b, preferredTransform.a);
						
                        videoSize = [videoTrack naturalSize];
                        
                        self.size = P2Make(videoSize.width, videoSize.height);
                        
                        NSLog(@"loaded video with size: %f x %f", self.size.width, self.size.height);
                        
                        self.shouldResizeToTexture = false;
                        
						[self addDidPlayToEndTimeNotificationForPlayerItem:item];
						
						dispatch_async(dispatch_get_main_queue(), ^{
							[item addOutput:self.videoOutput];
							[_player replaceCurrentItemWithPlayerItem:item];
							[self.videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
						});
						
					}
					
				}];
			}
		}
		
	}];
	
}

-(void)dealloc {
      [self stop];
    
    [self removeObserver:self forKeyPath:@"player.currentItem.status" context:AVPlayerItemStatusContext];
    [self removeTimeObserverFromPlayer];
    
    if (_notificationToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:_notificationToken name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
        _notificationToken = nil;
    }
    
  
    
    [self cleanUpTextures];
	
	if(_videoTextureCache) {
		CFRelease(_videoTextureCache);
	}
}


-(void)play {
    // Make sure our playback is resumed from any interruption.
	if ([_player currentItem]) {
		[self addDidPlayToEndTimeNotificationForPlayerItem:[_player currentItem]];
	}
	[[self videoOutput] requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
    
	[_player play];
}

-(void)stop {
    [_player pause];
}

#pragma mark - NOTIFICATIONS


- (void)stopLoadingAnimationAndHandleError:(NSError *)error
{
	if (error) {
        //       NSString *cancelButtonTitle = NSLocalizedString(@"OK", @"Cancel button title for animation load error");
        //		NKAlertSprite* alert = [[UIAlertView alloc] initWithTitle:[error localizedDescription] message:[error localizedFailureReason] delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
        //		[alertView show];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == AVPlayerItemStatusContext) {
		AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
		switch (status) {
			case AVPlayerItemStatusUnknown:
				break;
			case AVPlayerItemStatusReadyToPlay:
                //NSLog(@"video player is ready");
				//self.playerView.presentationRect = [[_player currentItem] presentationSize];
				break;
			case AVPlayerItemStatusFailed:
				[self stopLoadingAnimationAndHandleError:[[_player currentItem] error]];
				break;
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)addDidPlayToEndTimeNotificationForPlayerItem:(AVPlayerItem *)item
{
	if (_notificationToken)
		_notificationToken = nil;
	
	/*
     Setting actionAtItemEnd to None prevents the movie from getting paused at item end. A very simplistic, and not gapless, looped playback.
     */
	_player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
	_notificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:item queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		// Simple item playback rewind.
		[[_player currentItem] seekToTime:kCMTimeZero];
	}];
}

- (void)addTimeObserverToPlayer
{
	/*
	 Adds a time observer to the player to periodically refresh the time label to reflect current time.
	 */
    if (_timeObserver)
        return;
    /*
     Use __weak reference to self to ensure that a strong reference cycle is not formed between the view controller, player and notification block.
     */
    __weak NKVideoTexture* weakSelf = self;
    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 10) queue:dispatch_get_main_queue() usingBlock:
                     ^(CMTime time) {
                         [weakSelf syncTimeLabel];
                     }];
}

- (void)syncTimeLabel
{
	double seconds = CMTimeGetSeconds([_player currentTime]);
	if (!isfinite(seconds)) {
		seconds = 0;
	}
	
	int secondsInt = round(seconds);
	int minutes = secondsInt/60;
	secondsInt -= minutes*60;
	
    // TO DO, ADD TIME LABEL
    
	//self.currentTime.textColor = [NKColor colorWithWhite:1.0 alpha:1.0];
	//self.currentTime.textAlignment = NSTextAlignmentCenter;
    
	//self.currentTime.text = [NSString stringWithFormat:@"%.2i:%.2i", minutes, secondsInt];
}

- (void)removeTimeObserverFromPlayer
{
    if (_timeObserver)
    {
        [_player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
}

#pragma mark - OpenGL drawing

- (NSDictionary *)sourcePixelBufferAttributes
{
	return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
			  (NSString *)kCVPixelBufferOpenGLCompatibilityKey : [NSNumber numberWithBool:YES],
			  (NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{}};
}


- (void)loadTexturesFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
	CVReturn err;
    
	if (pixelBuffer != NULL) {
        
        // CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        
		if (!_videoTextureCache) {
			NSLog(@"No video texture cache");
			return;
		}
		
		[self cleanUpTextures];
		
		/*
		 Use the color attachment of the pixel buffer to determine the appropriate color conversion matrix.
		 */
        //		CFTypeRef colorAttachments = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
        //
        //		if (colorAttachments == kCVImageBufferYCbCrMatrix_ITU_R_601_4) {
        //			_preferredConversion = kColorConversion601;
        //		}
        //		else {
        //			_preferredConversion = kColorConversion709;
        //		}
        
        
        int frameWidth = CVPixelBufferGetWidth(pixelBuffer);
		int frameHeight = CVPixelBufferGetHeight(pixelBuffer);
        
#if NK_USE_GLES
        
		err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
														   _videoTextureCache,
														   pixelBuffer,
														   NULL,
														   GL_TEXTURE_2D,
														   GL_RGBA,
														   frameWidth,
														   frameHeight,
														   GL_RGBA,
														   GL_UNSIGNED_BYTE,
														   0,
														   &_lumaTexture);
#else
        NSDictionary *bufferAttributes = @{ (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32RGBA), (__bridge NSString *)kCVPixelBufferWidthKey : @(frameWidth), (__bridge NSString *)kCVPixelBufferHeightKey : @(frameHeight), (__bridge NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{ } };
        
        err = CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, pixelBuffer, (__bridge CFDictionaryRef)(bufferAttributes), &_lumaTexture);
#endif
		if (err) {
			NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
		}
        
        //		// UV-plane.
        //        //glEnable(GL_TEXTURE_2D);
        //
        //
        //#if NK_USE_GLES
        //		err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
        //														   _videoTextureCache,
        //														   pixelBuffer,
        //														   NULL,
        //														   GL_TEXTURE_2D,
        //														   GL_RG_EXT,
        //														   frameWidth / 2,
        //														   frameHeight / 2,
        //														   GL_RG_EXT,
        //														   GL_UNSIGNED_BYTE,
        //														   1,
        //														   &_chromaTexture);
        //#else
        //
        //        err = CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
        //                                                         _videoTextureCache,
        //                                                         pixelBuffer,
        //                                                         NULL,
        //                                                         &_chromaTexture);
        //#endif
        //
        //		if (err) {
        //			NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        //		}
        //
        //#if NK_USE_GLES
        //		glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
        //#else
        //        glBindTexture(CVOpenGLTextureGetTarget(_chromaTexture), CVOpenGLTextureGetName(_chromaTexture));
        //#endif
        //
        //
        //		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        //		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        //		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        //		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        //
		//CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        
		CFRelease(pixelBuffer);
	}
	
    //    glUniform1i(uniforms[UNIFORM_Y], 0);
    //	glUniform1i(uniforms[UNIFORM_UV], 1);
    //	glUniform1f(uniforms[UNIFORM_LUMA_THRESHOLD], self.lumaThreshold);
    //	glUniform1f(uniforms[UNIFORM_CHROMA_THRESHOLD], self.chromaThreshold);
    //	glUniform1f(uniforms[UNIFORM_ROTATION_ANGLE], self.preferredRotation);
    //	glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, _preferredConversion);
    
}

- (void)cleanUpTextures
{
	if (_lumaTexture) {
		CFRelease(_lumaTexture);
		_lumaTexture = NULL;
	}
	
	if (_chromaTexture) {
		CFRelease(_chromaTexture);
		_chromaTexture = NULL;
	}
	
	// Periodic texture cache flush every frame
#if NK_USE_GLES
	CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
#else
    CVOpenGLTextureCacheFlush(_videoTextureCache, 0);
#endif
}

-(void)bind {
    GLenum texTarget;
    
    CMTime outputItemTime = kCMTimeInvalid;
    
    CFTimeInterval nextVSync = CACurrentMediaTime();
    
	outputItemTime = [[self videoOutput] itemTimeForHostTime:nextVSync];
	
	if ([[self videoOutput] hasNewPixelBufferForItemTime:outputItemTime]) {
		CVPixelBufferRef pixelBuffer = NULL;
		pixelBuffer = [[self videoOutput] copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
		[self loadTexturesFromPixelBuffer:pixelBuffer];
        //NSLog(@"new vid frame");
	}
    
    #if NK_USE_GLES
    texTarget = CVOpenGLESTextureGetTarget(_lumaTexture);
    glEnable(texTarget);
    glActiveTexture(GL_TEXTURE0);
    texture = CVOpenGLESTextureGetName(texture);
    glBindTexture(texTarget, texture);
    #else
    
    texTarget = CVOpenGLTextureGetTarget(_lumaTexture);
    glEnable(texTarget);
    // BIND EXISTING TEXTURES
    glActiveTexture(GL_TEXTURE0);
    texture = CVOpenGLTextureGetName(_lumaTexture);
    glBindTexture(texTarget, texture);
    //NSLog(@"texTarget %d",texTarget);
    
#endif
    
    glTexParameteri(texTarget, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(texTarget, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(texTarget, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(texTarget, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
}



@end
