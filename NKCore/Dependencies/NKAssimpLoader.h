//
//  NKAssimpLoader.h
//  NodeKittenIOS
//
//  Created by Leif Shackelford on 6/13/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NKpch.h"
#import "NKMeshNode.h"


@interface AIScene : NSObject

@property (nonatomic, strong) NSArray *meshes;
@property (nonatomic, strong) NSArray *materials;
@property (nonatomic, strong) NSDictionary *animations;

//@property (nonatomic, strong) AINode *rootNode;

+ (NKMeshNode*)meshNodeFromFile:(NSString *)file;
+ (id) sceneFromFile:(NSString *)file;
- (id) initFromFile:(NSString *)file;

@end





