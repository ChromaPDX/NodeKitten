//
//  ExampleScene.m
//  Node Kitten Examples
//
//  Created by Leif Shackelford on 5/17/14.
//  Copyright (c) 2014 Chroma. All rights reserved.
//

#import "ExampleScene.h"

#define numScenes 9

#define TEST_BATCH_DRAW

@implementation ExampleScene

-(void)updateWithTimeSinceLast:(F1t)dt {
    [super updateWithTimeSinceLast:dt];
    
    if (acceleration > 0) {
        [[[self childNodeWithName:@"FL"] body] applyTorqueImpulse:V3Make(-2,0,0)];
        [[[self childNodeWithName:@"FR"] body] applyTorqueImpulse:V3Make(-2,0,0)];
    }
    else if (acceleration < 0) {
        [[[self childNodeWithName:@"FL"] body] applyCentralImpulse:V3MultiplyM16([[self childNodeWithName:@"FLS"] globalTransform], V3Make(2., 0, 0))];
        [[[self childNodeWithName:@"FR"] body] applyTorqueImpulse:V3MultiplyM16([[self childNodeWithName:@"FRS"] globalTransform], V3Make(2., 0, 0))];
    }
    if (steering < 0) { // left
        [[[self childNodeWithName:@"FLS"] body] applyTorqueImpulse:V3Make(0,.1,0)];
        [[[self childNodeWithName:@"FRS"] body] applyTorqueImpulse:V3Make(0,.1,0)];
    }
    else if (steering > 0){
        [[[self childNodeWithName:@"FLS"] body] applyTorqueImpulse:V3Make(0,-.1,0)];
        [[[self childNodeWithName:@"FRS"] body] applyTorqueImpulse:V3Make(0,-.1,0)];
    }
    else {
        
//        V3t steerForward = [[self childNodeWithName:@"FLS"] globalTransform].column3.xyz;
//        V3t vehicleForward = [[self childNodeWithName:@"BODY"] globalTransform].column3.xyz;
//        
//        F1t steeringAngle = V3DotProduct(steerForward, vehicleForward);
//        
//        if (steeringAngle > .9) {
//            [[[self childNodeWithName:@"FLS"] body] applyTorqueImpulse:V3Make(0,-.1,0)];
//        }
//        else if (steeringAngle < .9) {
//            [[[self childNodeWithName:@"FLS"] body] applyTorqueImpulse:V3Make(0,.1,0)];
//        }
    }
    //    NKLogV3(@"cam pos", self.camera.globalPosition);
    //    NKLogV3(@"cam target", self.camera.target.globalPosition);
    //NKLogM16(@"view matrix", self.camera.viewMatrix);
    
}
-(void)keyDown:(NSUInteger)key {
    
    NSLog(@"key down %lu", (unsigned long)key);
    
    if (key == 126) { // UP
        acceleration = 1;
    }
    else if (key == 125) { // DOWN
        acceleration = -1;
    }
    else if (key == 123) { // LEFT
        steering = -1;
    }
    else if (key == 124) { // RIGHT
        steering = 1;
    }
}

-(void)keyUp:(NSUInteger)key {
    
    NSLog(@"key up %lu", (unsigned long)key);
    
    if (key == 126) { // UP
        if (acceleration == 1)
            acceleration = 0;
    }
    else if (key == 125) { // DOWN
        if (acceleration == -1)
            acceleration = 0;
    }
    else if (key == 123) { // LEFT
        if (steering == -1)
            steering = 0;
    }
    else if (key == 124) { // RIGHT
        if (steering == 1)
            steering = 0;
    }
    
}
-(void)handleEvent:(NKEvent *)event {
    [super handleEvent:event];
    
    if (NKEventPhaseDoubleTap == event.phase) {
        [self unload];
        self.nkView.scene = [[ExampleScene alloc]initWithSize:self.size2d sceneChoice:0];
    }
}

