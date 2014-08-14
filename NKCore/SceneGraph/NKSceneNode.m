//
//  NKSceneNode.m
//  example-ofxTableView
//
//  Created by Chroma Developer on 2/17/14.
//
//

#import "NodeKitten.h"

@implementation NKSceneNode

-(instancetype)initWithSize:(S2t)size {
    
    self = [super initWithSize:V3Make(size.x, size.y, 1.)];
    
    if (self){
        
#if NK_USE_MIDI
        [[NKMidiManager sharedInstance] setDelegate:self];
#endif
        
#if NK_GL_DEBUG
        // Obtain iOS version
		int OSVersion_ = 0;
#if TARGET_OS_IPHONE
		NSString *OSVer = [[UIDevice currentDevice] systemVersion];
#else
        SInt32 versionMajor, versionMinor, versionBugFix;
        Gestalt(gestaltSystemVersionMajor, &versionMajor);
        Gestalt(gestaltSystemVersionMinor, &versionMinor);
        Gestalt(gestaltSystemVersionBugFix, &versionBugFix);
        
        NSString *OSVer = [NSString stringWithFormat:@"%d.%d.%d", versionMajor, versionMinor, versionBugFix];
#endif
		NSArray *arr = [OSVer componentsSeparatedByString:@"."];
		int idx = 0x01000000;
		for( NSString *str in arr ) {
			int value = [str intValue];
			OSVersion_ += value * idx;
			idx = idx >> 8;
		}
        NSLog(@"OS version: %@ (0x%08x)", OSVer, OSVersion_);
        NSLog(@"GL_VENDOR:   %s", glGetString(GL_VENDOR) );
        NSLog(@"GL_RENDERER: %s", glGetString ( GL_RENDERER   ) );
        NSLog(@"GL_VERSION:  %s", glGetString ( GL_VERSION    ) );
		//char* glExtensions = (char*)glGetString(GL_EXTENSIONS);
        //NSLog(@"GL EXT: %@",[NSString stringWithCString:glExtensions encoding: NSASCIIStringEncoding]);
#endif
        self.name = @"SCENE";
        
        self.backgroundColor = [NKByteColor colorWithRed:50 green:50 blue:50 alpha:255];
        self.shouldRasterize = false;
        self.userInteractionEnabled = true;
        
        _hitQueue = [NSMutableArray array];
        _lights = [NSMutableArray array];
        
        self.blendMode = 0;
        self.cullFace = 0;
        self.usesDepth = 0;
        
        _camera = [[NKCamera alloc]initWithScene:self];
        
        self.scene = self;
        
        _stack = [[NKMatrixStack alloc]init];
        
        self.useColorDetection = true;
        _hitDetectBuffer = [[NKFrameBuffer alloc] initWithWidth:self.size.width height:self.size.height];
        _hitDetectShader = [NKShaderProgram newShaderNamed:@"hitShaderSingle" colorMode:NKS_COLOR_MODE_UNIFORM numTextures:0 numLights:0 withBatchSize:0];
        
        self.framebuffer = [[NKFrameBuffer alloc] initWithWidth:self.size.width height:self.size.height];
        
#if NK_LOG_METRICS
        metricsTimer = [NSTimer timerWithTimeInterval:1. target:self selector:@selector(logMetricsPerSecond) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:metricsTimer forMode:NSDefaultRunLoopMode];
#endif
        NSLog(@"init scene with size, %f %f", size.width, size.height);
        
        GetGLError();
        
    }
    return self;
}

-(void)logMetricsPerSecond {
    NSLog(@"fps %d : frametime: %1.3f nodes: %lu : bBodies %lu : lights %lu", frames, (frameTime / frames), self.allChildren.count, (unsigned long)[[NKBulletWorld sharedInstance] nodes].count, (unsigned long)_lights.count);
    frames = 0;
    frameTime = 0;
}

