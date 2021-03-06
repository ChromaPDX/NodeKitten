//
//  ExampleScene.h
//  Node Kitten Examples
//
//  Created by Leif Shackelford on 5/17/14.
//  Copyright (c) 2014 Chroma. All rights reserved.
//

#import "NodeKitten.h"

@class NKLightNode;

float steering;
float acceleration;

@interface ExampleScene : NKSceneNode <NKTableCellDelegate>

@property (nonatomic, strong) NKLightNode *omni;

-(instancetype)initWithSize:(S2t)size sceneChoice:(int)sceneChoice;

@end