-(void)addBallToNode:(NKNode*)n {
    NKNode *s = [[NKNode alloc]initWithSize:V3MakeF(1.5)];
    
    [s setPosition:V3Make(0, 2, 25)];
    s.color = NKWHITE;
    
    [n addChild:s];
    
    s.body = [[NKBulletBody alloc] initWithType:NKBulletShapeSphere Size:s.size transform:s.localTransform mass:1.];
    
    [s.body setCollisionGroup:NKCollisionFilterCharacter];
    [s.body setCollisionMask: NKCollisionFilterStatic | NKCollisionFilterWalls];
    
    [[NKBulletWorld sharedInstance] addNode:s];
    
    s.userInteractionEnabled = true;
    s.eventBlock = newEventBlock{
        
        [s.body forceAwake];
        
        // NSLog(@"boing!");
        if (NKEventPhaseBegin == event.phase) {
            [s.body setLinearVelocity:V3MakeF(0)];
            [s.body setAngularVelocity:V3MakeF(0)];
            s.positionRef = V3MultiplyM16(self.camera.viewMatrix, V3Make(event.screenLocation.x,0,-event.screenLocation.y));
        }
        else if (NKEventPhaseMove == event.phase){
            if (!V3Equal(V3MakeF(0), s.positionRef)) {
                V3t delta = V3Subtract(V3MultiplyM16(self.camera.viewMatrix, V3Make(event.screenLocation.x,0,-event.screenLocation.y)), s.positionRef);
                [s.body setLinearVelocity:V3Multiply(delta, V3MakeF(.15))];
            }
        }
        
        else if (NKEventPhaseEnd == event.phase){
            if (!V3Equal(V3MakeF(0), s.positionRef)) {
                V3t delta = V3Subtract(V3MultiplyM16(self.camera.viewMatrix, V3Make(event.screenLocation.x,0,-event.screenLocation.y)), s.positionRef);
                [s.body applyCentralImpulse:V3Negate(V3Multiply(delta, V3MakeF(10.)))];
                s.positionRef = V3MakeF(0.);
                [s runAction:[NKAction delayFor:.5] completion:^{
                    [s runAction:[NKAction fadeAlphaTo:0 duration:1.] completion:^{
                        [s removeFromParent];
                        [self addBallToNode:n];
                    }];
                }];
                
            }
            
            
        }
    };
    
}

