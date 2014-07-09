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
@class NKShaderProgram;
@class NKByteColor;
@class NKBulletBody;
@class NKFrameBuffer;

//typedef NS_ENUM(U1t, NKTouchState) {
//    NKTouchNone,
//    NKTouchContainsFirstResponder,
//    NKTouchIsFirstResponder
//} NS_ENUM_AVAILABLE(10_9, 7_0);

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
@class NKEvent;

typedef void (^ActionBlock)(NKAction *action, NKNode* node, F1t completion);
#define newActionBlock (ActionBlock)^(NKAction *action, NKNode* node, F1t completion)
typedef void (^EventBlock)(NKEvent* event);
#define newEventBlock (EventBlock)^(NKEvent* event)
typedef void (^CompletionBlock)(void);

@interface NKNode : NSObject
{

#pragma mark - POSITION / GEOMETRY

    M16t _localTransform;
    M16t _cachedGlobalTransform;
    
    Q4t _orientation; // matrix set orientation
    V3t _scale; // matrix set scale
    V3t _position; // matrix set translation
    V3t _anchorPoint;
    V3t _size;
    
    NKNode *_parent;
    NSArray *_children;
    NSMutableSet *touches;


    NKByteColor *_color;    
    NodeAnimationHandler *animationHandler;
    
    F1t w;
    F1t h;
    F1t d;
    
    // CACHED PROPS
    F1t parentAlpha;
    F1t intAlpha;
    F1t _colorBlendFactor;
    
    EventBlock _eventBlock;
    
    bool _dirty;
    
    NKSceneNode* _scene;
}

#pragma mark - NODE TREE

@property (nonatomic, strong) NSArray *children;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NKByteColor *uidColor;
@property (nonatomic) U1t tag;
@property (nonatomic) V3t positionRef;
@property (nonatomic) V3t scalarVelocity;
@property (nonatomic) M16t modelViewCache;
@property (nonatomic, strong) NKFrameBuffer *framebuffer;

#pragma mark - POSITION PROPERTIES

@property (nonatomic) V3t upVector;

#pragma mark - STATE + INTERACTION PROPERTIES

@property (nonatomic, getter = isPaused) BOOL paused;
@property (nonatomic, getter = isHidden) BOOL hidden;
@property (nonatomic) bool userInteractionEnabled;

#pragma mark - COLOR + BLEND

-(void)setColor:(NKByteColor*)color;
-(NKByteColor*)color;
-(C4t)glColor;
-(F1t)colorBlendFactor;
-(void)setColorBlendFactor:(F1t)colorBlendFactor;

@property (nonatomic) NKBlendMode blendMode;
@property (nonatomic) bool usesDepth;
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
- (NKNode*)parent;
- (void)setParent:(NKNode *)parent;
- (BOOL)inParentHierarchy:(NKNode *)parent;

-(void)setDirty:(bool)dirty;

- (void) unload;

-(void)setScene:(NKSceneNode *)scene;
-(NKSceneNode*)scene;

#pragma mark - PHYSICS

@property (nonatomic, strong) NKBulletBody *body;

#pragma mark - GEOMETRY METHODS

-(bool)containsPoint:(P2t)location;

-(void)setXPosition:(float)position;
-(void)setYPosition:(float)position;
-(void)setZPosition:(float)position;

-(V3t)position;
- (void)setPosition:(V3t)position;
-(void)setPosition2d:(V2t)position;

-(V3t)globalPosition;
-(M16t)globalTransform;

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
// draw encompasses these 2 states
-(void)setupViewMatrix;
-(void)customDraw;
//**

// drawing for hit detection
-(void)drawWithHitShader;
-(void)customDrawWithHitShader;


-(bool)shouldCull;

-(int)numVisibleNodes;
-(int)numNodes;

#pragma mark - SHADER / FBO

-(void)loadShaderNamed:(NSString*)name;

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

-(void)setLocalTransform:(M16t)localTransform;
-(M16t)localTransform;

#pragma mark - POSITION METHODS

-(void)setSize2d:(S2t)size;
-(void)setSize:(V3t)size;
-(V2t)size2d;
-(V3t) size;

-(R4t)getDrawFrame;
- (R4t)calculateAccumulatedFrame;

-(void)setAnchorPoint:(V3t)anchorPoint;
-(void)setAnchorPoint2d:(V2t)anchorPoint;
-(V3t)anchorPoint;
-(V2t)anchorPoint2d;

#pragma mark - ORIENTATION METHODS

-(void) rotateMatrix:(M16t)M16;
-(void) globalRotateMatrix:(M16t)M16;
-(void) setOrientation:(const Q4t)q;
-(void) setGlobalOrientation:(const Q4t) q;
-(void) setOrientationEuler:(const V3t)eulerAngles;

-(Q4t) getGlobalOrientation;
-(Q4t) orientation;
-(V3t) getOrientationEuler;
-(F1t) getYOrientation;

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

-(void)setScale:(V3t)scale;
-(void)setScaleF:(F1t)s;
-(void)setXScale:(F1t)s;
-(void)setYScale:(F1t)s;

-(V3t)scale;
-(V2t)scale2d;

#pragma mark - TOUCH

-(void)setEventBlock:(EventBlock)eventBlock;

-(void)handleEvent:(NKEvent*)event;

//-(NKTouchState) touchDown:(P2t)location id:(int) touchId;
//-(NKTouchState) touchMoved:(P2t)location id:(int) touchId;
//-(NKTouchState) touchUp:(P2t)location id:(int) touchId;

//+(void)drawRectangle:(S2t)size;

// UTIL
-(void)logCoords;
-(void)logPosition;
-(void)logMatrix:(M16t) M16;

@end

