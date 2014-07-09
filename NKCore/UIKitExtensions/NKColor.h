//
//  NKColor.h
//  NKNikeField
//
//  Created by Leif Shackelford on 5/19/14.
//  Copyright (c) 2014 Chroma Developer. All rights reserved.
//

#import <Foundation/Foundation.h>

#define div255 *.003921568

@interface NKByteColor : NSObject <NSCopying, NSCoding>

{
    UB4t color;
}

+(instancetype)colorWithRed:(U1t)red green:(U1t)green blue:(U1t)blue alpha:(U1t)alpha;
+(instancetype)colorWithColor:(NKColor*)color;
+(instancetype)colorWithC4Color:(C4t)color;

-(BOOL)isEqual:(id)object;

-(void)setC4Color:(C4t)color;
-(void)setRed:(GLubyte)red;
-(void)setGreen:(GLubyte)green;
-(void)setBlue:(GLubyte)blue;
-(void)setAlpha:(GLubyte)alpha;
-(GLubyte)alpha;

-(UB4t)UB4Color;
-(NKColor*)NKColor;
-(C4t)C4Color;
-(V3t)RGBColor;

-(C4t)colorWithBlendFactor:(F1t)blendFactor;
-(C4t)colorWithBlendFactor:(F1t)blendFactor alpha:(F1t)alpha;

-(void)log;

-(GLubyte*)bytes;

@end
