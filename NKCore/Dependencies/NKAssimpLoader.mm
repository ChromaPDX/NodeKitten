//
//  NKAssimpLoader.m
//  NodeKittenIOS
//
//  Created by Leif Shackelford on 6/13/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//

#include "assimp/include/assimp/cimport.h"
#include "assimp/include/assimp/scene.h"
#include "assimp/include/assimp/material.h"
#include "assimp/include/assimp/anim.h"
#include "assimp/include/assimp/postprocess.h"

#import "NKAssimpLoader.h"
#import "NodeKitten.h"

@class AIMaterial;
struct aiMesh;

@interface NKMeshNode (ASSIMP)

-(instancetype)initWithAIAsset:(const aiMesh *)asset
                      material:(AIMaterial *)theMaterial;

@end

@interface AIMaterial : NSObject

@property (nonatomic, strong) NKTexture *tex;
@property (nonatomic, strong) NKTexture *bump;

+(instancetype)materialWithAsset:(aiMaterial*)asset;

@end


@interface AIAnimationNode : NSObject {
    aiNodeAnim data;
}

- (id) initWithAsset:(const aiNodeAnim *)asset;

@end


@interface AIAnimation : NSObject {
    double duration;
}


@property (nonatomic, strong) NSArray *channels;

+ (id) animationWithAsset:(const aiAnimation *)asset;
- (id) initWithAsset:(const aiAnimation *)asset;

@end

@interface NSString (AIString)

+ (id) stringWithAIString:(aiString *)aString;
- (id) initWithAIString:(aiString *)aString;

@end

@implementation AIScene

+ (id) sceneFromFile:(NSString *)file
{
    return [[self alloc] initFromFile:file];
}

- (id) initFromFile:(NSString *)file
{
    if (self = [super init])
    {
        NSString *filename = [file lastPathComponent];
        NSString *scenePath = [[NSBundle mainBundle] pathForResource:filename
                                                              ofType:@""];
        
        const aiScene *scene = aiImportFile([scenePath cStringUsingEncoding:NSUTF8StringEncoding], aiProcessPreset_TargetRealtime_Quality);
        if (!scene)
        {
            NSLog(@"Could not load scene from path: %@", scenePath);
            self = nil;
        }
        else if (![self loadScene:scene])
        {
            NSLog(@"Could not create data structure for scene %@", filename);
            self = nil;
        }
        else {
            NSLog(@"AI scene loaded with:");
            
        }
        
        if (scene)
            aiReleaseImport(scene);
    }
    return self;
}


- (BOOL) loadScene:(const aiScene *)scene
{

    NSLog(@"%d meshes, %d materials, %d animations, %d textures, %d lights, %d cameras", scene->mNumMeshes, scene->mNumMaterials, scene->mNumAnimations, scene->mNumTextures, scene->mNumLights, scene->mNumCameras);
    
   // NSLog(@"loading materials");
    
    NSMutableArray* newMaterials = [NSMutableArray arrayWithCapacity:scene->mNumMaterials];
    for (int i = 0; i < scene->mNumMaterials; ++i)
    {
        [newMaterials addObject:[AIMaterial materialWithAsset:scene->mMaterials[i]]];
    }
    
    NSLog(@"loading meshes");
    
    NSMutableArray* newMeshes = [NSMutableArray arrayWithCapacity:scene->mNumMeshes];
    
    NKMeshNode *rootNode;
    
    for (int i = 0; i < scene->mNumMeshes; ++i)
    {
        aiMesh *sceneMesh = scene->mMeshes[i];
        
        if (![[NSString stringWithAIString:&sceneMesh->mName] isEqualToString:@""]) {
            NSLog(@"scene model named: %@",[NSString stringWithAIString:&sceneMesh->mName]);
        }
        
        
        AIMaterial *material = [newMaterials objectAtIndex:(sceneMesh->mMaterialIndex)];
        
        if(!material && newMaterials.count){
            NSLog(@"no listed material for mesh, using default");
            material = newMaterials[0];
        }
        
        NKMeshNode *mesh = [[NKMeshNode alloc]initWithAIAsset:sceneMesh
                                material:material];
        
        if (i==0) {
            rootNode = mesh;
        }
        [newMeshes addObject:mesh];
    }
    
    _materials = newMaterials;
    _meshes = newMeshes;
    
    NSLog(@"loading animations");
    
    NSMutableDictionary* newAnimations = [NSMutableDictionary dictionaryWithCapacity:scene->mNumAnimations];
    
    for (int i = 0; i < scene->mNumAnimations; ++i)
    {
        aiAnimation *animation = scene->mAnimations[i];
        
        NSString* key = [NSString stringWithAIString:&animation->mName];
        if ([key isEqualToString:@""]) {
            key = [NSString stringWithFormat:@"%d", i];
        }
        [newAnimations setObject:[AIAnimation animationWithAsset:animation]
                          forKey:key];
        NSLog(@"adding animation for key : %@",key);
    }
    _animations = newAnimations;
    
    rootNode.animations = newAnimations;
    
    
    return YES;
}

