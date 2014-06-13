//
//  MyScene.m
//  EMA Stage
//
//  Created by Leif Shackelford on 5/17/14.
//  Copyright (c) 2014 EMA. All rights reserved.
//

#import "ExampleScene.h"

#define numScenes 7

#define TEST_BATCH_DRAW

@implementation ExampleScene

-(instancetype)initWithSize:(S2t)size sceneChoice:(int)sceneChoice {
    
    self = [super initWithSize:size];
    
    if (self) {
        
        #pragma mark - 0 - MENU
        
        if (sceneChoice == 0){
            
            V3t sceneCoords = V3Make(0,0,0);
            V3t camCoords = V3Make(sceneCoords.x + 0 ,sceneCoords.y + 0 , sceneCoords.z + 800);
            [self.camera setPosition3d:camCoords];
            
            NKScrollNode *table = [[NKScrollNode alloc] initWithColor:NKCLEAR size:P2Make(400, 600)];
            [self addChild:table];
            table.delegate = self;
            table.name = @"root table";
            
            table.eventBlock = newEventBlock{
                NSLog(@"touched: %@",table.name);
            };

            for (int i = 0; i < numScenes; i++) {
                
                NKScrollNode *sc = [[NKScrollNode alloc] initWithParent:table autoSizePct:.2];
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
                        sc.name =  [NSString stringWithFormat:@"%d - BIG CUBE", i];
                        break;
                    case 4:
                        sc.name =  [NSString stringWithFormat:@"%d - PHYSICS", i];
                        break;
                    case 5:
                        sc.name =  [NSString stringWithFormat:@"%d - OBJ", i];
                        break;
                    case 6:
                        sc.name =  [NSString stringWithFormat:@"%d - PRIMITIVES", i];
                        break;
                        
                    default:
                        sc.name =  [NSString stringWithFormat:@"%d", i];

                        break;
                }
                //sc.name =
                
                sc.eventBlock = newEventBlock{
                    if (NKEventTypeEnd == eventType) {
                        [sc.scene unload];
                        self.nkView.scene = [[ExampleScene alloc]initWithSize:self.size sceneChoice:[sc.name intValue]];
                    }
                };
                
                NKLabelNode* label = [[NKLabelNode alloc] initWithSize:sc.size FontNamed:@"Helvetica"];
                label.fontColor = NKWHITE;
                label.text = sc.name;
                [sc addChild:label];

            }
            
        }
        
        #pragma mark - 1 - NODE / CAMERA ANIMATION
        
        else if (sceneChoice == 1) {
            
            NKTexture * tex = [NKTexture textureWithImageNamed:@"earthmap.png"];
            //NKTexture*tex;
            
            V3t sceneCoords = V3Make(0,0,-30);
            
            [self setPosition3d:sceneCoords];
            
            V3t camCoords = V3Make(sceneCoords.x,sceneCoords.y, sceneCoords.z + 20);
            
            [self.camera setPosition3d:camCoords];
            
            self.camera.target.position3d = self.position3d;
            self.camera.target = self;
            
            [self.camera runAction:[NKAction enterOrbitAtLongitude:170 latitude:70 radius:20. offset:camCoords duration:5.] completion:^{
                [self.camera repeatAction:[NKAction maintainOrbitDeltaLongitude:30 latitude:30 radius:0.0 offset:camCoords duration:1.]];
            }];
            //
            NKLightProperties p;
            
            p.isEnabled = true;
            p.isLocal = true;
            p.isSpot = false;
            
            p.ambient = V3Make(.2,.2,.4);
            p.color = V3Make(1.,1.,1.);
            p.coneDirection = V3Make(0, 0, -1);
            p.halfVector = V3MakeF(0);
            
            p.spotCosCutoff = 10.;
            p.spotExponent = 2;
            p.constantAttenuation = 1.;
            p.linearAttenuation = .1;
            p.quadraticAttenuation = 0.;
            
            _omni = [[NKLightNode alloc] initWithProperties:p];
            
            [self addChild:_omni];
            
            [_omni setPosition3d:V3Make(0, 20, 0)];
            
            [_omni runAction:[NKAction move3dTo:V3MakeF(0) duration:2.] completion:^{
                [_omni runAction:[NKAction delayFor:.4] completion:^{
                    [_omni runAction:[NKAction enterOrbitAtLongitude:0 latitude:0 radius:10 duration:1.] completion:^{
                        [_omni repeatAction:[NKAction maintainOrbitDeltaLongitude:30 latitude:11 radius:.01 duration:.3]];
                    }];
                }];
            }];
            //
            self.drawLights = true;
            
            NKMeshNode *s = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveCube texture:tex color:NKWHITE size:V3MakeF(3.)];
            
            [self addChild:s];
            
            [s runAction:[NKAction rotateXByAngle:45 duration:2.] completion:^{
                [s repeatAction:[NKAction rotateYByAngle:90 duration:2.]];
            }];
            
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
            int numSpheres = 200;
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
#else
                    s = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveLODSphere texture:tex color:NKCOLOR_RANDOM size:V3MakeF((arc4random() % 100 + 1)*.01)];
                    [self addChild:s];