-(instancetype)initWithSize:(S2t)size sceneChoice:(int)sceneChoice {
    
    self = [super initWithSize:size];
    
    if (self) {
        
        #pragma mark - 0 - MENU
        
        if (sceneChoice == 0){
            
            V3t sceneCoords = V3Make(0,0,0);
            V3t camCoords = V3Make(sceneCoords.x + 0 ,sceneCoords.y + 0 , sceneCoords.z + 800);
            [self.camera setPosition:camCoords];
            
            NKScrollNode *table = [[NKScrollNode alloc] initWithColor:NKCLEAR size:P2Make(600, 600)];
            [self addChild:table];
            table.delegate = self;
            table.name = @"root table";
            
            table.eventBlock = newEventBlock{
                NSLog(@"touched: %@",table.name);
            };

            for (int i = 0; i < numScenes; i++) {
                
                NKScrollNode *sc = [[NKScrollNode alloc] initWithParent:table autoSizePct:1./numScenes];
                [table addChild:sc];
                
                if (i % 2 == 0){
                sc.normalColor = NKCOLOR_RANDOM;
                }
                else {
                    sc.normalColor = NKBLACK;
                }
                
                switch (i) {
                    case 0:
                        sc.name =  [NSString stringWithFormat:@"%d - MENU", i];
                        break;
                    case 1:
                        sc.name =  [NSString stringWithFormat:@"%d - ORBIT", i];
                        break;
                    case 2:
                        sc.name =  [NSString stringWithFormat:@"%d - WIREFRAME", i];
                        break;
                    case 3:
                        sc.name =  [NSString stringWithFormat:@"%d - LIGHT TEST", i];
                        break;
                    case 4:
                        sc.name =  [NSString stringWithFormat:@"%d - PHYSICS", i];
                        break;
                    case 5:
                        sc.name =  [NSString stringWithFormat:@"%d - 3D MODELS", i];
                        break;
                    case 6:
                        sc.name =  [NSString stringWithFormat:@"%d - VIDEO", i];
                        break;
                    case 7:
                        sc.name =  [NSString stringWithFormat:@"%d - MIDI", i];
                        break;
                        
                    case 8:
                        sc.name =  [NSString stringWithFormat:@"%d - KINECT", i];
                        break;
                        
                    default:
                        sc.name =  [NSString stringWithFormat:@"%d", i];
                        break;
                }
                
                sc.eventBlock = newEventBlock{
                    if (NKEventPhaseEnd == event.phase) {
                        [sc.scene unload];
                        self.nkView.scene = [[ExampleScene alloc]initWithSize:self.size2d sceneChoice:[sc.name intValue]];
                    }
                };
                
                NKLabelNode* label = [[NKLabelNode alloc] initWithSize:sc.size2d FontNamed:@"Helvetica"];
                label.fontColor = NKWHITE;
                label.text = sc.name;
                [sc addChild:label];

            }
            
        }
        
        #pragma mark - 1 - NODE / CAMERA ANIMATION
        
        else if (sceneChoice == 1) {
            
            
           // NKTexture * tex = [NKTexture textureWithImageNamed:@"h-alpha-a.jpg"];
            NKTexture*tex;
            
            V3t sceneCoords = V3Make(0,0,-30);
            
            [self setPosition:sceneCoords];
            
            V3t camCoords = V3Make(sceneCoords.x,sceneCoords.y, sceneCoords.z + 20);
            
            [self.camera setPosition:camCoords];
            
            //self.camera.target.position = self.position;
            self.camera.target = self;
            
            [self repeatAction:[NKAction rotateYByAngle:30 duration:1.]];
            
            [self.camera runAction:[NKAction enterOrbitAtLongitude:170 latitude:70 radius:20. offset:camCoords duration:5.] completion:^{
                [self.camera repeatAction:[NKAction maintainOrbitDeltaLongitude:30 latitude:30 radius:0.0 offset:camCoords duration:1.]];
            }];
            //
            NKLightProperties p;
            
            p.isEnabled = true;
            p.isLocal = true;
            p.isSpot = false;
            
            p.ambient = V3Make(.4,.4,.4);
            p.color = V3Make(2.,2.,2.);
            p.coneDirection = V3Make(0, 0, -1);
            p.halfVector = V3MakeF(0);
            
            p.spotCosCutoff = 10.;
            p.spotExponent = 2;
            p.constantAttenuation = 1.;
            p.linearAttenuation = .05;
            p.quadraticAttenuation = 0.;
            
            _omni = [[NKLightNode alloc] initWithProperties:p];
            
            [self addChild:_omni];
            
            [_omni setPosition:V3Make(0, 20, 0)];
            
            [_omni runAction:[NKAction moveTo:V3MakeF(0) duration:2.] completion:^{
                [_omni runAction:[NKAction delayFor:.4] completion:^{
                    [_omni runAction:[NKAction enterOrbitForNode:self atLongitude:0 latitude:0 radius:10 duration:1.] completion:^{
                        [_omni repeatAction:[NKAction maintainOrbitForNode:self longitude:30 latitude:11 radius:.01 duration:.3]];
                    }];
                }];
            }];
            //
            self.drawLights = true;
            
            self.name = @"BATCH / LIGHTS TEST SCENE";
            NSLog(@"init MY SCENE");
            
            NKMeshNode *ax = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveAxes texture:nil color:NKCLEAR size:V3MakeF(10)];
            [self addChild:ax];
            
            ax.shader = [NKShaderProgram newShaderNamed:@"vertexColor" colorMode:NKS_COLOR_MODE_VERTEX numTextures:0 numLights:0 withBatchSize:0];
            
            ax.userInteractionEnabled = false;
            
#ifdef TEST_BATCH_DRAW
            NKBatchNode* emitter = [[NKBatchNode alloc]initWithPrimitive:NKPrimitiveSphere texture:tex color:NKWHITE size:V3MakeF(1)];
            [self addChild:emitter];
#endif
            
#if TARGET_OS_IPHONE
            int numSpheres = 100;
#else
            int numSpheres = 1000;
#endif
            
            for (int i = 0; i < numSpheres ; ++i){
                
                //tex = nil;
#ifdef TEST_BATCH_DRAW
                NKNode* s;
#else
                NKMeshNode *s;
#endif
                
                if (i < numSpheres / 4.) {
#ifdef TEST_BATCH_DRAW
                    s = [[NKNode alloc] initWithSize:V3MakeF((arc4random() % 100 + 1)*.01)];
                    s.color = NKWHITE;
                    [emitter addChild:s];
                    [s setTransparency:.8];
#else
                    s = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveLODSphere texture:tex color:NKCOLOR_RANDOM size:V3MakeF((arc4random() % 100 + 1)*.01)];
                    [self addChild:s];
#endif
                    
                    s.userInteractionEnabled = true;
                }
                else {
#ifdef TEST_BATCH_DRAW
                    s = [[NKNode alloc] initWithSize:V3MakeF((arc4random() % 40 + 1)*.01)];
                    s.color = NKWHITE;
                    [emitter addChild:s];
                     [s setTransparency:.8];
#else
                    s = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveLODSphere texture:tex color:NKWHITE size:V3MakeF((arc4random() % 40 + 1)*.01)];
                    [self addChild:s];
#endif
                    s.userInteractionEnabled = true;
                }
                
                [s runAction:[NKAction enterOrbitAtLongitude:arc4random() % 360 latitude:arc4random() % 360 radius:(arc4random() % 80)*.1 + 4. duration:4.] completion:^{
                    if (arc4random() % 100 > 50) {
                        //[s runAction:[NKAction resize:V3MakeF(.5) duration:4.]];
                        [s repeatAction:[NKAction rotateXByAngle:90 duration:.5]];
                    }
                    else {
                        [s repeatAction:[NKAction rotateYByAngle:90 duration:.5]];
                    }
                    [s repeatAction:[NKAction maintainOrbitDeltaLongitude:50 latitude:20. radius:0.0 duration:(arc4random() % 20+4) * .2]];
                }];
                
                s.eventBlock = newEventBlock{
                    if (event.phase == NKEventPhaseBegin) {
                        
                        if (![s.children containsObject:_omni]) {
                            //[s removeAllActions];
                            
                            self.camera.target = s;
                            
                            [_omni removeAllActions];
                            
                            //
                            [_omni runAction:[NKAction enterOrbitForNode:s atLongitude:arc4random() % 360 latitude:0 radius:s.size.width + .5 duration:1.] completion:^{
                                [_omni repeatAction:[NKAction maintainOrbitForNode:s longitude:28 latitude:2 radius:0 duration:.1]];
                            }];
                            //
                            // [s repeatAction:[NKAction maintainOrbitDeltaLongitude:30 latitude:33 radius:0. duration:(arc4random() % 10)*.5]];
                            
                            [s runAction:[NKAction delayFor:15] completion:^{
                                
                                [_omni removeAllActions];
                                [_omni runAction:[NKAction enterOrbitForNode:self atLongitude:arc4random() % 360 latitude:0 radius:10 duration:1.] completion:^{
                                    [_omni repeatAction:[NKAction maintainOrbitForNode:self longitude:28 latitude:2 radius:0 duration:.1]];
                                }];
                                
                                
                            }];
                        }
                    }
                };
                
            }
            
        }
        
        #pragma mark - 2 - WIRE FRAME
        
        else if (sceneChoice == 2){
            [self.camera setPosition:V3Make(10, 20, 10)];
            //[self.camera repeatAction:[NKAction move3dBy:V3Make(0, 1, 0) duration:.1]];
            NSLog(@"init MY SCENE");
            
            NKSpriteNode *n = [[NKSpriteNode alloc] initWithTexture:[NKTexture textureWithImageNamed:@"kitty"] color:NKWHITE size:S2Make(4, 4)];
            [self addChild:n];
            [n repeatAction:[NKAction rotateByAngles:V3Make(0, 90, 0) duration:.1]];
            
            //[n repeatAction:[NKAction rotateYByAngle:90 duration:2.]];
            
            for (int i = 0; i < 100 ; ++i){
                NKMeshNode *s = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveSphere texture:nil color:NKCOLOR_RANDOM size:V3MakeF((arc4random() % 20 + 5)*.1)];
                //s.alpha = 1.;
                s.userInteractionEnabled = true;
                //s.name = [NSString stringWithFormat:@"%d sphere %d", i,i];
                [self addChild:s];
                //s.blendMode = NKBlendModeAdd;
                s.eventBlock = newEventBlock{
                    if (event.phase == NKEventPhaseBegin) {
                        s.userInteractionEnabled = false;
                        [s removeAllActions];
                        s.drawMode = GL_TRIANGLE_STRIP;
                        [s runAction:[NKAction fadeAlphaTo:0. duration:.3]];
                        [s runAction:[NKAction scaleTo:5. duration:.3] completion:^{
                            [s removeFromParent];
                        }];
                    }
                };
                
                s.drawMode = GL_LINES;
                [s runAction:[NKAction enterOrbitAtLongitude:arc4random() % 360 latitude:arc4random() % 360 radius:arc4random() % 10+1 duration:2.] completion:^{
                    //[s repeatAction:[NKAction rotateYByAngle:90 duration:2.]];
                    [s repeatAction:[NKAction maintainOrbitDeltaLongitude:90. latitude:145. radius:0.1 duration:(arc4random() % 10+10) * .1]];
                }];
            }
            
            NKMeshNode *ax = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveAxes texture:nil color:NKCLEAR size:V3MakeF(10)];
            [self addChild:ax];
            // [ax setPosition:V3MakeF(20)];
            
            [self repeatAction:[NKAction rotateByAngles:V3Make(0, 50, 0) duration:4.]];
            
            
        }
        
        #pragma mark - 3 - LIGHT TEST
        
        else if (sceneChoice == 3){
            self.camera.position = V3Make(0, 2, 2.5);
            
            [self repeatAction:[NKAction rotateYByAngle:90 duration:8.]];
            
            //[self runAction:[NKAction move3dBy:V3Make(50, 50, 50) duration:3]];
            
            _omni = [[NKLightNode alloc] initWithDefaultProperties];
            
            _omni.scale = V3MakeF(.1);
            
            self.drawLights = true;
            //            [_omni setPosition:V3Make(0, 10, 20)];
            [self addChild:_omni];
            
            [self.camera runAction:[NKAction enterOrbitAtLongitude:170 latitude:70 radius:3. offset:V3Make(0, 2, 2.5) duration:5.] completion:^{
                [self.camera repeatAction:[NKAction maintainOrbitDeltaLongitude:30 latitude:30 radius:0.0 offset:V3Make(0, 2, 2.5) duration:1.]];
            }];
            
            [_omni setPosition:V3Make(0, 1, 2)];
            
            [_omni runAction:[NKAction moveTo:V3MakeF(0) duration:2.] completion:^{
                [_omni runAction:[NKAction delayFor:.4] completion:^{
                    [_omni runAction:[NKAction enterOrbitAtLongitude:0 latitude:30 radius:1 duration:1.] completion:^{
                        [_omni repeatAction:[NKAction maintainOrbitDeltaLongitude:30 latitude:11 radius:.0 duration:.3]];
                    }];
                }];
            }];
            
            NKMeshNode *ax = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveAxes texture:nil color:NKCLEAR size:V3MakeF(100)];
            [self addChild:ax];
            ax.shader = [NKShaderProgram newShaderNamed:@"vertexColor" colorMode:NKS_COLOR_MODE_VERTEX numTextures:0 numLights:0 withBatchSize:0];
            
            ax.userInteractionEnabled = false;
            
            AIScene* scene = [[AIScene alloc]initWithFile:@"duck.dae" normalize:.5] ;
            
            NKMeshNode *ground = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveCube texture:nil color:[NKByteColor colorWithRed:50 green:50 blue:50 alpha:255] size:V3Make(100, .01, 100)];
            // [self addChild:ground];
            
            ground.body = [[NKBulletBody alloc] initWithType:NKBulletShapeBox Size:ground.size transform:ground.localTransform mass:0];
            
            [ground.body setCollisionGroup:NKCollisionFilterStatic];
            [ground.body setCollisionMask: NKCollisionFilterCharacter | NKCollisionFilterWalls];
            
            [[NKBulletWorld sharedInstance] addNode:ground];
            
            [ground runAction:[NKAction rotateXByAngle:-30 duration:3.]];
            
            for (int i = 0; i <scene.meshes.count; i++){
                
                NKMeshNode *node = scene.meshes[i];
                
                [node setPosition:V3Add(node.position, V3Make(0, 0, 0))];
                
                [self addChild:node];
                if (i < 4) {
                    //if (i == 0 || i == 1 || i == 3) [node removeFromParent];
                    //[node repeatAction:[NKAction rotateYByAngle:-60 duration:1.]];
                    
                    //                    node.body = [[NKBulletBody alloc]initWithType:NKBulletShapeBox Size:node.size transform:node.globalTransform mass:1.];
                    //                    [node.body setCollisionGroup:NKCollisionFilterCharacter];
                    //                    [node.body setCollisionMask: NKCollisionFilterStatic | NKCollisionFilterWalls];
                    //
                    //                    [[NKBulletWorld sharedInstance] addNode:node];
                    
                }
            }

        }
        
        #pragma mark - 4 - PHYSICS
        
        else if (sceneChoice == 4) { // BULLET TEST
            
            [self.camera setPosition:V3Make(0, 10, 40)];
            
            _omni = [[NKLightNode alloc] initWithDefaultProperties];

            _omni.pointer->linearAttenuation = .01;
            
            [_omni setPosition:V3Make(0, 10, 20)];
            [self addChild:_omni];
//
            
            for (int i = 0; i < 5; i++) {
                NKMeshNode *ground = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveCube texture:nil color:NKWHITE size:V3Make(100, .01, 100)];
                [self addChild:ground];
                
                switch (i) {
                    case 0:
                        [ground setOrientationEuler:V3Make(0,0,10)];
                        break;
                    case 1:
                        [ground setOrientationEuler:V3Make(60,0,0)];
                        [ground setPosition:V3Make(0, 0, -20)];
                        break;
                    case 2:
                        [ground setOrientationEuler:V3Make(0,0,-10)];
                        break;
                    case 3:
                        ground.size = V3Make(30, .01, 3);
                        ground.position = V3Make(0, 2., 0);
                        //[ground setOrientationEuler:V3Make(0,0,0)];
                        break;
                    case 4:
                        [ground setOrientationEuler:V3Make(-20,0,0)];
                        ground.position = V3Make(0, 0, 30);
                        break;
                        
                    default:
                        break;
                }
                ground.body = [[NKBulletBody alloc] initWithType:NKBulletShapeBox Size:ground.size transform:ground.localTransform mass:0];
                
                [ground.body setCollisionGroup:NKCollisionFilterStatic];
                [ground.body setCollisionMask: NKCollisionFilterCharacter | NKCollisionFilterWalls];
                
                [[NKBulletWorld sharedInstance] addNode:ground];
            }
            
            NKBatchNode *batch = [[NKBatchNode alloc]initWithPrimitive:NKPrimitiveCube texture:[NKTexture textureWithImageNamed:nil] color:NKWHITE size:V3MakeF(.5)];
            
            [self addChild:batch];
            
