//
//  NKTextureManager.m
//  nike3dField
//
//  Created by Chroma Developer on 3/27/14.
//
//

#import "NodeKitten.h"

@implementation NKTextureManager

static NKTextureManager *sharedObject = nil;

-(instancetype)init {
    self = [super init];
    if (self) {
        textureCache = [NSMutableDictionary dictionary];
        textureNodeMap = [NSMutableDictionary dictionary];
        labelCache = [NSMutableDictionary dictionary];
        _textureThread = dispatch_queue_create("TEX_BG_THREAD", DISPATCH_QUEUE_SERIAL);
        _defaultTexture = -1;
        
        NSLog(@"texture manager loaded");
    }
    
    return self;
}

+ (NKTextureManager *)sharedInstance
{
    static dispatch_once_t _singletonPredicate;
    
    dispatch_once(&_singletonPredicate, ^{
        sharedObject = [[super alloc] init];
    });
    
    return sharedObject;
}

+(NSMutableDictionary*)textureCache {
    return [[NKTextureManager sharedInstance] textureCache];
}


-(NSMutableDictionary*)textureCache {
    return textureCache;
}

+ (dispatch_queue_t) textureThread {
    return [[NKTextureManager sharedInstance] textureThread];
}

- (dispatch_queue_t) textureThread {
    return _textureThread;
}

+(void)addNode:(NKNode *)node forTexture:(NKTexture *)texture {
    [[NKTextureManager sharedInstance] addNode:node forTexture:texture];
}

-(void)addNode:(NKNode *)node forTexture:(NKTexture *)texture {
    if (texture.name) {
        
        NSMutableSet* nodes;
        
        if (![textureCache objectForKey:texture.name]) {
            [textureCache setObject:texture forKey:texture.name];
        }
        if ([textureNodeMap objectForKey:texture.name]) {
            nodes = [textureNodeMap objectForKey:texture.name];
            [nodes addObject:node];
        }
        else {
            nodes = [[NSMutableSet alloc]init];
            [nodes addObject:node];
            [textureNodeMap setObject:nodes forKey:texture.name];
            
            if ([texture isKindOfClass:[NKVideoTexture class]]) {
                [(NKVideoTexture*)texture play];
            }
#if NK_LOG_CV
            NSLog(@"TEXTURE_MANAGER: add texture to cache: %@ totalCached: %lu", texture.name, (unsigned long)textureCache.allKeys.count);
#endif
        }
    }
   // NSLog(@"TEXTURE_MANAGER: add node for: %@ count : %lu", texture.name, (unsigned long)nodes.count);
}

+(void)removeNode:(NKNode *)node forTexture:(NKTexture *)texture {
     [[NKTextureManager sharedInstance] removeNode:node forTexture:texture];
}

-(void)removeNode:(NKNode *)node forTexture:(NKTexture *)texture {

    if ([textureNodeMap objectForKey:texture.name]) {
        NSMutableSet* nodes = [textureNodeMap objectForKey:texture.name];
        [nodes removeObject:node];
         //NSLog(@"TEXTURE_MANAGER: remove node for: %@ count : %lu", texture.name, (unsigned long)nodes.count);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!nodes.count) {
                
                if ([texture isKindOfClass:[NKVideoTexture class]]) {
                    [(NKVideoTexture*)texture unload];
                }

                [textureNodeMap removeObjectForKey:texture.name];
                [textureCache removeObjectForKey:texture.name];
                
#if NK_LOG_CV
            NSLog(@"TEXTURE_MANAGER: remove texture from cache: %@ totalCached: %lu", texture.name, (unsigned long)textureCache.allKeys.count);
#endif
            }
        });
        
    }
}

+(NSMutableDictionary*)labelCache {
    return [[NKTextureManager sharedInstance] labelCache];
}


-(NSMutableDictionary*)labelCache {
    return labelCache;
}

+(GLuint)defaultTextureLocation {
    return [[NKTextureManager sharedInstance] defaultTextureLocation];
}

-(GLuint)defaultTextureLocation{
    if (_defaultTexture == -1) {
        NKTexture *defaultTex = [NKTexture blankTexture];
        _defaultTexture = [defaultTex glName];
        NSLog(@"blank tex loc: %d",_defaultTexture);
    }
    return _defaultTexture;
}

#pragma mark - Video Textures

#if TARGET_OS_IPHONE
+(CVOpenGLESTextureCacheRef)videoTextureCache {
    return [[NKTextureManager sharedInstance] videoTextureCache];
}
-(CVOpenGLESTextureCacheRef)videoTextureCache {
    
    if (!_videoTextureCache) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [[NKGLManager sharedInstance] context], NULL, &_videoTextureCache);
        
        if (err != noErr) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
            return Nil;
        }
        else {
            
            NSAssert(_videoTextureCache, @"something went wrong");
            NSLog(@"created CVGLTextureCache successfully");
        }
        
    }
    
    return _videoTextureCache;
}
#else

+(CVOpenGLTextureCacheRef)videoTextureCache {
    return [[NKTextureManager sharedInstance] videoTextureCache];
}

-(CVOpenGLTextureCacheRef)videoTextureCache {
    
        CVReturn err = CVOpenGLTextureCacheCreate(kCFAllocatorDefault, NULL,
                                                  [[[NKGLManager sharedInstance] context] CGLContextObj],
                                                  [[[NKGLManager sharedInstance] pixelFormat] CGLPixelFormatObj],
                                                  NULL,
                                                  &_videoTextureCache);
        if (err != noErr) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
            return Nil;
        }
        else {
            
            NSAssert(_videoTextureCache, @"something went wrong");
            NSLog(@"created CVGLTextureCache successfully");
        }

    return _videoTextureCache;
}
#endif

-(void)dealloc {
    [textureCache removeAllObjects];
    [textureNodeMap removeAllObjects];
    CFRelease(_videoTextureCache);
}

@end
