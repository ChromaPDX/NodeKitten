//
//  NKTextureManager.h
//  nike3dField
//
//  Created by Chroma Developer on 3/27/14.
//
//

#import "NKPch.h"
@class NKNode;
@class NKTexture;

@interface NKTextureManager : NSObject
{
    NSMutableDictionary *textureCache;
    NSMutableDictionary *textureNodeMap;
    NSMutableDictionary *labelCache;
    dispatch_queue_t _textureThread;
    int videosPlaying;
#if TARGET_OS_IPHONE
    CVOpenGLESTextureCacheRef _videoTextureCache;
#else
    CVOpenGLTextureCacheRef _videoTextureCache;
#endif
}

+ (NKTextureManager *)sharedInstance;
+ (NSMutableDictionary*) textureCache;
+ (dispatch_queue_t) textureThread;

+ (void)addNode:(NKNode*)node forTexture:(NKTexture*)texture;
+ (void)removeNode:(NKNode*)node forTexture:(NKTexture*)texture;

+ (NSMutableDictionary*) labelCache;
+ (GLuint) defaultTextureLocation;

#if TARGET_OS_IPHONE
+(CVOpenGLESTextureCacheRef)videoTextureCache;
#else
+(CVOpenGLTextureCacheRef)videoTextureCache;
#endif

@property (nonatomic)     GLuint defaultTexture;

@end
