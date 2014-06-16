//
//  NKGLManager.h
//  NodeKittenIOS
//
//  Created by Leif Shackelford on 6/14/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NKGLManager : NSObject
{
    #if NK_USE_GLES
 
    #else
    
    #endif
    
}

#if NK_USE_GLES

@property (nonatomic) CVOpenGLESTextureCacheRef videoTextureCache;
@property (nonatomic, weak) EAGLContext *context;

#else
@property (nonatomic, weak) NSOpenGLContext *context;
@property (nonatomic, strong) NSOpenGLPixelFormat *pixelFormat;

@property (nonatomic) CVOpenGLTextureCacheRef videoTextureCache;

#endif

+ (NKGLManager *)sharedInstance;
+ (void)updateWithTimeSinceLast:(F1t) dt;

@end
