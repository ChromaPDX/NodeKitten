//
//  AppDelegate.h
//  NodeKittenDesktop
//
//  Created by Leif Shackelford on 6/12/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//

#import "NodeKitten.h"
#import "ExampleScene.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic) IBOutlet NKView* view;
@property (nonatomic, strong) NKViewController* viewController;

@end