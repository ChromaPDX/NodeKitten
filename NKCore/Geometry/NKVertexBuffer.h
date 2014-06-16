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


typedef void (^GeometrySetupBlock)(GLuint size);
#define newGeometrySetupBlock (GeometrySetupBlock)^(GLuint size)

@class NKIndexBuffer;

@interface NKVertexBuffer : NSObject

@property (nonatomic, strong) NKIndexBuffer *indexBuffer;

- (id)initWithSize:(GLsizeiptr)size
       numberOfElements:(GLuint)numElements
              data:(const GLvoid *)data
             setup:(GeometrySetupBlock)geometrySetupBlock;

-(instancetype)initWithVertexData:(const GLvoid *)data ofSize:(GLsizeiptr)size;

+(instancetype)loadObjNamed:(NSString*)name;
+(instancetype)pointSprite;
+(instancetype)defaultCube;
+(instancetype)defaultRect;
+(instancetype)sphereWithStacks:(GLint)stacks slices:(GLint)slices squash:(GLfloat)squash;
+(instancetype)lodSphere:(int)levels;
+(instancetype)cubeWithWidthSections:(int) resX height:(int)resY depth:(int) resZ;

+(instancetype)axes;

// GL ALLOC BLOCKS
+(GeometrySetupBlock)riggedMeshSetupBlock;
+(GeometrySetupBlock)primitiveSetupBlock;

- (void)bind;
- (void)unbind;

@property (nonatomic) NSUInteger numberOfElements;
@property (nonatomic) int* elementOffset;
@property (nonatomic) int* elementSize;
@property (nonatomic) V3t boundingBoxSize;

@end

@interface NKIndexBuffer : NSObject

- (id)initWithSize:(GLsizeiptr)size
              data:(const GLvoid *)data;
- (void)bind;
- (void)unbind;


@end

static inline V3t normalizeVertices(V3t* vertices, int length, V3t size, bool center) {
    
    float minx = 1000000., maxx = -1000000.;
    float miny = 1000000., maxy = -1000000.;
    float minz = 1000000., maxz = -1000000.;
    
    V3t finalModelSize;
    
    for (int i = 0; i <length; i++){ // FIND LARGEST VALUE
        
        if (vertices[i].x < minx)
            minx = vertices[i].x;
        if (vertices[i].x > maxx)
            maxx = vertices[i].x;
        
        if (vertices[i].y < miny)
            miny = vertices[i].y;
        if (vertices[i].y > maxy)
            maxy = vertices[i].y;
        
        if (vertices[i].z < minz)
            minz = vertices[i].z;
        if (vertices[i].z > maxz)
            maxz = vertices[i].z;
        
    };
    
    float width = fabsf(maxx - minx);
    float height = fabsf(maxy - miny);
    float depth = fabsf(maxz - minz);
    
    NKLogV3(@"min", V3Make(minx, miny, minz));
    NKLogV3(@"max", V3Make(maxx, maxy, maxz));
    NKLogV3(@"center", V3Make((minx+maxx), (miny+maxy), (minz+maxz)));
    
    V3t modelSize = V3Make(width, height, depth);
    
    V3t modelInverse = V3Divide(V3MakeF(2.), modelSize);
    
    V3t modelNormalized = V3UnitRetainAspect(modelSize);
    
    finalModelSize = V3Multiply(size, modelNormalized);
    
    //                NKLogV3(@"obj size:", modelSize);
    //                NKLogV3(@"obj divisor:", modelInverse);
    //                NKLogV3(@"normalized size", modelNormalized);
    //                NKLogV3(@"normalized center", offsetNormalized);
    
    for (int p = 0; p < length; p++){
        
        if (center) {
            V3t offset = V3Make((minx+maxx), (miny+maxy), (minz+maxz));
            V3t offsetNormalized = V3Divide(offset, modelSize);
            vertices[p] = V3Subtract(V3Multiply(vertices[p], modelInverse),offsetNormalized);
        }
        else {
            vertices[p] = V3Multiply(vertices[p], modelInverse);
        }
    }
    
    return finalModelSize;
    
}
