//
//  NKLabelNode.m
//  NodeKittenExample
//
//  Created by Chroma Developer on 2/28/14.
//  Copyright (c) 2014 Chroma. All rights reserved.
//

#import "NodeKitten.h"
#import <CoreText/CoreText.h>

@implementation NKLabelNode

//+ (instancetype)labelNodeWithFontNamed:(NSString *)fontName{
//    NKLabelNode *newLabel = [[NKLabelNode alloc]initWithFontNamed:fontName];
//    return newLabel;
//}
+ (instancetype)labelNodeWithFontNamed:(NSString *)fontName {
    return [[NKLabelNode alloc]initWithSize:S2Make(200, 100) FontNamed:fontName];
}

- (instancetype)initWithFontNamed:(NSString *)fontName {
    
    self = [self initWithSize:S2Make(200, 100) FontNamed:fontName];

    if (self){
        
    }
    
    return self;
}

- (instancetype)initWithSize:(S2t)size FontNamed:(NSString *)fontName{
    
    self = [super initWithColor:nil size:size];
    
    if (self){
        
        [self setSize:V3Make(size.width, size.height, 1)];
        
        if (!fontName) {
            _fontName = @"Arial Black.ttf";
        }
        else{
            _fontName = fontName;
            //_fontName = @"Arial Black";
        }
        
        //NSLog(@"labelnode with fontnamed: %@", _fontName);
        
        _fontSize = size.width < size.height ? size.width/4. : size.height/4.;
        
        _color = NKWHITE;
        _fontColor = NKWHITE;
        
    }
    
    return self;
}

- (void)loadAsyncText:(NSString*)text completion:(void (^)())block{
    
    if (!text) {
        [self setTexture:nil];
        _text = text;
    }
    
    else if (_text != text){
        _text = text;
        [self setTexture:[NKTexture textureWithString:text ForLabelNode:self inBackGroundWithCompletionBlock:^{block();}]];
        return;
    }
    
    block();
}

- (void)setText:(NSString *)text {
    if (_text != text){
        [self setTexture:[NKTexture textureWithString:text ForLabelNode:self]];
        //NSLog(@"completed set tex from string: size:%1.0f %1.0f", self.texture.size.width, self.texture.size.height);
    }
    
    if (!text) {
        [self setTexture:nil];
    }
    
    _text = text;
    
}

-(void)chooseShader {
    self.shader = [NKShaderProgram newShaderNamed:@"textureShader" colorMode:NKS_COLOR_MODE_NONE numTextures:_numTextures numLights:0 withBatchSize:0];
}


@end

