//
//  NKGLManager.m
//  NodeKittenIOS
//
//  Created by Leif Shackelford on 6/14/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//

#import "NodeKitten.h"

static NKGLManager *sharedObject = nil;

@implementation NKGLManager

-(instancetype)init {
    self = [super init];
    if (self) {
        NSLog(@"gl context manager loaded");
    }
    
    return self;
}

+ (NKGLManager *)sharedInstance
{
    static dispatch_once_t _singletonPredicate;
    
    dispatch_once(&_singletonPredicate, ^{
        sharedObject = [[super alloc] init];
    });
    
    return sharedObject;
}

#if TARGET_OS_IPHONE

-(void)setContext:(EAGLContext *)context {
    _context = context;
    if (context) {
        NSLog(@"loaded EAGL context: %@", context);
    }
}

#else

-(void)setContext:(NSOpenGLContext *)context {
    _context = context;
  
    if (context) {
        NSLog(@"loaded context: %@", context);
        [context makeCurrentContext];
//        _ciContext = [CIContext contextWithCGLContext:_context.CGLContextObj
//                                          pixelFormat:[[NKGLManager sharedInstance] pixelFormat].CGLPixelFormatObj
//                                           colorSpace:CGColorSpaceCreateDeviceRGB()
//                                              options:nil];
 //       _ciContext = [[CIContext alloc]init];
        
     //   NSLog(@"gl manager has valid GL Context");
    }
}

-(void)setPixelFormat:(NSOpenGLPixelFormat *)pixelFormat {
    _pixelFormat = pixelFormat;
    if (pixelFormat) {
        NSLog(@"gl manager has valid GL Pixel Format");
    }
}

#endif

+(CIContext*)ciContext {
    return [[NKGLManager sharedInstance] ciContext];
}

-(CIContext*)ciContext {
    if (!_ciContext) {
#if TARGET_OS_IPHONE
        _ciContext = [CIContext contextWithEAGLContext:_context];
#else
        NSLog(@"init CI Context");
        _ciContext = [CIContext contextWithCGLContext:_context.CGLContextObj
                                          pixelFormat:_pixelFormat.CGLPixelFormatObj
                                           colorSpace:nil
                                              options:nil];
//        _ciContext = [CIContext contextWithCGLContext:_context.CGLContextObj
//                                          pixelFormat:_pixelFormat.CGLPixelFormatObj
//                                              options:nil];
#endif
    }
    return _ciContext;
}

+ (void)updateWithTimeSinceLast:(F1t)dt {
    [[NKGLManager sharedInstance]updateWithTimeSinceLast:dt];
	// Periodic texture cache flush every frame
}

- (void)updateWithTimeSinceLast:(F1t)dt {
}

@end