-(void)updateWithTimeSinceLast:(F1t)dt {
    
    if (loaded) {
    
#if NK_LOG_METRICS
    frames++;
    currentFrameTime = CFAbsoluteTimeGetCurrent();
#endif
    
   
        
    [NKSoundManager updateWithTimeSinceLast:dt];
    
    [NKGLManager updateWithTimeSinceLast:dt];
    
    [[NKBulletWorld sharedInstance] updateWithTimeSinceLast:dt];
    
    [self setDirty:false];
    
    [super updateWithTimeSinceLast:dt];
//
    [_camera setDirty:true];
    [_camera updateCameraWithTimeSinceLast:dt];
        
    }
    
}

-(void)setDirty:(bool)dirty {
    
        _dirty = dirty;
        
        if (dirty) {
            for (NKNode *n in _children) {
                if ([n isKindOfClass:[NKLightNode class]]) {
                }
                [n setDirty:dirty];
            }
        }
}

-(void)drawHitBuffer {
    self.blendMode = NKBlendModeNone;
    glDisable(GL_BLEND);
    
    _activeShader = _hitDetectShader;
    [_activeShader use];
    
    [super drawWithHitShader];
    
    [_camera drawWithHitShader];
}

-(void)processHitBuffer {
    
    [_hitDetectBuffer bind];
    
    glViewport(0, 0, self.size.width, self.size.height);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    
    [self drawHitBuffer];
    
    for (CallBack b in _hitQueue) {
        b();
    }
    
    [_hitQueue removeAllObjects];
    
}

-(void)setActiveShader:(NKShaderProgram *)activeShader {
 
    if (!activeShader) {
        _activeShader = nil;
        glUseProgram(0);
    }
    
    else if (![_activeShader isEqual:activeShader]) {
        //NSLog(@"set shader: %@", activeShader.name);
        _activeShader = activeShader;
        [_activeShader use];
        
        // prep globals
        
        if  ([_activeShader uniformNamed:NKS_S2D_TEXTURE]){
            [[_activeShader uniformNamed:NKS_S2D_TEXTURE] bindI1:0];
                glUniform1i([[_activeShader uniformNamed:NKS_S2D_TEXTURE] glLocation], 0);
        }
        
        if ([_activeShader uniformNamed:NKS_LIGHT]){
            if (_lights) {
                [[_activeShader uniformNamed:NKS_I1_NUM_LIGHTS] bindI1:(int)_lights.count];
                if (_lights.count) {
                    [[_activeShader uniformNamed:NKS_LIGHT] bindLightProperties:[(NKLightNode*)_lights[0] pointer] count:(int)_lights.count];
                }
            }
            else {
                [[_activeShader uniformNamed:NKS_I1_NUM_LIGHTS] bindI1:0];
            }
        }
        
        for (NKShaderModule *m in _activeShader.modules) {
            if (m.uniformUpdateBlock) {
                  m.uniformUpdateBlock();
            }
        }
    }
}

-(void)bindMainFrameBuffer:(NKNode*)sender {
    if (sender != self && self.framebuffer) {
        [self.framebuffer bind];
    }
    else {
#if TARGET_OS_IPHONE
        NKUIView* view = self.nkView;
        [view.framebuffer bind];
#else
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
#endif
    }
    //NSLog(@"bind fb %@ %@", view, view.framebuffer);
}

-(void)draw {
    [self clear];
#if DRAW_HIT_BUFFER
    [self drawHitBuffer];
#else
    [super draw];
    [_camera draw];
#endif
    frameTime += CFAbsoluteTimeGetCurrent() - currentFrameTime;
}

-(void)clear {
    _activeShader = nil;
    glUseProgram(0);
    [_boundTexture unbind];
    _boundTexture = nil;
    [_boundVertexBuffer unbind];
    _boundVertexBuffer = nil;
}