#endif
                    
                    s.userInteractionEnabled = true;
                }
                else {
#ifdef TEST_BATCH_DRAW
                    s = [[NKNode alloc] initWithSize:V3MakeF((arc4random() % 40 + 1)*.01)];
                    s.color = NKRED;
                    [emitter addChild:s];
#else
                    s = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveLODSphere texture:tex color:NKWHITE size:V3MakeF((arc4random() % 40 + 1)*.01)];
                    [self addChild:s];
#endif
                    s.userInteractionEnabled = true;
                }
                
                [s runAction:[NKAction enterOrbitAtLongitude:arc4random() % 360 latitude:arc4random() % 360 radius:(arc4random() % 80)*.1 + 4. duration:4.] completion:^{
                    if (arc4random() % 100 > 50) {
                        //[s runAction:[NKAction resize3d:V3MakeF(.5) duration:4.]];
                        [s repeatAction:[NKAction rotateXByAngle:90 duration:.5]];
                    }
                    else {
                        [s repeatAction:[NKAction rotateYByAngle:90 duration:.5]];
                    }
                    [s repeatAction:[NKAction maintainOrbitDeltaLongitude:50 latitude:20. radius:0.0 duration:(arc4random() % 20+4) * .2]];
                }];
                
                s.eventBlock = newEventBlock{
                    if (eventType == NKEventTypeBegin) {
                        
                        if (![s.children containsObject:_omni]) {
                            //[s removeAllActions];
                            
                            self.camera.target = s;
                            
                            [_omni removeAllActions];
                            
                            [s addChild:_omni];
                            //
                            [_omni runAction:[NKAction enterOrbitAtLongitude:arc4random() % 360 latitude:0 radius:s.size.width + .5 duration:1.] completion:^{
                                [_omni repeatAction:[NKAction maintainOrbitDeltaLongitude:28 latitude:2 radius:0 duration:.1]];
                            }];
                            //
                            // [s repeatAction:[NKAction maintainOrbitDeltaLongitude:30 latitude:33 radius:0. duration:(arc4random() % 10)*.5]];
                            
                            [s runAction:[NKAction delayFor:15] completion:^{
                                
                                if ([s.children containsObject:_omni]) {
                                    [_omni removeAllActions];
                                    [self addChild:_omni];
                                    [_omni runAction:[NKAction enterOrbitAtLongitude:arc4random() % 360 latitude:0 radius:10. duration:1.] completion:^{
                                        [_omni repeatAction:[NKAction maintainOrbitDeltaLongitude:28 latitude:2 radius:0 duration:.5]];
                                    }];
                                }
                                
                            }];
                        }
                    }
                };
                
            }
            
        }
        
        #pragma mark - 2 - WIRE FRAME
        
        else if (sceneChoice == 2){
            [self.camera setPosition3d:V3Make(10, 20, 10)];
            //[self.camera repeatAction:[NKAction move3dBy:V3Make(0, 1, 0) duration:.1]];
            NSLog(@"init MY SCENE");
            
            NKSpriteNode *n = [[NKSpriteNode alloc] initWithTexture:[NKTexture textureWithImageNamed:@"kitty"] color:NKWHITE size:S2Make(4, 4)];
            [self addChild:n];
            [n repeatAction:[NKAction rotate3dByAngle:V3Make(0, 90, 0) duration:.1]];
            
            //[n repeatAction:[NKAction rotateYByAngle:90 duration:2.]];
            
            for (int i = 0; i < 100 ; ++i){
                NKMeshNode *s = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveSphere texture:nil color:NKCOLOR_RANDOM size:V3MakeF((arc4random() % 20 + 5)*.1)];
                //s.alpha = 1.;
                s.userInteractionEnabled = true;
                //s.name = [NSString stringWithFormat:@"%d sphere %d", i,i];
                [self addChild:s];
                //s.blendMode = NKBlendModeAdd;
                s.eventBlock = newEventBlock{
                    if (eventType == NKEventTypeBegin) {
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
            // [ax setPosition3d:V3MakeF(20)];
            
            [self repeatAction:[NKAction rotate3dByAngle:V3Make(0, 50, 0) duration:4.]];
            
            
        }
        
        #pragma mark - 3 - LIGHT CUBE
        
        else if (sceneChoice == 3){
            // NKTexture * tex = [NKTexture textureWithImageNamed:@"earthmap.png"];
            NKTexture*tex;
            
            V3t sceneCoords = V3Make(100,-100,30);
            
            [self setPosition3d:sceneCoords];
            
            V3t camCoords = V3Make(sceneCoords.x+15,sceneCoords.y+20, sceneCoords.z - 50);
            
            [self.camera setPosition3d:camCoords];
            
            self.camera.target.position3d = self.position3d;
            self.camera.target = self;
            
            //            [self.camera runAction:[NKAction enterOrbitAtLongitude:170 latitude:70 radius:40. offset:camCoords duration:5.] completion:^{
            //                [self.camera repeatAction:[NKAction maintainOrbitDeltaLongitude:30 latitude:30 radius:0.0 offset:camCoords duration:1.]];
            //            }];
            
            NKLightProperties p;
            
            p.isEnabled = true;
            p.isLocal = true;
            p.isSpot = false;
            
            p.ambient = V3Make(.5,.5,.4);
            p.color = V3Make(1.,1.,1.);
            p.coneDirection = V3Make(0, 0, -1);
            p.halfVector = V3MakeF(10);
            
            p.spotCosCutoff = 10.;
            p.spotExponent = 2;
            p.constantAttenuation = 0.;
            p.linearAttenuation = .0;
            p.quadraticAttenuation = .05;
            
            _omni = [[NKLightNode alloc] initWithProperties:p];
            
            [self addChild:_omni];
            
            [_omni setPosition3d:V3Make(0, 20, 0)];
            [_omni runAction:[NKAction move3dTo:V3MakeF(0) duration:2.] completion:^{
                [_omni runAction:[NKAction delayFor:.4] completion:^{
                    [_omni runAction:[NKAction enterOrbitAtLongitude:0 latitude:0 radius:15 duration:1.] completion:^{
                        [_omni repeatAction:[NKAction maintainOrbitDeltaLongitude:30 latitude:11 radius:.01 duration:.3]];
                    }];
                }];
            }];
            
            self.drawLights = true;
            
            NKMeshNode *s = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveCube texture:nil color:NKWHITE size:V3MakeF(10.)];
            
            [self addChild:s];
            
            [s runAction:[NKAction rotateXByAngle:45 duration:2.] completion:^{
                [s repeatAction:[NKAction rotateYByAngle:90 duration:2.]];
            }];
            
            self.name = @"BATCH / LIGHTS TEST SCENE";
            NSLog(@"init MY SCENE");
        }
        
        #pragma mark - 4 - PHYSICS
        
        else if (sceneChoice == 4) { // BULLET TEST
            
            //[self.scene repeatAction:[NKAction rotateYByAngle:45 duration:4.]];
            
            
            [self.camera setPosition3d:V3Make(0, 10, 40)];
            
            NKLightProperties p;
            
            p.isEnabled = true;
            p.isLocal = true;
            p.isSpot = false;
            
            p.ambient = V3Make(.2,.2,.4);
            p.color = V3Make(1.,1.,1.);
            p.coneDirection = V3Make(0, 0, -1);
            p.halfVector = V3MakeF(0);
            
            p.spotCosCutoff = 10.;
            p.spotExponent = 2;
            p.constantAttenuation = 1.;
            p.linearAttenuation = .01;
            p.quadraticAttenuation = 0.;
            
            _omni = [[NKLightNode alloc] initWithProperties:p];
            //self.drawLights = true;
//            [_omni runAction:[NKAction move3dTo:V3MakeF(0) duration:.01] completion:^{
//                [_omni runAction:[NKAction delayFor:.4] completion:^{
//                    [_omni runAction:[NKAction enterOrbitAtLongitude:40 latitude:-40 radius:20 duration:1.] completion:^{
//                        [_omni repeatAction:[NKAction maintainOrbitDeltaLongitude:10 latitude:0 radius:0 duration:.1]];
//                    }];
//                }];
//            }];
            
            [_omni setPosition3d:V3Make(0, 10, 20)];
            [self addChild:_omni];
            
            
            for (int i = 0; i < 5; i++) {
                NKMeshNode *ground = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveCube texture:nil color:NKWHITE size:V3Make(100, .01, 100)];
                [self addChild:ground];
                
                switch (i) {
                    case 0:
                        [ground setOrientationEuler:V3Make(0,0,10)];
                        break;
                    case 1:
                        [ground setOrientationEuler:V3Make(60,0,0)];
                        [ground setPosition3d:V3Make(0, 0, -20)];
                        break;
                    case 2:
                        [ground setOrientationEuler:V3Make(0,0,-10)];
                        break;
                    case 3:
                        ground.size3d = V3Make(30, .01, 3);
                        ground.position3d = V3Make(0, 2., 0);
                        //[ground setOrientationEuler:V3Make(0,0,0)];
                        break;
                    case 4:
                        [ground setOrientationEuler:V3Make(-20,0,0)];
                        ground.position3d = V3Make(0, 0, 30);
                        break;
                        
                    default:
                        break;
                }
                ground.body = [[NKBulletBody alloc] initWithType:NKBulletShapeBox Size:ground.size3d transform:ground.localTransformMatrix mass:0];
                [[NKBulletWorld sharedInstance] addNode:ground];
            }
            
            //            NKMeshNode *sphere = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveSphere texture:[NKTexture textureWithImageNamed:@"ball_Texture.png"] color:NKWHITE size:V3MakeF(3)];
            //            [self addChild:sphere];
            //
            //            sphere.body = [[NKBulletBody alloc] initWithType:NKBulletShapeSphere Size:sphere.size3d transform:sphere.localTransformMatrix mass:0.];
            //            [[NKBulletWorld sharedInstance] addNode:sphere];
            //
            //
            
            NKBatchNode *batch = [[NKBatchNode alloc]initWithPrimitive:NKPrimitiveCube texture:[NKTexture textureWithImageNamed:nil] color:NKWHITE size:V3MakeF(.5)];
            
          //  NKBatchNode *batch = [[NKBatchNode alloc ]initWithObjNamed:@"trashbin" withSize:V3MakeF(1.) normalize:true anchor:true];
            [self addChild:batch];
            
#if TARGET_OS_IPHONE
            int numSpheres = 16;
#else
            int numSpheres = 32;
#endif
            
            for (int i = 0; i < numSpheres*2; i++){
                NKNode *s = [[NKNode alloc]initWithSize:V3Make(1.,1.5,1.)];
                s.color = NKCOLOR_RANDOM;
                [s setPosition3d:V3Make((i % 8) * s.size.width * 2.25 - (s.size.width*8), (i/8) * s.size.height * 2.1 + 2.2, 0)];
                [batch addChild:s];
                
                s.body = [[NKBulletBody alloc] initWithType:NKBulletShapeBox Size:s.size3d transform:s.localTransformMatrix mass:1.];
                [[NKBulletWorld sharedInstance] addNode:s];
                
                s.userInteractionEnabled = true;
//                s.eventBlock = newEventBlock{
//                    // NSLog(@"boing!");
//                    [s.body forceAwake];
//                    [s.body applyCentralForce:V3Make(0, 200., 0)];
//                };
            }
            
            NKBatchNode *batch2 = [[NKBatchNode alloc]initWithPrimitive:NKPrimitiveSphere texture:[NKTexture textureWithImageNamed:@"ball_Texture.png"] color:NKWHITE size:V3MakeF(1.)];
            
            [self addChild:batch2];
            
            [self addBallToNode:batch2];
//            [self addBallToNode:batch2];
//            [self addBallToNode:batch2];
//            for (int i = 0; i < numSpheres/4; i++){
//                NKNode *s = [[NKNode alloc]initWithSize:V3MakeF(1.5)];
//                [s setPosition3d:V3Make(arc4random() % 100 * .1 - 5., arc4random() % 100 * .1 + 1, arc4random() % 200 * .1 + 8.)];
//                s.color = NKWHITE;
//                [batch2 addChild:s];
//                
//                s.body = [[NKBulletBody alloc] initWithType:NKBulletShapeSphere Size:s.size3d transform:s.localTransformMatrix mass:1.];
//                [[NKBulletWorld sharedInstance] addNode:s];
//                
//                s.userInteractionEnabled = true;
//                s.eventBlock = newEventBlock{
//                    
//                    [s.body forceAwake];
//                    
//                    // NSLog(@"boing!");
//                    if (NKEventTypeBegin == eventType) {
//                        [s.body setLinearVelocity:V3MakeF(0)];
//                        [s.body setAngularVelocity:V3MakeF(0)];
//                        s.positionRef = V3MultiplyM16(self.camera.viewMatrix, V3Make(location.x,0,-location.y));
//                    }
//                    else if (NKEventTypeMove == eventType){
//                        if (!V3Equal(V3MakeF(0), s.positionRef)) {
//                            V3t delta = V3Subtract(V3MultiplyM16(self.camera.viewMatrix, V3Make(location.x,0,-location.y)), s.positionRef);
//                            [s.body setLinearVelocity:V3Multiply(delta, V3MakeF(.25))];
//                            //[s setPosition3d:s.position3d];
//                            //[s setPosition3d:V3Add(s.position3d,V3Multiply(V3Make(delta.x, 0, delta.y), V3MakeF(.01)))];
//                        }
//                    }
//                    
//                    else if (NKEventTypeEnd == eventType){
//                        if (!V3Equal(V3MakeF(0), s.positionRef)) {
//                            V3t delta = V3Subtract(V3MultiplyM16(self.camera.viewMatrix, V3Make(location.x,0,-location.y)), s.positionRef);
//                            [s.body applyCentralImpulse:V3Negate(V3Multiply(delta, V3MakeF(50.)))];
//                            s.positionRef = V3MakeF(0.);
//                        }
//                    }
//                };
//            }
            
        }
        
