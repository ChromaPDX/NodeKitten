//
//  NKMeshNode.h
//  nike3dField
//
//  Created by Chroma Developer on 3/31/14.
//
//
#import "NKPch.h"

#import "NKNode.h"
//#import "NKTexture.h"
#import "NKVertexBuffer.h"

@class NKTexture;
@class NKByteColor;
//@class NKVertexBuffer;

static inline float cblend(F1t col, F1t bl){
    return ((col * bl) + (1. - bl));
}

@interface NKMeshNode : NKNode
{
    NKVertexBuffer *_vertexBuffer;
    NSMutableArray *_textures;
    NSMutableArray *_materials;
    M16t *boneOffsets;
    
    U1t _numTextures;
    NKPrimitive _primitiveType;
    GLenum _drawMode;
    
    U1t _numTris;
}

@property (nonatomic, strong) NSDictionary *animations;
@property (nonatomic) bool drawBoundingBox;


@property (nonatomic) float pointSize;
@property (nonatomic) float lineWidth;
@property (nonatomic) bool usesLOD;

-(NKVertexBuffer*)vertexBuffer;

-(instancetype)initWithObjNamed:(NSString *)name;
-(instancetype)initWithObjNamed:(NSString *)name withSize:(V3t)size normalize:(bool)normalize;
-(instancetype)initWithObjNamed:(NSString *)name withSize:(V3t)size normalize:(bool)normalize anchor:(bool)anchor;

-(instancetype)initWithPrimitive:(NKPrimitive)primitive texture:(NKTexture*)texture color:(NKByteColor *)color size:(V3t)size;
-(instancetype)initWithVertexBuffer:(NKVertexBuffer*)buffer drawMode:(GLenum)drawMode texture:(NKTexture*)texture color:(NKByteColor *)color size:(V3t)size;

-(void)setTexture:(NKTexture *)texture;
-(void)bindTextures;
-(void)setDrawMode:(GLenum)drawMode;

@end
