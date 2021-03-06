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

//#define SHOW_HIT_DETECTION

#import "NKNode.h"
#import "NKAlertSprite.h"

#if NK_USE_MIDI
#import "MIKMIDI.h"
typedef void (^MidiReceivedBlock)(MIKMIDICommand* command);
#define newMidiReceivedBlock (MidiReceivedBlock)^(MIKMIDICommand* command)
#endif

#if TARGET_OS_IPHONE
@class NKUIView;
#else
@class NKView;
#endif

@class NKCamera;
@class NKShaderProgram;
@class NKVertexBuffer;
@class NKAlertSprite;
@class NKFrameBuffer;
@class NKMatrixStack;

@class NKBulletWorld;

typedef void (^CallBack)();


@interface NKSceneNode : NKNode <NKAlertSpriteDelegate>

{
    int frames;
    double currentFrameTime;
    double frameTime;
    bool loaded;
    NKVertexBuffer *axes;
    
   #if NK_LOG_METRICS
    NSTimer *metricsTimer;
#endif
}

-(instancetype) initWithSize:(S2t)size;

// NODE HIERARCHY
#if TARGET_OS_IPHONE
@property (nonatomic, weak)   NKUIView *nkView;
#else
@property (nonatomic, weak)   NKView *nkView;
#endif
//@property (nonatomic) void *view;

@property (nonatomic) BOOL shouldRasterize;
@property (nonatomic) NKByteColor *backgroundColor;
@property (nonatomic) NKByteColor *borderColor;

@property (nonatomic, strong) NKCamera *camera;
@property (nonatomic, strong) NKMatrixStack *stack;
@property (nonatomic, weak) NKAlertSprite *alertSprite;

@property (nonatomic) BOOL drawLights;
@property (nonatomic, strong) NSMutableArray *lights;

// HIT DETECTION

-(void)dispatchEvent:(NKEvent*)event;

// COLOR BASED HIT DETECTION
@property (nonatomic) bool useColorDetection;
@property (nonatomic, strong) NKShaderProgram *hitDetectShader;
@property (nonatomic, strong) NKFrameBuffer *hitDetectBuffer;
@property (nonatomic, strong) NSMutableArray *hitQueue;

// PHYSICS HIT DETECTION

@property (nonatomic) bool useBulletDetection;

// GL STATE MACHINE CONTROL
@property (nonatomic, weak) NKShaderProgram *activeShader;
@property (nonatomic, weak) NKVertexBuffer *boundVertexBuffer;
@property (nonatomic, weak) NKTexture *boundTexture;
@property (nonatomic) bool fill;

// EXTERNAL MODULES
#if NK_USE_MIDI
-(void)handleMidiCommand:(MIKMIDICommand*)command;
@property (nonatomic, strong) MidiReceivedBlock midiReceivedBlock;
#endif

-(void)bindMainFrameBuffer:(NKNode*)sender;
-(void)clear;

-(void)pushMultiplyMatrix:(M16t)matrix;
-(void)pushScale:(V3t)scale;
-(void)popMatrix;

-(void)setUniformIdentity;
-(void)drawAxes;

// HIT BUFFER

-(void)processHitBuffer;
-(void)drawHitBuffer;

-(void)keyDown:(NSUInteger)key;
-(void)keyUp:(NSUInteger)key;

@end