#if TARGET_OS_IPHONE
            int numSpheres = 16;
#else
            int numSpheres = 32;
#endif
            
            for (int i = 0; i < numSpheres*2; i++){
                NKNode *s = [[NKNode alloc]initWithSize:V3Make(1.,1.5,1.)];
                s.color = NKCOLOR_RANDOM;
                [s setPosition:V3Make((i % 8) * s.size.width * 2.25 - (s.size.width*8), (i/8) * s.size.height * 2.1 + 2.2, 0)];
                [batch addChild:s];
                
                s.body = [[NKBulletBody alloc] initWithType:NKBulletShapeBox Size:s.size transform:s.localTransform mass:1.];
                
                [s.body setCollisionGroup:NKCollisionFilterWalls];
                [s.body setCollisionMask: NKCollisionFilterStatic | NKCollisionFilterWalls | NKCollisionFilterCharacter];
                
                [[NKBulletWorld sharedInstance] addNode:s];
                
//                s.eventBlock = newEventBlock{
//                    // NSLog(@"boing!");
//                    [s.body forceAwake];
//                    [s.body applyCentralForce:V3Make(0, 200., 0)];
//                };
            }
            
            NKBatchNode *batch2 = [[NKBatchNode alloc]initWithPrimitive:NKPrimitiveSphere texture:[NKTexture textureWithImageNamed:@"ball_Texture.png"] color:NKWHITE size:V3MakeF(1.)];
            
            [self addChild:batch2];
            
            [self addBallToNode:batch2];
            
        }
        
