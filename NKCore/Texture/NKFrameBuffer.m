//
//  NKFrameBuffer.m
//  NKNikeField
//
//  Created by Leif Shackelford on 5/7/14.
//  Copyright (c) 2014 Chroma Developer. All rights reserved.
//
#import "NodeKitten.h"

@implementation NKFrameBuffer

#pragma mark - Init

#if TARGET_OS_IPHONE

- (id)initWithContext:(EAGLContext *)context layer:(id <EAGLDrawable>)layer
{
    self = [super init];
    
    if(self){
        
        [self destroyFBO:_frameBuffer];
        
        //NSLog(@"GLES fb init with context %@", context);
        
        // 1 // Create the framebuffer and bind it.
        
        glGenFramebuffers(1, &_frameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        
        //NSLog(@"allocate gl buffer, %d", _frameBuffer);
        // 2 // Create a color renderbuffer, allocate storage for it, and attach it to the framebuffer’s color attachment point.
        
        glGenRenderbuffers(1, &_renderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
        
        //NSLog(@"allocate gl buffer, %d", _renderBuffer);
        
       // glRenderbufferStorage(GL_RENDERBUFFER, GL_RGB8_OES, width,height);

        [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
        
        GLint nw;
        GLint nh;
        
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &nw);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &nh);
        
        _size = P2Make(nw, nh);
        
        
        NSLog(@"size %d, %d", nw, nh);
        
        _renderTexture = [[NKTexture alloc]initWithSize:_size];
        
       // [_renderTexture bind];
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
        //glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _renderTexture.glName, 0);
        
        // Always check that our framebuffer is ok
        if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        {
            NSLog(@"ERROR Creating framebuffer");
            return nil;
        }
        
        // 3 // Create a depth or depth/stencil renderbuffer, allocate storage for it, and attach it to the framebuffer’s depth attachment point.
        
        glGenRenderbuffers(1, &_depthBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _depthBuffer);
        
        NSLog(@"allocate gl depth buffer, %d", _depthBuffer);
        
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, _size.width, _size.height);
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);
        
        // 4 // Test the framebuffer for completeness. This test only needs to be performed when the framebuffer’s configuration changes.
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER) ;
        if(status != GL_FRAMEBUFFER_COMPLETE) {
           // NKCheckGLError(@"building frameBuffer");
            NSLog(@"failed to make complete framebuffer object %x", status);
            NSLog(@"failed context %@", context);
            return nil;
        }


        
    }
    
    return self;
    
}

-(int)width {
    return _size.width;
}

-(int)height {
    return _size.height;
}
#else
//
//-(instancetype)initWithWidth:(GLuint)width height:(GLuint)height {
//    
//}

#endif

-(instancetype)initWithWidth:(GLuint)width height:(GLuint)height {
    
    self = [super init];
    
    if(self){
        
        _size.width = width;
        _size.height = height;
        
#if NK_USE_GLES
        
        // 1 // Create the framebuffer and bind it.
        
        glGenFramebuffers(1, &_frameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        
        // 2 // Create a color renderbuffer, allocate storage for it, and attach it to the framebuffer’s color attachment point.
        
        glGenRenderbuffers(1, &_renderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
        
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGB8_OES, width,height);
        
        //glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
        //glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
        
        // 3 // Create a depth or depth/stencil renderbuffer, allocate storage for it, and attach it to the framebuffer’s depth attachment point.
        
        glGenRenderbuffers(1, &_depthBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _depthBuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);
        
        _renderTexture = [[NKTexture alloc]initWithSize:S2Make(width, height)];
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _renderTexture.glName, 0);
        
        // Always check that our framebuffer is ok
        if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        {
            NSLog(@"ERROR Creating framebuffer");
            return nil;
        }
        
        
#else
        
        if ([self buildFBOWithWidth:_size.width andHeight:_size.height]){
            
        }
        else {
            NSAssert(0, @"failed to create framebuffer");
            return nil;
        }
        
#endif
        
        
    }
    
    NSLog(@"new framebuffer: %d size %d %d", _renderBuffer, width, height);
    
    return self;
    
}

-(BOOL) buildFBOWithWidth:(GLuint)width andHeight:(GLuint) height
{
    glGenFramebuffers(1, &_frameBuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    // 1 color
    _renderTexture = [[NKTexture alloc]initWithSize:_size];
    _renderBuffer = _renderTexture.glName;
    
    // 2 depth
	GLuint depthRenderbuffer;
	glGenRenderbuffers(1, &depthRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
	
    // 3 setup
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _renderTexture.glName, 0);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
	
	if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
		[self destroyFBO:_frameBuffer];
        return 0;
	}
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    GetGLError();
    
    return 1;
}

