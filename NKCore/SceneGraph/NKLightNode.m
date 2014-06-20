//
//  NKLightNode.m
//  EMA Stage
//
//  Created by Leif Shackelford on 5/26/14.
//  Copyright (c) 2014 EMA. All rights reserved.
//

#import "NodeKitten.h"

@implementation NKLightNode

-(instancetype)initWithProperties:(NKLightProperties)properties {
    self = [[NKLightNode alloc] initWithPrimitive:NKPrimitiveSphere texture:nil color:NKYELLOW size:V3MakeF(.25)];
    
    if (self) {
        //self.color = [NKByteColor colorWithRed:properties.color.r*255 green:properties.color.g*255 blue:properties.color.b*255 alpha:255];
        _properties = properties;
    }
    
    return self;
}

-(instancetype)initWithDefaultProperties {
    NKLightProperties p;
    
    p.isEnabled = true;
    p.isLocal = true;
    p.isSpot = false;
    
    p.ambient = V3Make(.2,.2,.2);
    p.color = V3Make(1.,1.,1.);
    p.coneDirection = V3Make(0, 0, -1);
    p.halfVector = V3MakeF(0);
    
    p.spotCosCutoff = 10.;
    p.spotExponent = 2;
    p.constantAttenuation = 1.;
    p.linearAttenuation = .2;
    p.quadraticAttenuation = 0;
    
    return [self initWithProperties:p];
    
}
-(instancetype)initWithColor:(NKByteColor*)color {
    self = [super initWithSize:V3MakeF(.5)];
    
    if (self) {
        self.color = color;
        _properties.color = color.RGBColor;
        _properties.ambient = V3MakeF(.5);
    }
    
    return self;
}

-(void)setColor:(NKByteColor *)color {
    [super setColor:color];
    _properties.color = color.RGBColor;
}

-(void)setDirty:(bool)dirty {
    [super setDirty:dirty];
     _properties.position = V3MultiplyM16WithTranslation(self.scene.camera.viewMatrix, self.globalPosition);
    // NKLogV3(@"light pos in eye space", _properties.position);
}

-(void)setScene:(NKSceneNode *)scene {
    [super setScene:scene];
    
    if (![self.scene.lights containsObject:self]) {
        [self.scene.lights addObject:self];
    }
}

-(void)chooseShader {
    self.shader = [NKShaderProgram newShaderNamed:@"lightNodeShader" colorMode:NKS_COLOR_MODE_UNIFORM numTextures:0 numLights:0 withBatchSize:0];
}

-(void)removeFromParent {
    [self.scene.lights removeObject:self];
    [super removeFromParent];
}

-(void)draw {
    if (self.scene.drawLights){
         [super draw];
    }
}

-(NKLightProperties*)pointer {
    return &_properties;
}

@end