//#pragma mark - 5 - OBJ
//        else if (sceneChoice == 5) { // OBJ
//            
//            //[self.scene repeatAction:[NKAction rotateYByAngle:45 duration:2.]];
//            
//            [self.camera setPosition:V3Make(0, 10, 20)];
//            
//            NKLightProperties p;
//            
//            p.isEnabled = true;
//            p.isLocal = true;
//            p.isSpot = false;
//            
//            p.ambient = V3Make(.2,.2,.4);
//            p.color = V3Make(1.,1.,1.);
//            p.coneDirection = V3Make(0, 0, -1);
//            p.halfVector = V3MakeF(0);
//            
//            p.spotCosCutoff = 10.;
//            p.spotExponent = 2;
//            p.constantAttenuation = 1.;
//            p.linearAttenuation = .1;
//            p.quadraticAttenuation = 0.;
//            
//            _omni = [[NKLightNode alloc] initWithProperties:p];
//            
//            [self addChild:_omni];
//
//            [_omni runAction:[NKAction moveTo:V3MakeF(0) duration:2.] completion:^{
//                [_omni runAction:[NKAction delayFor:.4] completion:^{
//                    [_omni runAction:[NKAction enterOrbitAtLongitude:0 latitude:0 radius:10 duration:1.] completion:^{
//                        [_omni repeatAction:[NKAction maintainOrbitDeltaLongitude:30 latitude:11 radius:.01 duration:.3]];
//                    }];
//                }];
//            }];
//
//            NKMeshNode* newMesh;
//            
//            newMesh = [[NKMeshNode alloc]initWithObjNamed:@"teapot" withSize:V3MakeF(5.) normalize:true anchor:true];
//            [self addChild:newMesh];
//            [newMesh setPosition:V3Make(0,0,0)];
//            [newMesh repeatAction:[NKAction rotateXByAngle:90 duration:1.]];
//            
//            newMesh = [[NKMeshNode alloc]initWithObjNamed:@"trashbin" withSize:V3MakeF(5.) normalize:true anchor:true];
//            newMesh.color = NKRED;
//            
//            [self addChild:newMesh];
//            [newMesh setPosition:V3Make(0,10,0)];
//            [newMesh repeatAction:[NKAction rotateXByAngle:90 duration:1.]];
//            
//            newMesh = [[NKMeshNode alloc]initWithObjNamed:@"mushrooms" withSize:V3MakeF(5.) normalize:true anchor:true];
//            newMesh.texture = [NKTexture textureWithImageNamed:@"shroom.tif"];
//            [self addChild:newMesh];
//            
//            [newMesh setPosition:V3Make(0,-10,0)];
//            [newMesh repeatAction:[NKAction rotateXByAngle:90 duration:1.]];
//
//            
//        }
        