-(void) destroyFBO:(GLuint) fboName
{
	if(0 == fboName)
	{
		return;
	}
    
    glBindFramebuffer(GL_FRAMEBUFFER, fboName);
	
    GLint maxColorAttachments = 1;
	
	// OpenGL ES on iOS 4 has only 1 attachment.
	// There are many possible attachments on OpenGL
	// on MacOSX so we query how many below
#if !NK_USE_GLES
	glGetIntegerv(GL_MAX_COLOR_ATTACHMENTS, &maxColorAttachments);
#endif
	
	GLint colorAttachment;
	
	// For every color buffer attached
    for(colorAttachment = 0; colorAttachment < maxColorAttachments; colorAttachment++)
    {
		// Delete the attachment
		[self deleteFBOAttachment:(GL_COLOR_ATTACHMENT0+colorAttachment)];
	}
	
	// Delete any depth or stencil buffer attached
    [self deleteFBOAttachment:GL_DEPTH_ATTACHMENT];
	
    [self deleteFBOAttachment:GL_STENCIL_ATTACHMENT];
	
    glDeleteFramebuffers(1,&fboName);
}

-(void) deleteFBOAttachment:(GLenum) attachment
{
    GLint param;
    GLuint objName;
	
    glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, attachment,
                                          GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE,
                                          &param);
	
    if(GL_RENDERBUFFER == param)
    {
        glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, attachment,
                                              GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
                                              &param);
		
        objName = ((GLuint*)(&param))[0];
        glDeleteRenderbuffers(1, &objName);
    }
    else if(GL_TEXTURE == param)
    {
        
        glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, attachment,
                                              GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
                                              &param);
		
        objName = ((GLuint*)(&param))[0];
        glDeleteTextures(1, &objName);
    }
    
}

#pragma mark - Binding

- (void)bind
{
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
}

- (void)clear {
            glViewport(0, 0, self.size.width, self.size.width);
    
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
}

- (void)bind:(void(^)())drawingBlock
{
    [self bind];
    drawingBlock();
    [self unbind];
}


- (void)unbind
{
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

-(void)unload {
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    if (_frameBuffer) {
        glDeleteFramebuffers(1, &_frameBuffer);
    }
    if (_renderBuffer) {
        glDeleteRenderbuffers(1, &_renderBuffer);
    }
    if(_depthBuffer)
    {
        glDeleteRenderbuffers(1, &_depthBuffer);
        _depthBuffer = 0;
    }
}

-(void)dealloc {
    [self unload];
}
//- (GLuint)bindTexture:(int)texLoc
//{
//    glEnable(GL_TEXTURE_2D);
//    glActiveTexture(texLoc);
//    glBindTexture(GL_TEXTURE_2D, self.locRenderTexture);
//    return self.locRenderTexture;
//}

#pragma mark - Accessing Data

-(V2t)size {
    return _size;
}

-(void)setSize:(V2t)size {
    _size = size;
}

- (NKByteColor*)colorAtPoint:(P2t)point {

    //NSLog(@"read pixels at %d, %d", (int)point.x, (int)point.y);

    NKByteColor *hit = [[NKByteColor alloc]init];
    
    [self bind];
    
    glReadPixels((int)point.x, (int)point.y,
                 1, 1,
                 GL_RGBA, GL_UNSIGNED_BYTE, hit.bytes);
    
    [self unbind];

    [hit log];
    
    return hit;
    
}

- (void)pixelValuesInRect:(CGRect)cropRect buffer:(GLubyte *)pixelBuffer
{
    GLint width = cropRect.size.width;
    GLint height = cropRect.size.height;
    glReadPixels(cropRect.origin.x, cropRect.origin.y,
                 width, height,
                 GL_RGBA, GL_UNSIGNED_BYTE, pixelBuffer);
}

- (NKImage *)imageAtRect:(CGRect)cropRect
{
    GLint width = cropRect.size.width;
    GLint height = cropRect.size.height;
    
    NSInteger myDataLength = width * height * 4;
    
    // allocate array and read pixels into it.
    GLubyte *buffer = (GLubyte *) malloc(myDataLength);
    
    [self pixelValuesInRect:cropRect buffer:buffer];
    
    return [NKImage imageWithBuffer:buffer ofSize:cropRect.size];
}

@end