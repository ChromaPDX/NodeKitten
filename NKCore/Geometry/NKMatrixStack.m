//
//  NKMatrixStack.m
//  NodeKittenIOS
//
//  Created by Leif Shackelford on 6/20/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//

#import "NKMatrixStack.h"

@implementation NKMatrixStack

-(instancetype)init {
    self = [super init];
    if (self) {
        matrixStack = malloc(sizeof(M16t)*NK_BATCH_SIZE);
        indexStack = malloc(sizeof(U1t)*NK_BATCH_SIZE);
        matrixBlockSize = NK_BATCH_SIZE;
        matrixCount = 0;
    }
    return self;
}

-(M16t*)data {
    return matrixStack;
}

-(void)pushMatrix{
    matrixCount++;
    if (matrixBlockSize <= matrixCount) {
        //NSLog(@"Expanding MATRIX STACK allocation size");
        
        M16t* copyBlock = malloc(sizeof(M16t) * (matrixCount*2));
        memcpy(copyBlock, matrixStack, sizeof(M16t) * (matrixCount));
        free(matrixStack);
        matrixStack = copyBlock;
        
        U1t* iCopyBlock = malloc(sizeof(U1t) * (matrixCount*2));
        memcpy(iCopyBlock, indexStack, sizeof(U1t) * (matrixCount));
        free(indexStack);
        indexStack = iCopyBlock;
        
        matrixBlockSize = matrixCount * 2;
    }
}

-(void)multiplyMatrix:(M16t)matrix {
    if (matrixCount > 0) {
        *(matrixStack+matrixCount) = M16Multiply(*(matrixStack+matrixCount-1), matrix);
    }
    else {
        *(matrixStack+matrixCount) = matrix;
    }
    [self pushMatrix];
}

-(void)appendMatrix:(M16t)matrix {
    matrixStack[matrixCount] = matrix;
    indexStack[matrixCount] = matrixCount;
    [self pushMatrix];
}

-(int)locationByDepth:(M16t)matrix {
    for (int i = 0;  i < matrixCount; i++){
        if (matrix.m32 < matrixStack[i].m32) {
            return i;
        }
    }
    return matrixCount;
}

// OLD

-(void)insertMatrix:(M16t)matrix atLocation:(int)location {
    M16t* copyBlock = malloc(sizeof(M16t) * (matrixBlockSize));
    memcpy(copyBlock, matrixStack, sizeof(M16t)*location);
    memcpy(copyBlock+location, matrix.m, sizeof(M16t));
    memcpy(copyBlock+location+1, matrixStack+location, sizeof(M16t) * (matrixCount - location));
    free(matrixStack);
    matrixStack = copyBlock;
    [self pushMatrix];
}

-(NSUInteger)count {
    return matrixCount;
}

-(M16t)lastObject {
    NSAssert(matrixCount, @"last object requested from empty stack");
    return matrixStack[matrixCount-1];
}

-(void)appendMatrixScale:(V3t)nscale {
    if (matrixCount > 0) {
        *(matrixStack+matrixCount) = M16ScaleWithV3(*(matrixStack+matrixCount-1), nscale);
    }
    [self pushMatrix];
}

-(M16t)currentMatrix {
    return *(matrixStack+matrixCount-1);
}

-(void)popMatrix {
    if (matrixCount > 0) {
        matrixCount--;
        //_currentMatrix = *(matrixStack+matrixCount-1);
        //memcpy(_currentMatrix.m, matrixStack+matrixCount, sizeof(M16t));
        //NSLog(@"pop M %lu", matrixCount);
    }
    // else _currentMatrix = M16IdentityMake();
    else {
        NSLog(@"MATRIX STACK UNDERFLOW");
    }
    
    //[_activeShader setMatrix4:modelMatrix forUniform:UNIFORM_MODELVIEWPROJECTION_MATRIX];
    
    //[_activeShader setMatrix4:M16Multiply(_camera.projectionMatrix,modelMatrix) forUniform:UNIFORM_MODELVIEWPROJECTION_MATRIX];
}

-(void)reset {
    matrixCount = 0;
}
-(void)dealloc {
    if (matrixStack) {
        free(matrixStack);
    }
}

@end

@implementation NKM9Stack

-(instancetype)init {
    self = [super init];
    if (self) {
        matrixStack = malloc(sizeof(M9t)*NK_BATCH_SIZE);
        matrixBlockSize = NK_BATCH_SIZE;
        matrixCount = 0;
    }
    
    return self;
}

-(M9t*)data {
    return matrixStack;
}

-(void)pushMatrix{
    matrixCount++;
    if (matrixBlockSize <= matrixCount) {
        NSLog(@"Expanding MATRIX STACK allocation size");
        M9t* copyBlock = malloc(sizeof(M9t) * (matrixCount*2));
        memcpy(copyBlock, matrixStack, sizeof(M9t) * (matrixCount));
        free(matrixStack);
        matrixStack = copyBlock;
        matrixBlockSize = matrixCount * 2;
    }
}

-(void)appendMatrix:(M9t)matrix {
    memcpy(matrixStack+matrixCount, matrix.m, sizeof(M9t));
    [self pushMatrix];
}

-(void)insertMatrix:(M9t)matrix atLocation:(int)location {
    M9t* copyBlock = malloc(sizeof(M9t) * (matrixBlockSize));
    memcpy(copyBlock, matrixStack, sizeof(M9t)*location);
    memcpy(copyBlock+location, matrix.m, sizeof(M9t));
    memcpy(copyBlock+location+1, matrixStack, sizeof(M9t) * (matrixCount - location));
    free(matrixStack);
    matrixStack = copyBlock;
    [self pushMatrix];
}

-(void)reset {
    matrixCount = 0;
}

-(void)dealloc {
    if (matrixStack) {
        free(matrixStack);
    }
}

@end

@implementation NKVector4Stack

-(instancetype)init {
    self = [super init];
    if (self) {
        vectorStack = malloc(sizeof(V4t)*NK_BATCH_SIZE);
        vectorBlockSize = NK_BATCH_SIZE;
        vectorCount = 0;
    }
    
    return self;
}

-(V4t*)data {
    return vectorStack;
}

-(void)pushVector{
    vectorCount++;
    if (vectorBlockSize <= vectorCount) {
        NSLog(@"Expanding VECTOR STACK allocation size");
        V4t* copyBlock = malloc(sizeof(V4t) * (vectorCount*2));
        memcpy(copyBlock, vectorStack, sizeof(V4t) * (vectorCount));
        free(vectorStack);
        vectorStack = copyBlock;
        vectorBlockSize = vectorCount * 2;
    }
}

-(void)appendVector:(V4t)vector {
    memcpy(vectorStack+vectorCount, vector.v, sizeof(V4t));
    [self pushVector];
}

-(void)insertVector:(V4t)vector atLocation:(int)location {
    V4t* copyBlock = malloc(sizeof(V4t) * (vectorBlockSize));
    memcpy(copyBlock, vectorStack, sizeof(V4t)*location);
    memcpy(copyBlock+location, vector.v, sizeof(V4t));
    memcpy(copyBlock+location+1, vectorStack, sizeof(V4t) * (vectorCount - location));
    free(vectorStack);
    vectorStack = copyBlock;
    [self pushVector];
}

-(void)reset {
    vectorCount = 0;
}

-(void)dealloc {
    if (vectorStack) {
        free(vectorStack);
    }
}

@end