#pragma mark - 5 - OBJ
        else if (sceneChoice == 5) { // OBJ
            
            //[self.scene repeatAction:[NKAction rotateYByAngle:45 duration:2.]];
            
            [self.camera setPosition3d:V3Make(0, 10, 20)];
            
            NKLightProperties p;
            
            p.isEnabled = true;
            p.isLocal = true;
            p.isSpot = false;
            
            p.ambient = V3Make(.2,.2,.4);
            p.color = V3Make(1.,1.,1.);
            p.coneDirection = V3Make(0, 0, -1);
            p.halfVector = V3MakeF(0);
            
            p.spotCosCutoff = 10.;
            p.spotExponent = 2;
            p.constantAttenuation = 1.;
            p.linearAttenuation = .1;
            p.quadraticAttenuation = 0.;
            
            _omni = [[NKLightNode alloc] initWithProperties:p];
            
            [self addChild:_omni];

            [_omni runAction:[NKAction move3dTo:V3MakeF(0) duration:2.] completion:^{
                [_omni runAction:[NKAction delayFor:.4] completion:^{
                    [_omni runAction:[NKAction enterOrbitAtLongitude:0 latitude:0 radius:10 duration:1.] completion:^{
                        [_omni repeatAction:[NKAction maintainOrbitDeltaLongitude:30 latitude:11 radius:.01 duration:.3]];
                    }];
                }];
            }];
            
            NKMeshNode* newMesh;
            
            newMesh = [[NKMeshNode alloc]initWithObjNamed:@"teapot" withSize:V3MakeF(5.) normalize:true anchor:true];
            [self addChild:newMesh];
            [newMesh setPosition3d:V3Make(0,0,0)];
            [newMesh repeatAction:[NKAction rotateXByAngle:90 duration:1.]];
            
            newMesh = [[NKMeshNode alloc]initWithObjNamed:@"trashbin" withSize:V3MakeF(5.) normalize:true anchor:true];
            newMesh.color = NKRED;
            
            [self addChild:newMesh];
            [newMesh setPosition3d:V3Make(0,10,0)];
            [newMesh repeatAction:[NKAction rotateXByAngle:90 duration:1.]];
            
            newMesh = [[NKMeshNode alloc]initWithObjNamed:@"mushrooms" withSize:V3MakeF(5.) normalize:true anchor:true];
            newMesh.texture = [NKTexture textureWithImageNamed:@"shroom.tif"];
            [self addChild:newMesh];
            
            [newMesh setPosition3d:V3Make(0,-10,0)];
            [newMesh repeatAction:[NKAction rotateXByAngle:90 duration:1.]];

            
        }
        
