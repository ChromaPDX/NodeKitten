//
//  AlertSprite.m
//  ChromaNSFW
//
//  Created by Chroma Developer on 12/10/13.
//  Copyright (c) 2013 Chroma. All rights reserved.
//

#import "NodeKitten.h"

@implementation NKAlertSprite

-(instancetype)initWithTexture:(NKTexture *)texture color:(NKColor *)color size:(S2t)size    {
    
    self = [super initWithTexture:texture color:color size:size];
    if (self) {
        self.userInteractionEnabled = YES;
    }
    return self;
    
}

-(void)handleEvent:(NKEvent *)event {
    
    if (NKEventPhaseEnd == event.phase) {
        [_delegate alertDidCancel];
    }
}

@end
