//
//  NKEvent.h
//  NodeKittenIOS
//
//  Created by Leif Shackelford on 6/13/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//

#include "NKpch.h"

typedef NS_ENUM(U1t, NKEventPhase) {
    NKEventPhaseNone,
    NKEventPhaseBegin,
    NKEventPhaseMove,
    NKEventPhaseEnd,
    NKEventPhaseDrag,
    NKEventPhaseDoubleTap
} NS_ENUM_AVAILABLE(10_9, 7_0);

@class NKNode;

@interface NKEvent : NSObject {
    P2t _startingScreenLocation;
    P2t _screenLocation;
    
    V3t _startingWorldLocation;
    V3t _worldLocation;
    
    P2t _scale;
    
    NKEventPhase _phase;
}

#if TARGET_OS_IPHONE
@property (nonatomic, strong) UITouch* touch;
-(instancetype)initWithTouch:(UITouch*)touch;
#else
@property (nonatomic, strong) NSEvent* event;
-(instancetype)initWithEvent:(NSEvent *)event scale:(P2t)scale;
#endif

-(P2t)startingScreenLocation;
-(void)setStartingScreenLocation:(P2t)location;

-(P2t)screenLocation;
-(void)setScreenLocation:(P2t)location;

//-(P2t)glLocation;

-(V3t)startingWorldLocation;
-(void)setStartingWorldLocation:(P2t)location;
-(V3t)worldLocation;
-(V3t)linearVelocity;

-(NKEventPhase)phase;
-(void)setPhase:(NKEventPhase)phase;

@property (nonatomic, strong) NKNode* node;

@end
