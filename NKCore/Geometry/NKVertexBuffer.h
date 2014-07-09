//*
//*  NODE KITTEN
//*

#import <Foundation/Foundation.h>

typedef struct NKPrimitiveArray{
    V3t vertex;
    V3t normal;
    V2t texCoord;
    C4t color;
} NKPrimitiveArray;

typedef struct NKRiggedStruct {
    V3t vertex;
    V3t normal;
    V3t texCoord;
    V3t tangent;
    V3t biNormal;
    F1t boneWeight;
} NKRiggedStuct;

typedef struct NKMaterial{
    V3t diffuse;
    V3t ambient;
    V3t specular;
    V3t emissive;
    F1t shininess;
    U1t texCount;
} NKMaterial;

typedef NS_ENUM(NSInteger, NKPrimitive) {
    NKPrimitiveNone,
    NKPrimitiveAxes,
    NKPrimitiveRect,
    NKPrimitiveCube,
    NKPrimitiveSphere,
    NKPrimitiveLODSphere,
    NKNumPrimitives
} NS_ENUM_AVAILABLE(10_9, 7_0);


typedef void (^GeometrySetupBlock)();
#define newGeometrySetupBlock (GeometrySetupBlock)^()

@class NKIndexBuffer;

@interface NKVertexBuffer : NSObject

{
    V3t *_vertices;
    V3t *normals;
    V3t *texCoords;
    C4t *_colors;
    V3t *tangents;
    V3t *biNormals;
    F1t *boneWeights;
    M16t *boneTransforms;
    
    U1t *indices;
    
    int verticesOffset;
    int normalsOffset;
    int texCoordsOffset;
    int colorsOffset;
    int tangentsOffset;
    int biNormalsOffset;
    int boneWeightsOffset;
    
    int stride;
    F1t *interlacedData;
    GeometrySetupBlock _geometrySetupBlock;

}

@property (nonatomic, strong) NKIndexBuffer *indexBuffer;
@property (nonatomic) V3t center;

- (id)initWithSize:(GLsizeiptr)size
       numberOfElements:(GLuint)numElements
              data:(const GLvoid *)data
             setup:(GeometrySetupBlock)geometrySetupBlock;

-(V3t*) vertices;
-(C4t*)colors;

-(void)setVertices:(V3t*)vertices;
-(void)setColors:(C4t *)colors;


-(instancetype)initWithVertexData:(const GLvoid *)data numberOfElements:(GLuint)numElements ofSize:(GLsizeiptr)size;

+(instancetype)loadObjNamed:(NSString*)name;
+(instancetype)pointSprite;
+(instancetype)defaultCube;
+(instancetype)defaultRect;
+(instancetype)sphereWithStacks:(GLint)stacks slices:(GLint)slices squash:(GLfloat)squash;
+(instancetype)lodSphere:(int)levels;
+(instancetype)cubeWithWidthSections:(int) resX height:(int)resY depth:(int) resZ;

+(instancetype)axes;

+(V6t)boundingSizeForVertexSet:(NSArray*)set;
-(V3t)normalizeForGroupWithSize:(F1t)unitSize groupBoundingBox:(V6t)box center:(bool)center;

// GL ALLOC BLOCKS
+(GeometrySetupBlock)riggedMeshSetupBlock;
+(GeometrySetupBlock)primitiveSetupBlock;

- (void)bufferData:(GLenum)bufferModeOrNull;
- (void)updateBuffer;
- (void)bind;
- (void)unbind;

@property (nonatomic) U1t numVertices;
@property (nonatomic) int* elementOffset;
@property (nonatomic) int* elementSize;
@property (nonatomic) V3t boundingBoxSize;


@end

@interface NKIndexBuffer : NSObject

@property (nonatomic) U1t numElements;

- (id)initWithLength:(U1t)length
                data:(const GLvoid *)data;

- (void)bind;
- (void)unbind;


@end
