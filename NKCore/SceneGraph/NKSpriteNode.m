//
//  ofxGameNode.m
//  example-ofxTableView
//
//  Created by Chroma Developer on 2/13/14.
//
//

#import "NodeKitten.h"
#import <CoreText/CoreText.h>

@implementation NKSpriteNode

//-(void)setupViewMatrix {
//    
//    //NSLog(@"uxWindow set ortho persp");
//    
//    M16t modelView = M16Multiply(self.scene.camera.viewMatrix, M16ScaleWithV3(self.globalTransform, _size));
//    
//    if([self.scene.activeShader uniformNamed:NKS_M16_MV] ){
//        [[self.scene.activeShader uniformNamed:NKS_M16_MV] bindM16:modelView];
//    }
//    
//    if ([self.scene.activeShader uniformNamed:NKS_M9_NORMAL]){
//        [[self.scene.activeShader uniformNamed:NKS_M9_NORMAL] bindM9:M16GetInverseNormalMatrix(modelView)];
//    }
//    
//    M16t mvp = M16Multiply(self.scene.camera.orthographicMatrix, modelView);
//    
//    [[self.scene.activeShader uniformNamed:NKS_M16_MVP] bindM16:mvp];
//    
//}

-(instancetype)initWithTexture:(NKTexture *)texture color:(NKByteColor *)color size:(V2t)size {
    
    self = [super initWithPrimitive:NKPrimitiveRect texture:texture color:color size:V3Make(size.x, size.y, 1)];
    
    if (self) {
        //self.cullFace = NKCullFaceNone;
    }
    
    return self;

}

+ (instancetype)spriteNodeWithTexture:(NKTexture*)texture size:(S2t)size {
    NKSpriteNode *node = [[NKSpriteNode alloc] initWithTexture:texture color:NKWHITE size:size];
    return node;
}

+ (instancetype)spriteNodeWithTexture:(NKTexture*)texture {
    NKSpriteNode *node = [[NKSpriteNode alloc] initWithTexture:texture];
    return node;
}

+ (instancetype)spriteNodeWithImageNamed:(NSString *)name {
    NKSpriteNode *node = [[NKSpriteNode alloc] initWithImageNamed:name];
    return node;
}

+ (instancetype)spriteNodeWithColor:(NKByteColor*)color size:(S2t)size {
    NKSpriteNode *node = [[NKSpriteNode alloc] initWithColor:color size:size];
    return node;
}


- (instancetype)initWithTexture:(NKTexture*)texture {
    return [self initWithTexture:texture color:NKWHITE size:S2Make(texture.width, texture.height)];
}

- (instancetype)initWithImageNamed:(NSString *)name {
    NKTexture *newTex = [NKTexture textureWithImageNamed:name];
    return [self initWithTexture:newTex color:NKWHITE size:S2Make(newTex.width, newTex.height)];
}

- (instancetype)initWithColor:(NKByteColor*)color size:(S2t)size {
    self = [self initWithTexture:nil color:color size:S2Make(size.width, size.height)];
    
    if (self) {
    }
    
    return self;

}

@end