#pragma mark - 5 - ASSIMP
        
        else if (sceneChoice == 5) { // ASSIMP

            self.camera.position = V3Make(0, 1.5, 4);
            
            //[self repeatAction:[NKAction rotateByAngle:90 duration:1.]];
            
            NKMeshNode *ax = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveAxes texture:nil color:NKCLEAR size:V3MakeF(100)];
            [self addChild:ax];
            ax.shader = [NKShaderProgram newShaderNamed:@"vertexColor" colorMode:NKS_COLOR_MODE_VERTEX numTextures:0 numLights:0 withBatchSize:0];
            
            ax.userInteractionEnabled = false;
            
            AIScene* scene = [[AIScene alloc]initWithFile:@"jeep1a.fbx" normalize:1.] ;

            NKMeshNode *ground = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveCube texture:[NKTexture textureWithImageNamed:@"earthmap.png"] color:[NKByteColor colorWithRed:50 green:50 blue:50 alpha:255] size:V3Make(100, .01, 100)];
            [ground setPosition:V3Make(0, -.5, 0)];
            [self addChild:ground];
            
            ground.body = [[NKBulletBody alloc] initWithType:NKBulletShapeBox Size:ground.size transform:ground.localTransform mass:0];
            
            [ground.body setCollisionGroup:NKCollisionFilterStatic];
            [ground.body setCollisionMask: NKCollisionFilterCharacter | NKCollisionFilterWalls];
            
            [[NKBulletWorld sharedInstance] addNode:ground];
            
            
            for (int i = 0; i < scene.meshes.count; i++){
                
                NKMeshNode *node = scene.meshes[i];
                
                [node setPosition:V3Add(node.position, V3Make(0, 1, 0))];
                                          
                [self addChild:node];
                
                node.drawBoundingBox = true;
                
                if (i < 4){
                    node.body = [[NKBulletBody alloc]initWithType:NKBulletShapeXCylinder Size:node.size transform:node.globalTransform mass:5.];
                    [node.body setCollisionGroup:NKCollisionFilterCharacter];
                    [node.body setCollisionMask: NKCollisionFilterStatic | NKCollisionFilterWalls];
                    
                    [[NKBulletWorld sharedInstance] addNode:node];
                }
                
                if (i == 6) {
                    node.name = @"BODY";
                    node.body = [[NKBulletBody alloc]initWithType:NKBulletShapeBox Size:node.size transform:node.globalTransform mass:50.];
                    [node.body setCollisionGroup:NKCollisionFilterCharacter];
                    [node.body setCollisionMask: NKCollisionFilterStatic | NKCollisionFilterWalls];
                    [[NKBulletWorld sharedInstance] addNode:node];
                    
                    //[self.camera setParent:node];
                    
                    [self.camera runAction:[NKAction enterOrbitForNode:node atLongitude:arc4random() % 360 latitude:0 radius:1. duration:.5 offset:V3Make(0, 2, 3)] completion:^{
                        [self.camera  repeatAction:[NKAction maintainOrbitForNode:node longitude:28 latitude:2 radius:0 duration:1. offset:V3Make(0, 2, 3)]];
                    }];
                    
                    [self.camera setTarget:node];
                    
                    _omni = [[NKLightNode alloc] initWithDefaultProperties];
                    
                    _omni.pointer->linearAttenuation = .001;
                    
                    [_omni setPosition:V3Make(0, 3, 3)];
                    
                    for (int i = 0; i < 4; i++) {
                        NKNode* wheel = scene.meshes[i];
                        
                        [wheel.body setFriction:.9];
                        [wheel.body setDamping:0.3 angular:.95];
                        
                        if (i == 0 || i == 2) { //
                            // make steering joint
                            
                            NKMeshNode *steering = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveCube texture:nil color:nil size:V3MakeF(.15)];
                            [steering setPosition:wheel.globalPosition];
                            [self addChild:steering];
                            
                            wheel.name = @"FL";
                            steering.name = @"FLS";
                            if (i == 0) {
                                wheel.name = @"FR";
                                steering.name = @"FRS";
                            }
           
                            
                            steering.body = [[NKBulletBody alloc]initWithType:NKBulletShapeBox Size:steering.size transform:steering.globalTransform mass:2.];
                            [steering.body setDamping:.98 angular:.98];
                            [steering.body setCollisionGroup:NKCollisionFilterCharacter];
                            [[NKBulletWorld sharedInstance] addNode:steering];
                            // attach steering
                            [node.body addWheelConstraintAtPosition:V3Subtract(steering.globalPosition,node.globalPosition) toNode:steering atPosition:V3MakeF(0) limits:V6Make(0, -1., 0 ,0 ,1., 0)];
                            
                            // attach wheel
                            [steering.body addWheelConstraintAtPosition:V3MakeF(0) toNode:wheel atPosition:V3MakeF(0) limits:V6Make(1, 0, 0, 0 ,0, 0)];
                        }
                        else {
                           // [wheel removeFromParent];
                            [node.body addWheelConstraintAtPosition:V3Subtract(wheel.position,node.position) toNode:wheel atPosition:V3MakeF(0) limits:V6Make(1, 0, 0, 0 ,0, 0)];
                        }
                      
                    
                    }
                }

            }
            
            [ground runAction:[NKAction rotateXByAngle:-30 duration:3.]];
            //[self.camera runAction:[NKAction move3dByX:0 Y:100 Z:-100 duration:10.]];
            
        }
        
