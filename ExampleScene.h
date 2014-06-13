//
//  MyScene.h
//  EMA Stage
//
//  Created by Leif Shackelford on 5/17/14.
//  Copyright (c) 2014 EMA. All rights reserved.
//

#import "NodeKitten.h"

@class NKLightNode;

@interface ExampleScene : NKSceneNode <NKTableCellDelegate>

@property (nonatomic, strong) NKLightNode *omni;

-(instancetype)initWithSize:(S2t)size sceneChoice:(int)sceneChoice;

@end
