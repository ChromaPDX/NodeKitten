//
//  GLView.m
//  Wavefront OBJ Loader
//
//  Created by Jeff LaMarche on 12/14/08.
//  Copyright Jeff LaMarche 2008. All rights reserved.
//

#import "NodeKitten.h"

#if !TARGET_OS_IPHONE

@implementation NKView

#pragma mark -
#pragma mark - OS X
#pragma mark -

-(void)setScene:(NKSceneNode *)scene {
    _scene = scene;
    
    _scene.nkView = self;
    
    w = self.bounds.size.width;
    h = self.bounds.size.height;
    
    wMult = w / self.bounds.size.width;
    hMult = h / self.bounds.size.height;
    
    _mscale = 1.;
    
    lastTime = CFAbsoluteTimeGetCurrent();
    _events = [[NSMutableSet alloc]init];
    
    [self startAnimation];
}

-(void)drawScene {

    int useFB = 0;
    
    if (_scene) {
        
        if (_scene.hitQueue.count) {
            [_scene processHitBuffer];
        }

        if (useFB) {
            
            if (!_framebuffer) {
                _framebuffer = [[NKFrameBuffer alloc] initWithWidth:_scene.size.width height:_scene.size.height];
                rect = [[NKMeshNode alloc]initWithPrimitive:NKPrimitiveRect texture:_framebuffer.renderTexture color:NKWHITE size:V3Make(_scene.size.width, _scene.size.height, 1)];
                
                rect.shader = [NKShaderProgram newShaderNamed:@"fboDraw" colorMode:NKS_COLOR_MODE_NONE numTextures:1 numLights:0 withBatchSize:0];
                
                rect.forceOrthographic = true;
                rect.usesDepth = false;
                rect.cullFace = NKCullFaceFront;
                rect.blendMode = NKBlendModeNone;
            }
            
            [_framebuffer bind];
            [_framebuffer clear];
            
            
        }
        else {
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
            //glViewport(0, 0, self.visibleRect.size.width, self.visibleRect.size.height);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
            
        }

        F1t dt = (CFAbsoluteTimeGetCurrent() - lastTime);
        lastTime = CFAbsoluteTimeGetCurrent();
        
        [_scene updateWithTimeSinceLast:dt];
        [_scene draw];
        
        if (useFB) {
            
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
            
            glViewport(0, 0, self.visibleRect.size.width, self.visibleRect.size.height);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
           
            [rect setScene:_scene];
            [rect customDraw];
        }
        
    }
    
    else {
        // NO SCENE / DO RED SCREEN
        glViewport(0, 0, self.visibleRect.size.width, self.visibleRect.size.height);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
    }

    glFlush();

    
}


// OS X

+(void) load_
{
	NSLog(@"%@ loaded", self);
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        NSLog(@"NKView initWith Coder");
        //self = [self initWithFrame:self.frame shareContext:nil];
        [self becomeFirstResponder];
    }
    
    return self;
    
}

- (void) update
{
	// XXX: Should I do something here ?
	[super update];
}