@end



//- (GLuint) texture:(int)num
//            ofType:(aiTextureType)type
//         fromAsset:(const aiMaterial *)asset
//{
//    aiTextureMapMode mapMode;
//    aiString *texturePathTmp = new aiString();
//    asset->GetTexture(type, num, texturePathTmp, NULL, NULL, NULL, NULL, &mapMode);
//    
//    NSString *texturePath = [NSString stringWithAIString:texturePathTmp];
//    delete texturePathTmp;
//    
//    GLuint textureId;
//    glGenTextures(1, &textureId);
//    glBindTexture(GL_TEXTURE_2D, textureId);
//    
//    if (!glHasError() && [self loadTexture:texturePath])
//    {
//        NSLog(@"loading texture %@",texturePath);
//        
//        if (mapMode == aiTextureMapMode_Wrap)
//        {
//            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
//            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
//        }
//        else if (mapMode == aiTextureMapMode_Clamp)
//        {
//            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
//            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
//        }
//        else
//        {
//            NSLog(@"Unsupported texturemapmode for %@: %i", texturePath, mapMode);
//        }
//    }
//    else
//    {
//        NSLog(@"Failed loading texture '%@'!", texturePath);
//        glDeleteTextures(1, &textureId);
//        textureId = 0;
//    }
//    
//    return textureId;
//}

//- (BOOL) loadTexture:(NSString *)path
//{
//
//    glCheckAndClearErrors();
//    
//    NSString *filename = [path lastPathComponent];
//    NSString *texturePath = [[NSBundle mainBundle] pathForResource:filename
//                                                            ofType:@""];
//    
//    NSImage *image = [[NSImage alloc] initWithContentsOfFile:texturePath];
//    if (!image)
//    {
//        return NO;
//    }
//    
//    NSRect imageRect;
//    imageRect.origin = NSZeroPoint;
//    imageRect.size = [image size];
//    
//    [image lockFocus];
//    [image setFlipped:YES];
//    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:imageRect];
//    [image unlockFocus];
//    
//    if (!imageRep)
//    {
//        return NO;
//    }
//    
//    int bytesPerRow = [imageRep bytesPerRow];
//    int bitsPerPixel = [imageRep bitsPerPixel];
//    BOOL hasAlpha = [imageRep hasAlpha];
//    
//    GLenum format = hasAlpha ? GL_RGBA : GL_RGB;
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
//    glCheckAndClearErrors();
//    
//    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
//    glPixelStorei(GL_UNPACK_ROW_LENGTH, bytesPerRow / (bitsPerPixel >> 3));
//    glCheckAndClearErrors();
//    
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageRect.size.width,
//                 imageRect.size.height, 0, format, GL_UNSIGNED_BYTE,
//                 [imageRep bitmapData]);
//    
//    if (glHasError())
//    {
//        return NO;
//    }
//    
//    glGenerateMipmap(GL_TEXTURE_2D);
//    glCheckAndClearErrors();
//    
//    return YES;
//}

@implementation NSString (AIString)

+ (id) stringWithAIString:(aiString *)aString
{
    return [[self alloc] initWithAIString:aString];
}

- (id) initWithAIString:(aiString *)aString
{
    return [NSString stringWithUTF8String:aString->data];
    
    if (aString == NULL)
    {
        self = nil;
    }
    else
    {
        self = [self initWithBytes:aString->data
                            length:aString->length
                          encoding:NSUTF8StringEncoding];
    }
    
    return self;
}

@end

@implementation NKMeshNode (ASSIMP)

