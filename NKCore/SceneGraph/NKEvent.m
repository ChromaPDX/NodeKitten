//
//  NKEvent.m
//  NodeKittenIOS
//
//  Created by Leif Shackelford on 6/13/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//

#import "NKEvent.h"

@implementation NKEvent

#if TARGET_OS_IPHONE // IOS ONLY METHODS

-(instancetype)initWithTouch:(UITouch *)touch {
    if (self = [super init]){
        _touch = touch;
        _scale = P2MakeF([[UIScreen mainScreen]scale]);
    }
    return self;
}

#else // DESKTOP ONLY METHODS

-(instancetype)initWithEvent:(NSEvent *)event scale:(P2t)scale{
    if (self = [super init]){
        _event = event;
        _scale = scale;
    }
    return self;
}

#endif

-(void)sharedInit {
    
}

// PROPERTIES

-(P2t)screenLocation {
    return _screenLocation;
}

-(void)setScreenLocation:(P2t)location {
    _screenLocation = location;
}

-(P2t)startingScreenLocation {
    return _startingScreenLocation;
}

-(void)setStartingScreenLocation:(P2t)location {
    _startingScreenLocation = location;
    _screenLocation = location;
}

-(NKEventPhase)phase {
    return _phase;
}

-(void)setPhase:(NKEventPhase)phase {
    _phase = phase;
}

-(V3t)startingWorldLocation {
    return _startingWorldLocation;
}

-(V3t)worldLocation {
    return _worldLocation;
}

//-(P2t)glLocation {
//    return P2Multiply(self.screenLocation, _scale);
//}

@end