- (void) awakeFromNib
{
    NSLog(@"awake from nib");
    
    NSLog(@"pixel flags: %d %d %d %d %d %d",				NSOpenGLPFADoubleBuffer,
          NSOpenGLPFADepthSize, 24,NSOpenGLPFAOpenGLProfile,
          NSOpenGLProfileVersion3_2Core, 0 );
    

    NSOpenGLPixelFormatAttribute attrs[] =
	{
        NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		// Must specify the 3.2 Core Profile to use OpenGL 3.2
#if NK_USE_GL3
		NSOpenGLPFAOpenGLProfile,
		NSOpenGLProfileVersion3_2Core,
#endif
        //NSOpenGLPFASampleBuffers,4,
		//NSOpenGLPFASamples, 4,
        0
	};
	
	NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
	
	if (!pf)
	{
		NSLog(@"No OpenGL pixel format");
	}
    

    
    NSOpenGLContext* context = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
    
    
#ifdef NK_GL_DEBUG
	// When we're using a CoreProfile context, crash if we call a legacy OpenGL function
	// This will make it much more obvious where and when such a function call is made so
	// that we can remove such calls.
	// Without this we'd simply get GL_INVALID_OPERATION error for calling legacy functions
	// but it would be more difficult to see where that function was called.
	//CGLEnable([context CGLContextObj], kCGLCECrashOnRemovedFunctions);
#endif
	
    [self setPixelFormat:pf];
    [self setOpenGLContext:context];
    [context setView:self];
    
    [[NKGLManager sharedInstance]setPixelFormat:pf];
    [[NKGLManager sharedInstance]setContext:context];
    
    
#if SUPPORT_RETINA_RESOLUTION
    // Opt-In to Retina resolution
    [self setWantsBestResolutionOpenGLSurface:YES];
#endif // SUPPORT_RETINA_RESOLUTION

    
    [self prepareOpenGL];
    
    GLint maj;
    GLint min;
    
    CGLGetVersion(&maj, &min);
    NSLog(@"NK GLView awake %1.0f %1.0f", self.visibleRect.size.width, self.visibleRect.size.height);
    NSLog(@"NK GLView using GL Version: %d.%d", maj, min);
    
     GetGLError();
}

- (void) prepareOpenGL
{
	[super prepareOpenGL];
	
	// Make all the OpenGL calls to setup rendering
	//  and build the necessary rendering objects
	[self initGL];
    

    //displayThread = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);

}

-(void)startAnimation {
    if (animating) return;
    animating = true;
#if USE_CV_DISPLAY_LINK
	// Create a display link capable of being used with all active displays
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	
	// Set the renderer output callback function
	CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void *)(self));
	
	// Set the display link for the current renderer
	CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
	CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
	
	// Activate the display link
	CVDisplayLinkStart(displayLink);
#else
    displayTimer = [NSTimer timerWithTimeInterval:.015 target:self selector:@selector(drawView) userInfo:nil repeats:YES];
    
    [[NSRunLoop mainRunLoop] addTimer:displayTimer forMode:NSDefaultRunLoopMode];
    
    NSLog(@"start animation");
#endif
    
	// Register to be notified when the window closes so we can stop the displaylink
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowWillClose:)
												 name:NSWindowWillCloseNotification
											   object:[self window]];
}

-(void)stopAnimation {
    if (!animating) return;
    animating = false;
    NSLog(@"stop animation");
    [displayTimer invalidate];
    #if USE_CV_DISPLAY_LINK
    #else
    #endif
    
}

- (void) initGL
{
	// The reshape function may have changed the thread to which our OpenGL
	// context is attached before prepareOpenGL and initGL are called.  So call
	// makeCurrentContext to ensure that our OpenGL context current to this
	// thread (i.e. makeCurrentContext directs all OpenGL calls on this thread
	// to [self openGLContext])
    

	[[self openGLContext] makeCurrentContext];
	
	// Synchronize buffer swaps with vertical refresh rate
	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
	
}