-(instancetype)initWithAIAsset:(const aiMesh *)asset
                      material:(AIMaterial *)theMaterial {
    
    
    V3t *vertices = NULL;
    V3t *normals = NULL;
    V3t *textureCoords = NULL;
    C4t *colors = NULL;
    V3t *tangents = NULL;
    V3t *binormals = NULL;
    F1t *boneWeights = NULL;
    U1t *indices = NULL;
    
    int numElements = asset->mNumVertices;
    
    NSLog(@"asset has %d unique vertices %d face vertices", numElements, asset->mNumFaces*3);
    
    // TODO: This is kinda unclean.
    assert(asset->mPrimitiveTypes == aiPrimitiveType_TRIANGLE);
    
    _numTris = asset->mNumFaces;
    
    indices = (U1t *)malloc(asset->mNumFaces * sizeof(unsigned int) * 3);
    int idx = 0;
    for (int i = 0; i < asset->mNumFaces; ++i)
    {
        aiFace &face = asset->mFaces[i];
        
        //assert(face.mNumIndices == 3);
        
        for (int j = 0; j < face.mNumIndices; ++j)
        {
            indices[idx++] = face.mIndices[j];
        }
    }
    
    // Set up vertex buffer
    vertices = (V3t*)malloc(sizeof(V3t) * numElements);
    memcpy(vertices, asset->mVertices, sizeof(V3t) * numElements);
    
    normalizeVertices(vertices, numElements, V3MakeF(1.),true);
    
    // Optionally set up color buffer.
    // TODO: Support more than 1 set of colors.
    if (asset->mColors[0])
    {
        colors = (V4t*)malloc(sizeof(C4t) * numElements);
        memcpy(colors, asset->mColors[0], sizeof(C4t) * numElements);
        
    }
    
    // Optionally set up the normal buffer.
    if (asset->mNormals)
    {
        normals = (V3t*)malloc(sizeof(V3t) * numElements);
        memcpy(normals, asset->mNormals, sizeof(V3t) * numElements);
    }
    
    // Optionally set up the first texture coord buffer.
    // TODO: Support more than 1 set of texcoords.
    if (asset->mTextureCoords[0])
    {
        textureCoords = (V3t*)malloc(sizeof(V3t) * numElements);
        memcpy(textureCoords, asset->mTextureCoords[0], sizeof(V3t) * numElements);
    }
    
    // Optionally set up bones!
    if (asset->HasBones())
    {
        if (asset->mNumBones) {
            NSLog(@"model has %d bones", asset->mNumBones);
            boneOffsets = (M16t*)malloc(sizeof(M16t) * asset->mNumBones);
            
            for (int i = 0; i < asset->mNumBones; ++i)
            {
                aiBone *bone = asset->mBones[i];
                
                memcpy(boneOffsets[i].m, &bone->mOffsetMatrix, sizeof(M16t));
                
                boneWeights = (float *)calloc(asset->mNumVertices, sizeof(float));
                for (int j = 0; j < bone->mNumWeights; ++j)
                {
                    aiVertexWeight &v = bone->mWeights[j];
                    boneWeights[v.mVertexId] = v.mWeight;
                }
            }
        }
    }
    
    //        int numberOfUnusedBones = MAX_NUMBER_OF_BONES - asset->mNumBones;
    //
    //        GLuint *firstUnusedBone = &(buffers[BUFFER_BONEWEIGHTS + asset->mNumBones]);
    //
    //        glDeleteBuffers(numberOfUnusedBones, firstUnusedBone);
    //        memset(firstUnusedBone, 0, numberOfUnusedBones * sizeof(GLuint));
    
    // Optionally set up the bitangent & tangent buffer.
    
    if (asset->HasTangentsAndBitangents())
    {
        tangents = (V3t*)malloc(sizeof(V3t) * numElements);
        memcpy(tangents, asset->mTangents, sizeof(V3t) * numElements);
        
        binormals = (V3t*)malloc(sizeof(V3t) * numElements);
        memcpy(binormals, asset->mBitangents, sizeof(V3t) * numElements);
        
    }
    
    NKRiggedStruct *elements = (NKRiggedStruct*)malloc(sizeof(NKRiggedStruct) * numElements);
    
    for (int i = 0; i < numElements; i++) {
        memcpy(&elements[i].vertex, &vertices[i], sizeof(V3t));
        memcpy(&elements[i].normal, &normals[i], sizeof(V3t));
        if (textureCoords)
        memcpy(&elements[i].texCoord, &textureCoords[i], sizeof(V3t));
        if (tangents)
            memcpy(&elements[i].tangent, &tangents[i], sizeof(V3t));
        if (binormals)
            memcpy(&elements[i].biNormal, &binormals[i], sizeof(V3t));
        if (boneWeights)
            memcpy(&elements[i].boneWeight, &boneWeights[i], sizeof(F1t));
    }
    
    free(vertices);
    free(normals);
    if (textureCoords)
        free(textureCoords);
    if(tangents)
        free(tangents);
    if(binormals)
        free(binormals);
    if(boneWeights)
        free(boneWeights);
    
    GLuint totalElements = MAX(numElements, asset->mNumFaces*3);
    
    NKVertexBuffer *vbo = [[NKVertexBuffer alloc]initWithSize:sizeof(NKRiggedStuct)*numElements numberOfElements:totalElements data:elements setup:[NKVertexBuffer riggedMeshSetupBlock]];
    
    free(elements);
    
    if (indices) {
        //NSLog(@"has index buffer");
        vbo.indexBuffer = [[NKIndexBuffer alloc]initWithSize:totalElements*sizeof(U1t) data:indices];
        free(indices);
    }
    
    self = [self initWithVertexBuffer:vbo drawMode:GL_TRIANGLES texture:theMaterial.tex color:NKWHITE size:V3MakeF(1.)];
    
    // DO TEXURES
    _drawMode = GL_TRIANGLES;
    self.cullFace = NKCullFaceNone;
    
    return self;
    
}


