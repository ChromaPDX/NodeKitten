//
//  AppDelegate.m
//  NodeKittenDesktop
//
//  Created by Leif Shackelford on 6/12/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    [_window makeFirstResponder:_view];
    
    _view.scene = [[ExampleScene alloc]initWithSize:S2MakeCG(_view.visibleRect.size) sceneChoice:0];
    
    [_view startAnimation];
}

@end