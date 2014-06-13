/***********************************************************************
 
 Written by Leif Shackelford
 Copyright (c) 2014 Chroma.io
 All rights reserved. *
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met: *
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of CHROMA GAMES nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission. *
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 OF THE POSSIBILITY OF SUCH DAMAGE. *
 ***********************************************************************/

#import "NKpch.h"

@class NKAction;
@class NodeAnimationHandler;
@class NKSceneNode;
@class NKDrawDepthShader;
@class NKFbo;
@class NKShaderProgram;
@class NKByteColor;
@class NKBulletBody;

typedef NS_ENUM(U1t, NKTouchState) {
    NKTouchNone,
    NKTouchContainsFirstResponder,
    NKTouchIsFirstResponder
} NS_ENUM_AVAILABLE(10_9, 7_0);

typedef NS_ENUM(U1t, NKEventType) {
    NKEventTypeNone,
    NKEventTypeBegin,
    NKEventTypeMove,
    NKEventTypeEnd,
    NKEventTypeDrag,
    NKEventTypeDoubleTap
} NS_ENUM_AVAILABLE(10_9, 7_0);

typedef NS_ENUM(U1t, NKBlendMode) {
    NKBlendModeNone,
    NKBlendModeAlpha,
    NKBlendModeAdd,
    NKBlendModeMultiply,
    NKBlendModeScreen,
    NKBlendModeSubtract
} NS_ENUM_AVAILABLE(10_9, 7_0);

typedef NS_ENUM(U1t, NKCullFaceMode) {
    NKCullFaceNone,
    NKCullFaceFront,
    NKCullFaceBack,
    NKCullFaceBoth
} NS_ENUM_AVAILABLE(10_9, 7_0);

@class NKNode;

typedef void (^ActionBlock)(NKAction *action, NKNode* node, F1t completion);
#define newActionBlock (ActionBlock)^(NKAction *action, NKNode* node, F1t completion)
typedef void (^EventBlock)(NKEventType eventType, P2t location);
#define newEventBlock (EventBlock)^(NKEventType eventType, P2t location)
typedef void (^CompletionBlock)(void);

@interface NKNode : NSObject
{

#pragma mark - POSITION / GEOMETRY

    M16t localTransformMatrix;
    
    Q4t orientation; // matrix set orientation
    V3t scale; // matrix set scale
    V3t position; // matrix set translation
	
	V3t axis[3];
    
    V3t _size3d;
    
    NKNode *_parent;
    NSMutableArray *intChildren;
    NSMutableSet *touches;
    // of internals

    NKByteColor *_color;
    
    NodeAnimationHandler *animationHandler;
    
    F1t w;
    F1t h;
    F1t d;
    
    // CACHED PROPS
    F1t intAlpha;

    EventBlock _eventBlock;
}

#pragma mark - NODE TREE

@property (nonatomic, weak) NKSceneNode* scene;
@property (nonatomic, strong) NSArray *children;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NKByteColor *uidColor;
@property (nonatomic) bool dirty;
@property (nonatomic) V3t positionRef;
@property (nonatomic) V3t scalarVelocity;

#pragma mark - POSITION PROPERTIES

@property (nonatomic) P2t anchorPoint;
@property (nonatomic) V3t anchorPoint3d;
@property (nonatomic) F1t zRotation;
@property (nonatomic) V3t upVector;

#pragma mark - STATE + INTERACTION PROPERTIES

@property (nonatomic, getter = isPaused) BOOL paused;
@property (nonatomic, getter = isHidden) BOOL hidden;
@property (nonatomic) bool userInteractionEnabled;

#pragma mark - BLEND

-(void)setColor:(NKByteColor*)color;
-(NKByteColor*)color;

@property (nonatomic) NKBlendMode blendMode;
@property (nonatomic) NKCullFaceMode cullFace;

@property (nonatomic) F1t alpha;
-(void)setTransparency:(F1t)transparency;
-(void)recursiveAlpha:(F1t)alpha;

#pragma mark - SHADER PROPERTIES

@property (nonatomic, strong) NKShaderProgram *shader;

#pragma mark - INIT

-(instancetype) init;
-(instancetype)initWithSize:(V3t)size;

#pragma mark - HIERARCHY METHODS

- (void)addChild:(NKNode *)node;
- (void)removeChild:(NKNode *)node;
- (void)removeChildNamed:(NSString *)name;
- (void)fadeInChild:(NKNode*)child duration:(NSTimeInterval)seconds;
- (void)fadeOutChild:(NKNode*)child duration:(NSTimeInterval)seconds;
- (void)fadeInChild:(NKNode*)child duration:(NSTimeInterval)seconds withCompletion:(void (^)())block;
- (void)fadeOutChild:(NKNode*)child duration:(NSTimeInterval)seconds withCompletion:(void (^)())block;
-(P2t)childLocationIncludingRotation:(NKNode*)child;
- (void)insertChild:(NKNode *)node atIndex:(NSInteger)index;
- (void)removeChildrenInArray:(NSArray *)nodes;
- (void)removeAllChildren;
- (void)removeFromParent;
- (NKNode *)childNodeWithName:(NSString *)name;
-(NSArray*)allChildren;
- (NKNode *)randomChild;
-(NKNode*)randomLeaf;
- (void)enumerateChildNodesWithName:(NSString *)name usingBlock:(void (^)(NKNode *node, BOOL *stop))block;
- (void)setParent:(NKNode *)parent;
- (BOOL)inParentHierarchy:(NKNode *)parent;