@end

@implementation AIAnimationNode

- (id) initWithNode:(const aiNodeAnim *)asset
{
    if (self = [super init])
    {
        data.mNumPositionKeys = asset->mNumPositionKeys;
        data.mPositionKeys = (aiVectorKey *)malloc(data.mNumPositionKeys * sizeof(aiVectorKey));
        memcpy(data.mPositionKeys, asset->mPositionKeys, data.mNumPositionKeys * sizeof(aiVectorKey));
        
        data.mNumRotationKeys = asset->mNumRotationKeys;
        data.mRotationKeys = (aiQuatKey *)malloc(data.mNumRotationKeys * sizeof(aiQuatKey));
        memcpy(data.mRotationKeys, asset->mRotationKeys, data.mNumRotationKeys * sizeof(aiQuatKey));
        
        data.mNumScalingKeys = asset->mNumScalingKeys;
        data.mScalingKeys = (aiVectorKey *)malloc(data.mNumScalingKeys * sizeof(aiVectorKey));
        memcpy(data.mScalingKeys, asset->mScalingKeys, data.mNumScalingKeys * sizeof(aiVectorKey));
    }
    
    return self;
}

- (void) dealloc
{
    NSLog(@"ai animation node dealloc, check memory leak");
//    if (data.mPositionKeys)
//        free(data.mPositionKeys);
//    if (data.mRotationKeys)
//        free(data.mRotationKeys);
//    if (data.mScalingKeys)
//        free(data.mScalingKeys);
}

@end

@implementation AIAnimation

+ (id) animationWithAsset:(const aiAnimation *)asset
{
    return [[AIAnimation alloc] initWithAsset:asset];
}

- (id) initWithAsset:(const aiAnimation *)asset
{
    if (self = [super init])
    {
        NSMutableArray *newChannels = [NSMutableArray arrayWithCapacity:asset->mNumChannels];
        for (int i = 0; i < asset->mNumChannels; ++i)
        {
            AIAnimationNode *node = [[AIAnimationNode alloc] initWithNode:asset->mChannels[i]];
            [newChannels addObject:node];
        }
        _channels = newChannels;
        
        duration = asset->mDuration;
        
        if (asset->mTicksPerSecond > 0.0001)
            duration /= asset->mTicksPerSecond;
    }
    
    return self;
}

@end

@implementation AIMaterial

+(instancetype)materialWithAsset:(aiMaterial *)asset {
    aiTextureMapMode mapMode;
    
    aiString *texturePathTmp = new aiString();
    
    asset->GetTexture(aiTextureType_DIFFUSE, 0, texturePathTmp, NULL, NULL, NULL, NULL, &mapMode);
    
    NSString *texturePath = [NSString stringWithAIString:texturePathTmp];
    
    NSLog(@"full path: %@", texturePath);
    
    NSString *filename = [[texturePath componentsSeparatedByString:@"\\"]lastObject] ;
    
    NSLog(@"loading AI texture with path: %@", filename);
  
    AIMaterial *newMat = [[AIMaterial alloc]init];
    
    if (![filename isEqualToString:@""]) {
          newMat.tex = [NKTexture textureWithImageNamed:filename];
    }
  
    
    return newMat;
}

@end

