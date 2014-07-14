//*
//*  NODE KITTEN
//*
#import "NKPch.h"
#import "NKVertexBuffer.h"

@class NKMeshNode;

@interface NKStaticDraw : NSObject
{
    NSMutableDictionary *meshesCache;
    NSMutableDictionary *vertexCache;
    NKVertexBuffer *primitiveCache[NKNumPrimitives];
}

+ (NKStaticDraw *)sharedInstance;
+ (NSMutableDictionary*) meshesCache;
+ (NSMutableDictionary*) vertexCache;
+ (NSMutableDictionary*) normalsCache;

+(NKVertexBuffer*)cachedPrimitive:(NKPrimitive)primitive;

+(NSString*)stringForPrimitive:(NKPrimitive)primitive;

+(NKMeshNode*)fboSurface;

@property (nonatomic, strong) NKMeshNode* boundingBoxMesh;
@property (nonatomic, strong) NKMeshNode* fboSurface;

@end

@interface NKColor(OpenGL)
- (void)setOpenGLColor;
- (void)setColorArrayToColor:(NKColor *)toColor;
@end