#pragma mark - 6 - primitive generation
        
        else if (sceneChoice == 6) { // PRIMITIVES
            
            NKVertexBuffer *newCube = [NKVertexBuffer cubeWithWidthSections:10 height:10 depth:10];
            NKMeshNode* newMesh = [[NKMeshNode alloc]initWithVertexBuffer:newCube
                                                                 drawMode:GL_LINES
                                                                  texture:nil
                                                                    color:NKWHITE size:V3MakeF(.1)];
            [self addChild:newMesh];
            [newMesh repeatAction:[NKAction rotateYByAngle:45. duration:1.]];
//            NKMeshNode *s = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveCube texture:nil color:NKWHITE size:V3MakeF(.1)];
//            
//            [self addChild:s];
        }
        
    }
    
    
    return self;
}

-(void)handleEventWithType:(NKEventType)event forLocation:(P2t)location {
    [super handleEventWithType:event forLocation:location];
    
    if (NKEventTypeDoubleTap == event) {
        [self unload];
        self.nkView.scene = [[ExampleScene alloc]initWithSize:self.size sceneChoice:0];
    }
}

-(void)addBallToNode:(NKNode*)n {
    NKNode *s = [[NKNode alloc]initWithSize:V3MakeF(1.5)];
    [s setPosition3d:V3Make(0, 2, 25)];
    s.color = NKWHITE;
    
    [n addChild:s];
    
    s.body = [[NKBulletBody alloc] initWithType:NKBulletShapeSphere Size:s.size3d transform:s.localTransformMatrix mass:1.];
    [[NKBulletWorld sharedInstance] addNode:s];
    
    s.userInteractionEnabled = true;
    s.eventBlock = newEventBlock{
        
        [s.body forceAwake];
        
        // NSLog(@"boing!");
        if (NKEventTypeBegin == eventType) {
            [s.body setLinearVelocity:V3MakeF(0)];
            [s.body setAngularVelocity:V3MakeF(0)];
            s.positionRef = V3MultiplyM16(self.camera.viewMatrix, V3Make(location.x,0,-location.y));
        }
        else if (NKEventTypeMove == eventType){
            if (!V3Equal(V3MakeF(0), s.positionRef)) {
                V3t delta = V3Subtract(V3MultiplyM16(self.camera.viewMatrix, V3Make(location.x,0,-location.y)), s.positionRef);
                [s.body setLinearVelocity:V3Multiply(delta, V3MakeF(.25))];
                //[s setPosition3d:s.position3d];
                //[s setPosition3d:V3Add(s.position3d,V3Multiply(V3Make(delta.x, 0, delta.y), V3MakeF(.01)))];
            }
        }
        
        else if (NKEventTypeEnd == eventType){
            if (!V3Equal(V3MakeF(0), s.positionRef)) {
                V3t delta = V3Subtract(V3MultiplyM16(self.camera.viewMatrix, V3Make(location.x,0,-location.y)), s.positionRef);
                [s.body applyCentralImpulse:V3Negate(V3Multiply(delta, V3MakeF(50.)))];
                s.positionRef = V3MakeF(0.);
                [self performSelector:@selector(addBallToNode:) withObject:n afterDelay:.5];
                //[self addBallToNode:n];
            }
            
            
        }
    };
    
}

@end