- (void) reshape
{
	[super reshape];
	
#if USE_CV_DISPLAY_LINK
	// We draw on a secondary thread through the display link. However, when
	// resizing the view, -drawRect is called on the main thread.
	// Add a mutex around to avoid the threads accessing the context
	// simultaneously when resizing.
	CGLLockContext([[self openGLContext] CGLContextObj]);
#endif
    
	// Get the view size in Points
	NSRect viewRectPoints = [self bounds];
    
    wMult = w / self.bounds.size.width;
    hMult = h / self.bounds.size.height;
    
    self.scene.size = V3Make(self.bounds.size.width, self.bounds.size.height, 1);
    
#if SUPPORT_RETINA_RESOLUTION
    
    // Rendering at retina resolutions will reduce aliasing, but at the potential
    // cost of framerate and battery life due to the GPU needing to render more
    // pixels.
    
    // Any calculations the renderer does which use pixel dimentions, must be
    // in "retina" space.  [NSView convertRectToBacking] converts point sizes
    // to pixel sizes.  Thus the renderer gets the size in pixels, not points,
    // so that it can set it's viewport and perform and other pixel based
    // calculations appropriately.
    // viewRectPixels will be larger (2x) than viewRectPoints for retina displays.
    // viewRectPixels will be the same as viewRectPoints for non-retina displays
    NSRect viewRectPixels = [self convertRectToBacking:viewRectPoints];
    
#else //if !SUPPORT_RETINA_RESOLUTION
    
    // App will typically render faster and use less power rendering at
    // non-retina resolutions since the GPU needs to render less pixels.  There
    // is the cost of more aliasing, but it will be no-worse than on a Mac
    // without a retina display.
    
    // Points:Pixels is always 1:1 when not supporting retina resolutions
    NSRect viewRectPixels = viewRectPoints;
    
#endif // !SUPPORT_RETINA_RESOLUTION
    
	// Set the new dimensions in our renderer
    //	[m_renderer resizeWithWidth:viewRectPixels.size.width
    //                      AndHeight:viewRectPixels.size.height];
	
    //[_scene setSize:S2Make(viewRectPixels.size.width*2., viewRectPixels.size.height*2.)];
    
#if USE_CV_DISPLAY_LINK
    
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
    
#endif
    
}

- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime
{
	[self drawView];
    return kCVReturnSuccess;
}

// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
    CVReturn result = [(__bridge NKView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}

- (void) drawRect: (NSRect) theRect
{
	// Called during resize operations
	
	// Avoid flickering during resize by drawiing
	[self drawView];
}

- (void) drawView
{
    //dispatch_async(dispatch_get_main_queue(), ^{
    [[self openGLContext] makeCurrentContext];
    
    // We draw on a secondary thread through the display link
    // When resizing the view, -reshape is called automatically on the main
    // thread. Add a mutex around to avoid the threads accessing the context
    // simultaneously when resizing
#if USE_CV_DISPLAY_LINK
    CGLLockContext([[self openGLContext] CGLContextObj]);
#endif
    
    [self drawScene];

    CGLFlushDrawable([[self openGLContext] CGLContextObj]);
    
#if USE_CV_DISPLAY_LINK
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
#endif
    //});
}


-(void) dealloc
{
#if USE_CV_DISPLAY_LINK
	if( displayLink ) {
		CVDisplayLinkStop(displayLink);
		CVDisplayLinkRelease(displayLink);
	}
#else
    if (displayTimer){
        [displayTimer invalidate];
    }
#endif
}

-(void)keyDown:(NSEvent *)theEvent {
    [_scene keyDown:theEvent.keyCode];
}

-(void)keyUp:(NSEvent *)theEvent {
    [_scene keyUp:theEvent.keyCode];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NKEvent *e = [[NKEvent alloc] initWithEvent:theEvent scale:P2MakeF(_mscale)];
    e.startingScreenLocation = P2Make(theEvent.locationInWindow.x, theEvent.locationInWindow.y);
    e.phase = NKEventPhaseBegin;
    [_events addObject:e];
    [_scene dispatchEvent:e];
}

- (void)mouseMoved:(NSEvent *)theEvent
{

}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if (_events.count) {
        NKEvent *e = [_events anyObject];
        e.phase = NKEventPhaseMove;
        e.screenLocation = P2Make(theEvent.locationInWindow.x, theEvent.locationInWindow.y);
        [e.node handleEvent:e];
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (_events.count) {
        NKEvent *e = [_events anyObject];
        if (theEvent.clickCount == 2) {
            e.phase = NKEventPhaseDoubleTap;        }
        else {
            e.phase = NKEventPhaseEnd;
        }
        e.screenLocation = P2Make(theEvent.locationInWindow.x, theEvent.locationInWindow.y);
        [e.node handleEvent:e];
        [_events removeObject:e];
    }
    

}




@end

#endif

