//
//  NKEmitterNode.m
//  NodeKittenIOS
//
//  Created by Leif Shackelford on 6/22/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//

#import "NodeKitten.h"

@implementation NKEmitterNode

//-(void)customDraw {
//    
//    if (self.color || _numTextures) {
//        
//        if (self.shader) {
//            self.scene.activeShader = self.shader;
//        }
//        
//        [self setupViewMatrix];
//        
//        if ([self.scene.activeShader uniformNamed:NKS_V4_COLOR]){
//            if (!_color) {
//                [[self.scene.activeShader uniformNamed:NKS_V4_COLOR] bindV4:[NKCLEAR C4Color]];
//            }else {
//                [[self.scene.activeShader uniformNamed:NKS_V4_COLOR] bindV4:[self glColor]];
//            }
//        }
//        
//        [self bindTextures];
//        
//        if (self.scene.boundVertexBuffer != _vertexBuffer) {
//            [_vertexBuffer bind];
//            self.scene.boundVertexBuffer = _vertexBuffer;
//        }
//        
//        if (_primitiveType == NKPrimitiveLODSphere) {
//            int lod = [self lodForDistance];
//            glDrawArrays(_drawMode, _vertexBuffer.elementOffset[lod], _vertexBuffer.elementSize[lod]);
//        }
//        else {
//            if (_vertexBuffer.indexBuffer){
//                [_vertexBuffer.indexBuffer bind];
//                //NSLog(@"draw indexed");
//                glDrawElements(_drawMode, _vertexBuffer.numberOfElements, GL_UNSIGNED_INT, 0);
//                [_vertexBuffer.indexBuffer unbind];
//            }
//            else
//                glDrawArrays(_drawMode, 0, _vertexBuffer.numberOfElements);
//        }
//        
//        if (_drawBoundingBox) {
//            NKVertexBuffer*v = [NKStaticDraw cachedPrimitive:NKPrimitiveCube];
//            [v bind];
//            glDrawArrays(GL_LINES, 0, v.numberOfElements);
//        }
//        
//    }
//    
//}
//
//-(void)chooseShader {
//    if (_numTextures) {
//#if !NK_USE_GLES
//        if ([_textures[0] isKindOfClass:[NKVideoTexture class]]) {
//            self.shader = [NKShaderProgram newShaderNamed:@"videoTextureShader" colorMode:NKS_COLOR_MODE_UNIFORM numTextures:-1 numLights:1 withBatchSize:0];
//            return;
//        }
//#endif
//        self.shader = [NKShaderProgram newShaderNamed:@"uColorTextureLightShader" colorMode:NKS_COLOR_MODE_UNIFORM numTextures:_numTextures numLights:1 withBatchSize:0];
//    }
//    else {
//        self.shader = [NKShaderProgram newShaderNamed:@"uColorLightShader" colorMode:NKS_COLOR_MODE_UNIFORM numTextures:0 numLights:1 withBatchSize:0];
//    }
//}

@end
