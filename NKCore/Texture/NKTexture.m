//
//  NKTexture.m
//  NodeKittenExample
//
//  Created by Chroma Developer on 3/5/14.
//  Copyright (c) 2014 Chroma. All rights reserved.
//

#import "NodeKitten.h"
#import "NKTextureManager.h"

#import <CoreText/CoreText.h>
#import "NKFont+CoreText.h"
#import "NKImage+Utils.h"

@implementation NKTexture

// INIT
#pragma mark - INIT

+(instancetype) textureWithImageNamed:(NSString*)name {
    
    if  (!name) return nil;
    
    if (![[NKTextureManager textureCache] objectForKey:name]) {
        NKTexture *newTex = [[NKTexture alloc] initWithImageNamed:name];
        
        if (newTex){
            //NSLog(@"adding tex to atlas named:%@", name);
            [[NKTextureManager textureCache] setObject:newTex forKey:name];
        }
        else {
            return nil;
        }
    }
    
    return [[NKTextureManager textureCache] objectForKey:name];
    
}

//+(instancetype) textureWithPVRNamed:(NSString*)name size:(S2t)size{
//    
//    if (![[NKTextureManager textureCache] objectForKey:name]) {
//        [[NKTextureManager textureCache] setObject:[[NKTexture alloc] initWithPVRFile:name width:size.width height:size.height]forKey:name];
//        //NSLog(@"add tex to atlas named: %@", name);
//    }
//    
//    return [[NKTextureManager textureCache] objectForKey:name];
//    
//}

+(instancetype) textureWithImage:(NKImage*)image {
    
    NKTexture *newTex = [[NKTexture alloc] initWithImage:image];
    
    return newTex;
    
}

+(instancetype) textureWithString:(NSString *)string ForLabelNode:(NKLabelNode*)node {
    
    if (![[NKTextureManager labelCache] objectForKey:string]) {
        [[NKTextureManager labelCache] setObject:[self textureWithString:string fontNamed:node.fontName color:node.fontColor Size:I2Make(node.size.width, node.size.height) fontSize:node.fontSize completion:nil] forKey:string];
        //NSLog(@"add tex to atlas for label node named: %@", string);
    }
    return [[NKTextureManager labelCache] objectForKey:string];
}

+(instancetype) textureWithString:(NSString *)string ForLabelNode:(NKLabelNode *)node inBackGroundWithCompletionBlock:(void (^)())block {
    if (![[NKTextureManager labelCache] objectForKey:string]) {
        [[NKTextureManager labelCache] setObject:[self textureWithString:string fontNamed:node.fontName color:node.fontColor Size:I2Make(node.size.width, node.size.height) fontSize:node.fontSize completion:^{block();}] forKey:string];
        //NSLog(@"add tex to atlas for label node named: %@", string);
    }
    else {
        block();
    }
    return [[NKTextureManager labelCache] objectForKey:string];
}

+(instancetype) textureWithString:(NSString *)text fontNamed:(NSString*)name color:(NKByteColor*)textColor Size:(I2t)size fontSize:(CGFloat)fontSize completion:(void (^)())block{
    
    NSString *textureName = [NSString stringWithFormat:@"%d_%@_%@", (int)fontSize, name, text];

    if ([[NKTextureManager textureCache] objectForKey:textureName]) {
        return [[NKTextureManager textureCache] objectForKey:textureName];
    }
    
    if (!textColor) {
        textColor = NKWHITE;
    }
    
    NKTexture *texture = [[NKTexture alloc] initForBackThreadWithWidth:size.width height:size.height];
    
    texture.name = textureName;
    
    //NSLog(@"cache font texture: %@", texture.name);
    
    [[NKTextureManager textureCache] setObject:texture forKey:texture.name];
    
    [texture setGlName:[NKTextureManager defaultTextureLocation]];
    
#if NK_USE_GLES
    dispatch_async([NKTextureManager textureThread], ^{
#endif
        CGContextRef ctx = [NKImage newRGBAContext:size];
        
        //Prepare our view for drawing
        
        CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
        
        CGContextClearRect(ctx, CGRectMake(0, 0, size.width, size.height));
        
        CGContextTranslateCTM(ctx, 0, size.height );
        CGContextScaleCTM(ctx, 1.0, -1.0);
        
        CGColorRef color = textColor.NKColor.CGColor;
        
        CTFontRef font = [NKFont bundledFontNamed:name size:fontSize];
        //CTFontRef font = CTFontCreateWithName((CFStringRef) name, fontSize, NULL);
        
        CTTextAlignment theAlignment = kCTCenterTextAlignment;
        
        CFIndex theNumberOfSettings = 1;
        CTParagraphStyleSetting theSettings[1] =
        {
            { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment),
                &theAlignment }
        };
        
        CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(theSettings, theNumberOfSettings);
        
        NSDictionary *attributesDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                        (__bridge id)(font), (NSString *)kCTFontAttributeName,
                                        color, kCTForegroundColorAttributeName,
                                        paragraphStyle, kCTParagraphStyleAttributeName,
                                        nil];
        
        
        NSAttributedString *stringToDraw = [[NSAttributedString alloc] initWithString:text attributes:attributesDict];
        
        CFAttributedStringRef ref = (__bridge CFAttributedStringRef)(stringToDraw);
        
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(ref);
        
        //Create Frame
        CGMutablePathRef path = CGPathCreateMutable();
        
        CGPathAddRect(path, NULL, CGRectMake(0, 0, size.width, size.height));
        
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
        
        //Draw Frame
        
        //	CTFrameDraw(frame, ctx);
        //
        //    CGContextSetRGBFillColor(ctx, 1., 0., .5, 1.);
        //    CGContextFillRect(ctx, CGRectMake(0, 0, size.width, size.height));
        
        CTFrameDraw(frame, ctx);
#if NK_USE_GLES
        dispatch_async(dispatch_get_main_queue(), ^{
#endif
            [texture loadTexFromCGContext:ctx size:size];
            if (block) {
                block();
            }
#if NK_USE_GLES
        });
#endif
        
        //NKTexture *texture = [[NKTexture alloc] initWithTexture:[NKTexture texFromImage:UIGraphicsGetImageFromCurrentImageContext()]];
        
        //NSLog(@"Creating texture with font %@, font named %@", font, name);
        
        
        
        
#if NK_USE_GLES
    });
