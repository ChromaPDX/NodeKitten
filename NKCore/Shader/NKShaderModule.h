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

@property (nonatomic,strong) NSSet *uniforms;
@property (nonatomic,strong) NSSet *varyings;
@property (nonatomic,strong) NSString *const functionString;
@property (nonatomic, strong) UniformUpdateBlock updateBlock;

@end