#pragma mark - 6 - VIDEO NODE
        
        else if (sceneChoice == 6) {
            
            self.camera.position = V3Make(0, 0, 20);
            
            //[self repeatAction:[NKAction rotateYByAngle:90 duration:1.]];
            
//            _omni = [[NKLightNode alloc] initWithDefaultProperties];
//            
//            [_omni runAction:[NKAction moveTo:V3MakeF(0) duration:2.] completion:^{
//                [_omni runAction:[NKAction delayFor:.4] completion:^{
//                    [_omni runAction:[NKAction enterOrbitAtLongitude:0 latitude:0 radius:10 duration:1.] completion:^{
//                        [_omni repeatAction:[NKAction maintainOrbitDeltaLongitude:30 latitude:11 radius:.01 duration:.3]];
//                    }];
//                }];
//            }];
//
//            self.drawLights = true;
//            
//            [self addChild:_omni];
            
//            NKMeshNode *videoNode = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveRect texture:[NKVideoTexture textureWithVideoNamed:@"carousel_360-640.mov"] color:NKWHITE size:V3Make(6.,8.,1.)];
//
//            [videoNode setPosition:V3Make(0, 7, 0)];
//
//            [self addChild:videoNode];
    
            
             NKMeshNode *videoNode2 = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveCube texture:[NKVideoTexture textureWithVideoNamed:@"slitscan-fall-640-360.mov"] color:NKWHITE size:V3MakeF(3.)];
            
            [videoNode2 setPosition:V3Make(0, -7, 0)];
            
            [videoNode2 repeatAction:[NKAction rotateByAngles:V3Make(30, 12, 20) duration:1.]];
            
            [self addChild:videoNode2];
            
            NKMeshNode *videoNode3 = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveSphere texture:[NKVideoTexture textureWithCameraSource:nil] color:NKWHITE size:V3MakeF(6.)];
            
            [videoNode3 repeatAction:[NKAction rotateByAngles:V3Make(0, 20, 0) duration:1.]];
            [videoNode3 setPosition:V3Make(0, 4, 0)];
            
            
            [self addChild:videoNode3];
        }
        
#pragma mark - 7 - PARTICLES
        
        else if (sceneChoice == 7) { // EMITTERNODE
            
            
            self.camera.position = V3Make(0, 0, 4);
       
            NKEmitterNode *emitter = [[NKEmitterNode alloc]initWithSize:V3MakeF(1.)];
            
            [self addChild:emitter];
            
        }
        
        
        
//#if NK_USE_KINECT
//#pragma mark - 8 - KINECT
//        
//        else if (sceneChoice == 8) { // EMITTERNODE
//            
//            
//            self.camera.position = V3Make(0, 0, 4);
//            
//            [NKKinectManager sharedInstance];
//        }
//#endif

        
    }
    

    return self;
}


@end
