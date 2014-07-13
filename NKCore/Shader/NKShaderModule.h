//
//  NKFragModule.h
//  NodeKittenIOS
//
//  Created by Leif Shackelford on 7/12/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^UniformUpdateBlock)();
#define newUniformUpdateBlock (UniformUpdateBlock)^()

@interface NKShaderModule : NSObject

@property (nonatomic, strong) NSString *name;


@property (nonatomic,strong) NSMutableArray *uniforms;
@property (nonatomic,strong) NSMutableArray *varyings;

@property (nonatomic,strong) NSString *types;

@property (nonatomic, strong) NSMutableArray *vertFunctions;
@property (nonatomic, strong) NSMutableArray *fragFunctions;

@property (nonatomic,strong) NSString *const vertexMain;
@property (nonatomic,strong) NSString *const fragmentMain;

@property (nonatomic, strong) UniformUpdateBlock uniformUpdateBlock;

-(NKShaderVariable*)uniformNamed:(NKS_ENUM)name;
-(NKShaderVariable*)varyingNamed:(NKS_ENUM)name;

// DEFAULT MODULES

+(NKShaderModule*) materialModule:(int)numTex;
+(NKShaderModule*) colorModule:(NKS_COLOR_MODE)colorMode batchSize:(int)batchSize;
+(NKShaderModule*) textureModule:(int)numTex;
+(NKShaderModule*) lightModule:(bool)highQuality batchSize:(int)batchSize;

// POST PROCESS (FRAGMENT ONLY) MODULES

+(NKShaderModule*) falseColorModule:(F1t)intensity darkColor:(NKByteColor*)darkColor lightColor:(NKByteColor*)lightColor;

@end