-(void)setCullFace:(NKCullFaceMode)cullFace {
    
    if (cullFace != self.cullFace) {
        
        switch (cullFace) {

            case NKCullFaceNone:
                glDisable(GL_CULL_FACE);
                break;
                
            case NKCullFaceFront:
                if (self.cullFace < 1) {
                    glEnable(GL_CULL_FACE);
                }
                glCullFace(GL_FRONT);
                break;
                
            case NKCullFaceBack:
                if (self.cullFace < 1) {
                    glEnable(GL_CULL_FACE);
                }
                glCullFace(GL_BACK);
                break;
                
            case NKCullFaceBoth:
                if (self.cullFace < 1) {
                    glEnable(GL_CULL_FACE);
                }
                glCullFace(GL_FRONT_AND_BACK);
                break;
                
            default:
                break;
        }
        
        [super setCullFace:cullFace];
    }
    
}

-(void)setBlendMode:(NKBlendMode)blendMode {
    
    if (self.blendMode != blendMode) {
        
        switch (blendMode){
            case NKBlendModeNone:
                glDisable(GL_BLEND);
                break;
                
            case NKBlendModeAlpha:{
                glEnable(GL_BLEND);
                //#ifndef TARGET_OPENGLES
                //				glBlendEquation(GL_FUNC_ADD);
                //#endif
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                break;
            }
                
            case NKBlendModeAdd:{
                glEnable(GL_BLEND);
                //#ifndef TARGET_OPENGLES
                //				glBlendEquation(GL_FUNC_ADD);
                //#endif
                glBlendFunc(GL_SRC_ALPHA, GL_ONE);
                break;
            }
                
            case NKBlendModeMultiply:{
                glEnable(GL_BLEND);
                //#ifndef TARGET_OPENGLES
                //				glBlendEquation(GL_FUNC_ADD);
                //#endif
                glBlendFunc(GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA /* GL_ZERO or GL_ONE_MINUS_SRC_ALPHA */);
                break;
            }
                
            case NKBlendModeScreen:{
                glEnable(GL_BLEND);
                //#ifndef TARGET_OPENGLES
                //				glBlendEquation(GL_FUNC_ADD);
                //#endif
                glBlendFunc(GL_ONE_MINUS_DST_COLOR, GL_ONE);
                break;
            }
                
            case NKBlendModeSubtract:{
                glEnable(GL_BLEND);
                //#ifndef TARGET_OPENGLES
                //                glBlendEquation(GL_FUNC_REVERSE_SUBTRACT);
                //#else
                //                NSLog(@"OF_BLENDMODE_SUBTRACT not currently supported on OpenGL ES");
                //#endif
                glBlendFunc(GL_SRC_ALPHA, GL_ONE);
                break;
            }
                
            default:
                break;
        }
        
        [super setBlendMode:blendMode];
    }
    
}

-(void)setUsesDepth:(bool)usesDepth {
    if (self.usesDepth != usesDepth) {
        if (usesDepth) {
            glEnable(GL_DEPTH_TEST);
            glDepthFunc(GL_LEQUAL);
        }
        else {
             glDisable(GL_DEPTH_TEST);
        }
        
        [super setUsesDepth:usesDepth];
    }
    
}

-(void)setUniformIdentity {
    NKS_SCALAR s;
    
    s.I1[0] = 0;
    [[self.activeShader uniformNamed:NKS_INT_NUM_TEXTURES] pushValue:s];
    
   // [self.activeShader setInt:0 forUniform:[nksf:@"u_%@",nks(NKS_INT_NUM_TEXTURES)]];
    
    s.M16 = M16IdentityMake();
    [[self.activeShader uniformNamed:NKS_INT_NUM_TEXTURES] pushValue:s];
    
    //[self.activeShader setMatrix4:M16IdentityMake() forUniform:[nksf:@"u_%@",nks(NKS_M16_MVP)]];
    //[self.activeShader setMatrix3:M9IdentityMake() forUniform:[nksf:@"u_%@",nks(NKS_M9_NORMAL)]];
}

// SCENE DOES NOT TRANSFORM CHILDREN

- (void)addChild:(NKNode *)child {

    NSMutableArray *temp;
    if (!_children) {
        temp = [[NSMutableArray alloc]initWithCapacity:1];
    }
    else {
        temp = [_children mutableCopy];
    }
    
    if (![temp containsObject:child]) {
        [temp addObject:child];
        [child setScene:self];
    }
    
    _children = temp;
    
}

