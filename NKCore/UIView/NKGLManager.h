//
//  NKGLManager.h
//  NodeKittenIOS
//
//  Created by Leif Shackelford on 6/14/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NKGLManager : NSObject

#if TARGET_OS_IPHONE
@property (nonatomic, weak) EAGLContext *context;
#else
@property (nonatomic, weak) NSOpenGLContext *context;
@property (nonatomic, strong) NSOpenGLPixelFormat *pixelFormat;
#endif

+ (NKGLManager *)sharedInstance;
+ (void)updateWithTimeSinceLast:(F1t) dt;

@end
