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
    
    if (![[NKTextureManager textureCache] objectForKey:name]) {
        NKVideoTexture *newTex = [[NKVideoTexture alloc] initWithVideoNamed:name];
        
        if (newTex){
            [[NKTextureManager textureCache] setObject:newTex forKey:name];
        }
    }
    
    return [[NKTextureManager textureCache] objectForKey:name];
    
}

-(instancetype)initWithVideoNamed:(NSString*)name {
    
    self = [super init];
    
    if (self) {
        
        self.name = name;
        
        self.textureMapStyle = NKTextureMapStyleRepeat;
        
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:nil];
        
        if (path) {
            
            NSURL *pathURL = [NSURL fileURLWithPath : path];

            _videoTextureCache = [NKTextureManager videoTextureCache];
            
            _player = [[AVPlayer alloc] init];
            
            [self setupPlaybackForURL:pathURL];
            
            self.videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:[self sourcePixelBufferAttributes]];
            
            _myVideoOutputQueue = [NKTextureManager textureThread];
            
            //dispatch_queue_create("myVideoOutputQueue", DISPATCH_QUEUE_SERIAL);
            
            [[self videoOutput] setDelegate:self queue:_myVideoOutputQueue];
            
            [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:AVPlayerItemStatusContext];
            
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
                        
						CGAffineTransform preferredTransform = [videoTrack preferredTransform];
						
						/*
                         The orientation of the camera while recording affects the orientation of the images received from an AVPlayerItemVideoOutput. Here we compute a rotation that is used to correctly orientate the video.
                         */
						//self.playerView.preferredRotation = -1 * atan2(preferredTransform.b, preferredTransform.a);
						
                        videoSize = CGSizeApplyAffineTransform([videoTrack naturalSize], preferredTransform);
                        
                        self.size = P2Make(videoSize.width, videoSize.height);
#if !TARGET_OS_IPHONE
                        bufferAttributes = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32RGBA), (NSString *)kCVPixelBufferWidthKey : @(videoSize.width), (NSString *)kCVPixelBufferHeightKey : @(videoSize.height), (NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{ } };
#endif
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

-(void)unload {
    [self stop];
    [[_player currentItem] removeOutput:self.videoOutput];
}

-(void)dealloc {
    if (_notificationToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:_notificationToken name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
        
        [self removeObserver:self forKeyPath:@"player.currentItem.status" context:AVPlayerItemStatusContext];
    }
    
    if (_timeObserver){
        [self removeTimeObserverFromPlayer];
    }
    
    NSLog(@"finished unloading");
}

-(void)play {
    if (playing) return;
    
    playing = true;

	if ([_player currentItem]) {
		[self addDidPlayToEndTimeNotificationForPlayerItem:[_player currentItem]];
	}
	[[self videoOutput] requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
    
	[_player play];
}

-(void)pause {
    if (!playing)   return;
    [_player pause];
}
-(void)stop {
    if (!playing)   return;
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

//- (void)addTimeObserverToPlayer
//{
//	/*
//	 Adds a time observer to the player to periodically refresh the time label to reflect current time.
//	 */
//    if (_timeObserver)
//        return;
//    /*
//     Use __weak reference to self to ensure that a strong reference cycle is not formed between the view controller, player and notification block.
//     */
//    __weak NKVideoTexture* weakSelf = self;
//    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 10) queue:dispatch_get_main_queue() usingBlock:
//                     ^(CMTime time) {
//                         [weakSelf syncTimeLabel];
//                     }];
//}

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

#if NK_LOG_CV
		if (!_videoTextureCache) {
			NSLog(@"No video texture cache");
			return;
		}
#endif
		
		[self cleanUpTextures];

        CVReturn err;
        
#if TARGET_OS_IPHONE
        int frameWidth = CVPixelBufferGetWidth(pixelBuffer);
		int frameHeight = CVPixelBufferGetHeight(pixelBuffer);

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
        err = CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, pixelBuffer, (__bridge CFDictionaryRef)(bufferAttributes), &_lumaTexture);
#endif
        
        #if NK_LOG_CV
		if (err) {
			NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
		}
#endif
        
        if (!target) {
#if TARGET_OS_IPHONE
            target = CVOpenGLESTextureGetTarget(_lumaTexture);
#else
            target = CVOpenGLTextureGetTarget(_lumaTexture);
#endif
        }
        
        glEnable(target);
        glActiveTexture(GL_TEXTURE0);
        
#if TARGET_OS_IPHONE
        glName = CVOpenGLESTextureGetName(_lumaTexture);
#else
        glName = CVOpenGLTextureGetName(_lumaTexture);
#endif
        
        glBindTexture(target, glName);
        
        glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
}

- (void)cleanUpTextures
{
	if (_lumaTexture) {
		CVOpenGLTextureRelease(_lumaTexture);
		_lumaTexture = NULL;
	}
    if  (_videoTextureCache){
#if TARGET_OS_IPHONE
        CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
#else
        CVOpenGLTextureCacheFlush(_videoTextureCache, 0);
#endif
    }
}

-(void)bind {
    CMTime outputItemTime = [[self videoOutput] itemTimeForHostTime:CACurrentMediaTime()];

	if ([[self videoOutput] hasNewPixelBufferForItemTime:outputItemTime]) {
		CVPixelBufferRef pixelBuffer = NULL;
		pixelBuffer = [[self videoOutput] copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
		[self loadTexturesFromPixelBuffer:pixelBuffer];
        CVPixelBufferRelease(pixelBuffer);
	}
    
    glEnable(target);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(target, glName);

}

@end