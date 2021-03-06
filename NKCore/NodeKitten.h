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
// NODE
#import "NKNode.h"

// NODE SUBS
#import "NKSceneNode.h"
#import "NKEmitterNode.h"
#import "NKMeshNode.h"
#import "NKCamera.h"
#import "NKLightNode.h"

// MESH NODE SUBS
#import "NKSpriteNode.h"
#import "NKBatchNode.h"
#import "NKLabelNode.h"
#import "NKScrollNode.h"
#import "NKAlertSprite.h"
#import "NKEmitterNode.h"

// SCOLL NODE SUBS
#import "NKPickerNode.h"

// GEOMETRY + DRAWS
// #import "NKVectorTypes.h" should be in the PCH
#import "NKVertexBuffer.h"
#import "NKStaticDraw.h"

// TEXTURE

#import "NKTextureManager.h"
#import "NKTexture.h"
#import "NKVideoTexture.h"
#import "NKColor.h"

// SHADERS

#import "NKShaderManager.h"
#import "NKShaderProgram.h"
#import "NKShaderModule.h"
#import "NKShaderTools.h"

// ANIMATION

#import "NKNodeAnimationHandler.h"

// DEPENDENCIES / MODULES

#if NK_USE_ASSIMP
#import "NKAssimpLoader.h"
#endif

#if NK_USE_MIDI
#import "NKMidiManager.h"
#endif

#if NK_USE_KINECT
#import "NKKinectManager.h"
#endif

// SOUND

#import "NKSoundManager.h"

// UIKIT

#import "NKEvent.h"
#import "NKGLManager.h"

#if TARGET_OS_IPHONE
#import "NKUIViewController.h"
#import "NKUIView.h"
#else
#import "NKViewController.h"
#import "NKView.h"
#endif
#import "NKFrameBuffer.h"

// UIKIT EXTENSIONS

#import "NKImage+Utils.h"
#import "NKFont+CoreText.h"

// 3rd party libraries

#import "NKBulletWorld.h"

