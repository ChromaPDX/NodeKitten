//
//  NKMatrixStack.h
//  NodeKittenIOS
//
//  Created by Leif Shackelford on 6/20/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NKpch.h"

@interface NKMatrixStack : NSObject

{
    M16t *matrixStack;
    U1t *indexStack;
    UInt32 matrixBlockSize;
    UInt32 matrixCount;
}

//@property (nonatomic) M16t currentMatrix;

-(M16t*)data;
-(M16t)currentMatrix;
-(NSUInteger)count;
-(M16t)lastObject;

-(void)multiplyMatrix:(M16t)matrix;
-(void)appendMatrix:(M16t)matrix;
-(int)locationByDepth:(M16t)matrix;
-(void)insertMatrix:(M16t)matrix atLocation:(int)location;
-(void)appendMatrixScale:(V3t)scale;
-(void)popMatrix;
-(void)reset;

@end

@interface NKM9Stack : NSObject

{
    M9t *matrixStack;
    UInt32 matrixBlockSize;
    UInt32 matrixCount;
}

@property (nonatomic) M9t currentMatrix;

-(M9t*)data;
-(void)appendMatrix:(M9t)matrix;
-(void)insertMatrix:(M9t)matrix atLocation:(int)location;
-(void)reset;

@end


@interface NKVector4Stack : NSObject
{
    V4t *vectorStack;
    UInt32 vectorBlockSize;
    UInt32 vectorCount;
}


@property (nonatomic) M16t currentVector;

-(V4t*)data;
-(void)appendVector:(V4t)vector;
-(void)insertVector:(V4t)vector atLocation:(int)location;
-(void)reset;

@end