- (void) unload;

#pragma mark - PHYSICS

@property (nonatomic, strong) NKBulletBody *body;

#pragma mark - GEOMETRY METHODS

- (void)setZPosition:(int)zPosition;
- (void)setPosition:(P2t)position;

-(V3t)getGlobalPosition;
-(P2t)positionInNode:(NKNode*)node;
-(V3t)positionInNode3d:(NKNode*)node;

- (P2t)convertPoint:(P2t)point fromNode:(NKNode *)node;
- (P2t)convertPoint:(P2t)point toNode:(NKNode *)node;

-(V3t)convertPoint3d:(V3t)point fromNode:(NKNode *)node;
-(V3t)convertPoint3d:(V3t)point toNode:(NKNode *)node;

#pragma mark - UPDATE / DRAW CYCLE

//**
- (void)updateWithTimeSinceLast:(F1t) dt;
//**
- (void)draw;
//**
// draw encompasses these 3 states
-(void)begin;
-(void)customDraw;
-(void)end;
//**

// drawing for hit detection
-(void)drawWithHitShader;
-(void)customDrawWithHitShader;


-(bool)shouldCull;

-(int)numVisibleNodes;
-(int)numNodes;

#pragma mark - SHADER / FBO

-(void)loadShaderNamed:(NSString*)name;
+(NKFbo*)customFbo:(S2t)size;

#pragma mark - STATE MAINTENANCE

-(void)pushStyle;

#pragma mark - ACTIONS

- (void)runAction:(NKAction *)action;
- (void)runAction:(NKAction *)action completion:(void (^)())block;
- (void)runAction:(NKAction *)action withKey:(NSString *)key;
-(void)repeatAction:(NKAction*)action;
- (int)hasActions;
- (NKAction *)actionForKey:(NSString *)key;
- (void)removeActionForKey:(NSString *)key;
- (void)removeAllActions;

#pragma mark - MATRIX METHODS

-(M16t)getGlobalTransformMatrix;
-(void)setLocalTransformMatrix:(M16t)_localTransformMatrix;
-(M16t)localTransformMatrix;

#pragma mark - POSITION METHODS

-(bool)containsPoint:(P2t) location;

-(P2t)position;
-(V3t)position3d;
-(void)setPosition3d:(V3t)position3d;

-(void)setSize:(S2t)size;
-(void)setSize3d:(V3t)size3d;

-(S2t) size;
-(V3t) size3d;

-(R4t)getDrawFrame;
- (R4t)calculateAccumulatedFrame;

#pragma mark - ORIENTATION METHODS

-(void) rotateMatrix:(M16t)M16;
-(void) globalRotateMatrix:(M16t)M16;
-(void) setOrientation:(const Q4t)q;
-(void) setGlobalOrientation:(const Q4t) q;
-(void) setOrientationEuler:(const V3t)eulerAngles;

-(Q4t) getGlobalOrientation;
-(Q4t) orientation;
-(V3t) getOrientationEuler;

// look etc.

#pragma mark - GEODATA

@property (nonatomic) F1t latitude;
@property (nonatomic) F1t longitude;
@property (nonatomic) F1t radius;

-(void)setOrbit:(V3t)orbit;
-(V3t)currentOrbit;
-(V3t)orbitForLongitude:(float)longitude latitude:(float)latitude radius:(float)radius;
-(V3t) upVector;
-(void)lookAtNode:(NKNode*)node;
-(M16t)getLookMatrix:(V3t)lookAtPosition;

#pragma mark - SCALE METHODS

-(void)setScale3d:(V3t)s;
-(void)setScale:(F1t)s;
-(void)setXScale:(F1t)s;
-(void)setYScale:(F1t)s;

-(V3t)scale3d;
-(P2t)scale;

#pragma mark - TOUCH

-(void)setEventBlock:(EventBlock)eventBlock;

-(void)handleEventWithType:(NKEventType)event forLocation:(P2t)location;

//-(NKTouchState) touchDown:(P2t)location id:(int) touchId;
//-(NKTouchState) touchMoved:(P2t)location id:(int) touchId;
//-(NKTouchState) touchUp:(P2t)location id:(int) touchId;

//+(void)drawRectangle:(S2t)size;

// UTIL
-(void)logCoords;
-(void)logPosition;
-(void)logMatrix:(M16t) M16;

@end