-(M16t)globalTransform {
    return M16IdentityMake();
}

-(V3t)globalPosition {
    return V3Make(0, 0, 0);
}

-(void)alertDidSelectOption:(int)option {
    if (option == 0) {
        [self alertDidCancel];
    }
    // OVERRIDE IN SUBCLASS FOR OTHER OPTIONS
}

-(void)alertDidCancel {
    [self dismissAlertAnimated:true];
}

-(void)presentAlert:(NKAlertSprite*)alert animated:(BOOL)animated {
    
    _alertSprite = alert;
    alert.delegate = self;
    [self addChild:alert];
    
    if (animated) {
      
        [_alertSprite setPosition2d:P2Make(0, -self.size.height)];
        [_alertSprite runAction:[NKAction move2dTo:P2Make(0, 0) duration:.3]];
    }
}


-(void)dismissAlertAnimated:(BOOL)animated{
    if (animated) {
        [_alertSprite runAction:[NKAction move2dTo:P2Make(0, -self.size.height) duration:.3] completion:^{
            [self removeChild:_alertSprite];
            _alertSprite = nil;
        }];
    }
    else {
        [self removeChild:_alertSprite];
        _alertSprite = nil;
    }
}

-(void)pushMultiplyMatrix:(M16t)matrix {
    [_stack multiplyMatrix:matrix];
}

-(void)pushScale:(V3t)scale {
    [_stack appendMatrixScale:scale];
}

-(void)popMatrix {
    [_stack popMatrix];
}

-(void)keyDown:(NSUInteger)key {

    NSLog(@"key down %d", key);
    
    V3t p = _position;
    
    switch (key) {
            
        case 123:
            
            [self setPosition:V3Make(p.x-1, p.y, p.z)];
            break;
        case 124:
            
            [self setPosition:V3Make(p.x+1, p.y, p.z)];
            break;
            
        case 126: //up arrow
        
            [self setPosition:V3Make(p.x, p.y, p.z+1)];
            break;
            
        case 125: // down arrow
            [self setPosition:V3Make(p.x, p.y, p.z-1)];
            break;
            
        default:
            break;
    }
}
-(void)dispatchEvent:(NKEvent*)event {
    //NSLog(@"dispatch event for location %f %f",location.x, location.y);
    if (_useColorDetection) {
        
        CallBack callBack = ^{
            NKByteColor *hc = [[NKByteColor alloc]init];
            glReadPixels(event.screenLocation.x, event.screenLocation.y,
                         1, 1,
                         GL_RGBA, GL_UNSIGNED_BYTE, hc.bytes);
            NKNode *hit = [NKShaderManager nodeForColor:hc];
            
            if (!hit){
                hit = self;
            }
            
            event.node = hit;
            
            [hit handleEvent:event];
            
        };
        
        [_hitQueue addObject:callBack];
    }
    
    else if (_useBulletDetection) {
        // IMPLEMENT THIS
    }
}

#if TARGET_OS_IPHONE
-(void)setNkView:(NKUIView *)nkView {
    _nkView = nkView;
    loaded = true;
}
#else

-(void)setNkView:(NKView *)nkView {
    _nkView = nkView;
    loaded = true;
}
#endif

-(void)unload {
    
    glFinish();
    
    [self clear];
    
    loaded = false;
    
    _hitQueue = nil;
    
    //[self.nkView stopAnimation];
    
#if NK_LOG_METRICS
    [metricsTimer invalidate];
#endif
    
    
    for (NKNode* c in _children) {
        [c removeFromParent];
    }
    
    [NKBulletWorld reset];
    
    [_lights removeAllObjects];
    
    [_hitDetectBuffer unload];
}

#if NK_USE_MIDI
-(void)handleMidiCommand:(MIKMIDICommand *)command {
    if (_midiReceivedBlock) {
        _midiReceivedBlock(command);
    }
    else {
       // NSLog(@"received midi, provide scene a MidiReceivedBlock, or instead, implement: -(void)handleMidiCommand:(MIKMIDICommand *)command in subclass");
    }
}
#endif


@end