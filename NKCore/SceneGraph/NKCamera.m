//
//  NKCamera.m
//  nike3dField
//
//  Created by Chroma Developer on 4/1/14.
//
//

#import "NodeKitten.h"

@implementation NKCamera

-(instancetype) initWithScene:(NKSceneNode*)scene {
    self = [super init];
    if (self) {
        self.scene = scene;
        self.position = V3Make(scene.position.x, scene.position.y, scene.position.z - 1);
        self.name = @"CAMERA";
        
        pDirty = true;
        
        self.aspect = self.scene.size.width / self.scene.size.height; // Use screen bounds as default
        _nearZ = .01f;
        _farZ = 10000.0f;
        _fovVertRadians = DEGREES_TO_RADIANS(54);
        
        self.upVector = V3Make(0, 1, 0);
        
        _target = [[NKNode alloc]init];
        
        [self initGL];
       
    }
    return self;
}

-(void)setTarget:(NKNode *)target {
    [self lookAtNode:target];
}

-(void)lookAtNode:(NKNode *)node {
    [_target removeAllActions];
    [_target runAction:[NKAction moveToFollowNode:node duration:1.] completion:^{
        [_target repeatAction:[NKAction followNode:node duration:1.]];
    }];
}


-(void)setDirty:(bool)dirty {
    [super setDirty:dirty];
    vpDirty = dirty;
    vDirty = dirty;
    pDirty = dirty;
}

- (M16t)viewProjectionMatrix
{
    if (vpDirty) {
        vpDirty = false;
        return viewProjectionMatrix = M16Multiply([self projectionMatrix], [self viewMatrix]);
    }
    
    return viewProjectionMatrix;
}

- (M16t)viewMatrix {
    if (vDirty) {
        _localTransform = viewMatrix = M16MakeLookAt(self.globalPosition, _target.globalPosition, [self upVector]);
        M16Invert(&_localTransform);
        //NKLogV3(@"view matrix trans", V3GetM16Translation(_localTransform));
        vDirty = false;
        return viewMatrix;
    }
    return viewMatrix;
}
//
//-(M16t)globalTransform {
//    return _localTransform;
//}

-(M16t)projectionMatrix {
    if (pDirty) {
        pDirty = false;
        if (_projectionMode == NKProjectionModeOrthographic) {
            return projectionMatrix = M16MakeOrtho(-self.scene.size.width*.5, self.scene.size.width*.5, -self.scene.size.height*.5, self.scene.size.height*.5, self.nearZ, self.farZ);
        }
        else {
            return projectionMatrix = M16MakePerspective(self.fovVertRadians,
                                                         self.aspect,
                                                         self.nearZ,
                                                         self.farZ);
        }
    }
    return projectionMatrix;
}

-(M16t)perspectiveMatrix {
    return M16MakeOrtho(-self.scene.size.width*.5, self.scene.size.width*.5, -self.scene.size.height*.5, self.scene.size.height*.5, self.nearZ, self.farZ);
}

-(M16t)orthographicMatrix {
    return M16MakeOrtho(-self.scene.size.width*.5, self.scene.size.width*.5, -self.scene.size.height*.5, self.scene.size.height*.5, self.nearZ, self.farZ);
}

-(void)initGL {
    GetGLError();
    
    glEnable(GL_BLEND);
    
    [self.scene setUsesDepth:true];
    
    glLineWidth(1.0f);
    
#if !TARGET_OS_IPHONE

#if !NK_USE_GL3
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, .01);
#endif
    
    glEnable( GL_POLYGON_SMOOTH );
    glHint( GL_LINE_SMOOTH_HINT, GL_NICEST );
    glHint( GL_POLYGON_SMOOTH_HINT, GL_NICEST );

#if !NK_USE_GL3
    glEnable(GL_MULTISAMPLE_ARB);
    glHint(GL_MULTISAMPLE_FILTER_HINT_NV, GL_NICEST);
#endif
    
    float gran;
    glGetFloatv(GL_SMOOTH_LINE_WIDTH_GRANULARITY, &gran);
    NSLog(@"smooth line gran: %f",gran);
#endif
    
    GetGLError();
}


#pragma mark UTIL

////convert from screen to camera
//-(V3t)s2w:(P2t)ScreenXY {
//    V3t CameraXYZ;
//    
//    CameraXYZ.x = ((ScreenXY.x * 2.) / self.scene.size.width) - 1.;
//    CameraXYZ.y = ((ScreenXY.y * 2.) / self.scene.size.height)- 1.;
//    CameraXYZ.z = self.position.z;
//    
//    //CameraXYZ.z = ScreenXYZ.z;
//    NSLog(@"noralized screen coords %f %f %f", CameraXYZ.x, CameraXYZ.y, CameraXYZ.z);
//    //get inverse camera matrix
//    M16t inverseCamera = M16InvertColumnMajor([self projectionMatrix], NULL);
//    
//    //convert camera to world
//    V3t p = V3MultiplyM16(inverseCamera, CameraXYZ);
//    
//    NSLog(@"camera coords %f %f %f", p.x, p.y, p.z);
//    return p;
//}
//
//-(P2t)screenToWorld:(P2t)p {
//
//    V3t p2 = [self s2w:p];
//        p2.x *= 1000.;
//        p2.y *= 1000.;
//
//     //NSLog(@"world i: %f %f o:%f %f", p.x, p.y, p2.x, p2.y);
//    return P2Make(p2.x, p2.y);
//    //return P2Make(10000, 10000);
//}
//
//-(P2t)screenPoint:(P2t)p InNode:(NKNode*)node {
//    
//    V3t CameraXYZ;
//    CameraXYZ.x = p.x / self.scene.size.width - 1.0f;
//    CameraXYZ.y = p.y / self.scene.size.height;
//    //CameraXYZ.z = ScreenXYZ.z;
//    
//    //get inverse camera matrix
//    M16t inverseCamera = M16InvertColumnMajor([node globalTransform], NULL);
//    
//    //convert camera to world
//    
//    V3t p2 = V3MultiplyM16(inverseCamera, CameraXYZ);
//
//    p2.x *= 1820.;
//    p2.y *= 1820.;
//    
//    //NSLog(@"world i: %f %f o:%f %f", p.x, p.y, p2.x, p2.y);
//    return P2Make(p2.x, p2.y);
//    
//}

-(void)updateCameraWithTimeSinceLast:(F1t)dt {
    [super updateWithTimeSinceLast:dt];
    [_target updateWithTimeSinceLast:dt];
    //  NKLogV3(@"camera pos", self.globalPosition);
}
-(void)updateWithTimeSinceLast:(F1t)dt {

}

@end