#endif
    
    return texture;
    
}

-(instancetype)initWithWidth:(I1t)width height:(I1t)height {
    
    self = [super init];
    
    if (self) {
        
        _width = width;
        _height = height;

        [self genGlTexture:_width height:_height];

        glTexImage2D(target, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
        
    }
    
    GetGLError();

    return self;
    
}

-(I1t)width {
    return _width;
}
-(I1t)height {
    return _height;
}



-(instancetype) initWithImageNamed:(NSString*)name {
    
    self = [super init];
    
    if (self) {
        
        _name = name;
        
        self.textureMapStyle = NKTextureMapStyleRepeat;
        
        NKImage* request = [NKImage imageNamed:name];
        
        if (!request) {
            request = [NKImage imageNamed:@"chromeKittenSmall.png"];
            //NSLog(@"can't load tex, , using default");
        }
        
        NSAssert(request != nil, @"MISSING DEFAULT TEX IMAGE OR SOMETHING ELSE BROKE !!");
        
        [self loadTexFromCGContext:[NKTexture contextFromImage:request] size:I2Make(request.size.width, request.size.height)];
        
        _width = request.size.width;
        _height = request.size.height;

        self.shouldResizeToTexture = false;

    }
    
    return self;
}

#if GL_EXT_texture_compression_s3tc
#define GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG GL_COMPRESSED_RGB_S3TC_DXT1_EXT
#define GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG GL_COMPRESSED_RGB_S3TC_DXT1_EXT
#endif

- (id)initWithPVRFile:(NSString *)inFilename width:(GLuint)inWidth height:(GLuint)inHeight;
{
    if ((self = [super init]))
    {
        glEnable(target);
        
       // glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
        glGenTextures(1, &glName);
        glBindTexture(target, glName);
        glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(target, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(target, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexParameteri(target,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(target,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glBlendFunc(GL_ONE, GL_SRC_COLOR);
        NSString *extension = [inFilename pathExtension];
        NSString *base = [[inFilename componentsSeparatedByString:@"."] objectAtIndex:0];
        NSString *path = [[NSBundle mainBundle] pathForResource:base ofType:extension];
        NSData *texData = [[NSData alloc] initWithContentsOfFile:path];
        
        // Assumes pvr4 is RGB not RGBA, which is how texturetool generates them
        if ([extension isEqualToString:@"pvr4"])
            glCompressedTexImage2D(target, 0, GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG, inWidth, inHeight, 0, (inWidth * inHeight) / 2, [texData bytes]);
        else if ([extension isEqualToString:@"pvr2"])
            glCompressedTexImage2D(target, 0, GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG, inWidth, inHeight, 0, (inWidth * inHeight) / 2, [texData bytes]);
        else
        {
            NKImage *image = [[NKImage alloc] initWithData:texData];
            if (image == nil)
                return nil;
            
            GLuint width =  image.size.width;
            GLuint height = image.size.height;

            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            void *imageData = malloc( height * width * 4 );
            CGContextRef context = CGBitmapContextCreate( imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
            CGColorSpaceRelease( colorSpace );
            CGContextClearRect( context, CGRectMake( 0, 0, width, height ) );
            CGContextTranslateCTM( context, 0, height - height );
            
           // [image drawInRect:CGRectMake( 0, 0, width, height )];
            
            CGContextDrawImage( context, CGRectMake( 0, 0, width, height ), image.getCGImage);
            
            glTexImage2D(target, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
            GLuint errorcode = glGetError();
            CGContextRelease(context);
            
            free(imageData);
            //			[image release];
        }
        glEnable(GL_BLEND);
        
    }
    return self;
}

-(instancetype) initWithImage:(NKImage*)image {
    self = [super init];
    
    if (self) {
        self.textureMapStyle = NKTextureMapStyleRepeat;
        

        if (!image) {
            image = [NKImage imageNamed:@"chromeKitten.png"];
        }
        
        [self loadTexFromCGContext:[NKTexture contextFromImage:image] size:I2Make(image.size.width, image.size.height)];
        
        _width = image.size.width;
        _height = image.size.height;
    
        self.shouldResizeToTexture = false;
    }
    
    return self;
}


-(instancetype) initWithCGContext:(CGContextRef)ref size:(I2t)size{
    self = [super init];
    
    if (self) {
        self.textureMapStyle = NKTextureMapStyleRepeat;
        [self loadTexFromCGContext:ref size:size];
        self.shouldResizeToTexture = false;
    }
    
    return self;
}

-(instancetype) initForBackThreadWithWidth:(I1t)width height:(I1t)height {
    self = [super init];
    
    if (self) {
        _width = width;
        _height = height;
        self.textureMapStyle = NKTextureMapStyleRepeat;
        self.shouldResizeToTexture = false;
    }
    
    return self;
    
}



+(NKTexture*)blankTexture {
    return [NKTexture textureWithImageNamed:@"blank_texture"];
//    
//    CGSize sz = S2Make(10, 10);
//    NKTexture* tex = [[NKTexture alloc]initForBackThreadWithSize:sz];
//    CGContextRef context = [NKTexture newRGBAContext:sz];
//    CGContextClearRect(context, CGRectMake(0, 0, sz.width, sz.height));
////    CGContextSetRGBFillColor(context, 0, 0, 0, 0.);
////    CGContextFillRect(context, CGRectMake(0, 0, sz.width, sz.height));
//    [tex loadTexFromCGContext:context size:sz];
//    
//    return tex;
    
}
#pragma mark - PROPS

+(CGContextRef) contextFromImage:(NKImage*)image {
    
    CGSize size = CGSizeMake(image.size.width, image.size.height);
    
    CGContextRef ctx = [NKImage newBitmapRGBA8ContextFromImage:image];
    
    CGContextTranslateCTM(ctx, 0, size.height );
    CGContextScaleCTM(ctx, 1.0, -1.0);
    
    CGContextClearRect(ctx, CGRectMake(0, 0, size.width, size.height));
    CGContextDrawImage(ctx, CGRectMake(0, 0, size.width, size.height), image.getCGImage);
    
    return ctx;
    
}

-(void)genGlTexture:(int)w height:(int)h {
    target = GL_TEXTURE_2D;

    glActiveTexture(GL_TEXTURE0);
    
    glGenTextures(1, (GLuint *)&glName);
    glBindTexture(target, glName);
    
    glTexParameteri(target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
}

-(void)loadTexFromCGContext:(CGContextRef)context size:(I2t)size {
    
    _width = size.width;
    _height = size.height;
    
    target = GL_TEXTURE_2D;
    
    [self genGlTexture:size.width height:size.height];
    
    glTexImage2D(target, 0, GL_RGBA, size.width, size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, (unsigned char *)CGBitmapContextGetData(context));
    
#if !TARGET_OS_IPHONE
    glGenerateMipmap(target);
#endif
    
    glBindTexture(target, 0);
    
    if (!glName) {
        //NSLog(@"failed to allocate GLES texture ID");
    }

    
    GetGLError();
    CGContextRelease(context);
}

-(GLuint)glName {
    return glName;
}

-(void)setGlName:(GLuint)loc {
    glName = loc;
}

-(GLuint)glTarget {
    return target;
}


#pragma mark - UPDATE / DRAW

-(void)updateWithTimeSinceLast:(F1t)dt {
    
}

-(void)bind { // GL 1
    glActiveTexture(GL_TEXTURE0);
    glEnable(target);
    glBindTexture(target, glName);
}

-(void)unbind { // GL 1
    glBindTexture(target, 0);
//    glDisable(GL_TEXTURE_2D);
}

- (void)enableAndBind:(int)textureLoc
{
    glActiveTexture(GL_TEXTURE0+textureLoc);
    glBindTexture(target, glName);
}

- (void)bindToUniform:(GLuint)uniform {
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(target, glName);
    glUniform1i(uniform, 0);
}

- (void)enableAndBindToUniform:(GLuint)uniformSamplerLocation
{
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(target, glName);
    glUniform1i(uniformSamplerLocation, 0);
}

- (void)enableAndBindToUniform:(GLuint)uniformSamplerLocation atPosition:(int)textureNum
{
    assert(GL_TEXTURE1 == GL_TEXTURE0 + 1);
    glActiveTexture(GL_TEXTURE0 + textureNum);
    glBindTexture(target, glName);
    glUniform1i(uniformSamplerLocation, textureNum);
}

-(void)dealloc {
    glDeleteTextures(1, &glName);
}

@end

