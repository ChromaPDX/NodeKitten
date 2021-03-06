//
//  NKUIView.m
//  EMA Stage
//
//  Created by Leif Shackelford on 5/21/14.
//  Copyright (c) 2014 EMA. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "NodeKitten.h"

@implementation NKUIView

#pragma mark -
#pragma mark - IOS
#pragma mark -


+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

-(instancetype)initWithFrame:(CGRect)frame {
    
    if ((self = [super initWithFrame:frame]))
    {
        [self sharedInit];
    }
    return self;
    
}

- (id) initWithCoder:(NSCoder*)coder
{
    
    if ((self = [super initWithCoder:coder]))
    {
        [self sharedInit];
    }
    
    return self;
}

-(void)sharedInit {
    // Get the layer
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    
    _mscale = 1.0f;
    
    drawHitEveryXFrames = 10;
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)]) {
        _mscale = [[UIScreen mainScreen] scale];
    }
    
    eaglLayer.contentsScale = _mscale ;
    
    eaglLayer.opaque = TRUE;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    
#if NK_USE_GL3
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
#else
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
#endif
    [[NKGLManager sharedInstance] setContext:context];
    
    if(!context){
        NSLog(@"failed to create EAGL context");
        return;
    }
    if (![self createFramebuffer]) {
        return;
    }
    else {
        NSLog(@"GLES Context && Frame Buffer loaded!");
    }
    
    
    [NKTextureManager sharedInstance];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopAnimation)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopAnimation)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopAnimation)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startAnimation)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    UITapGestureRecognizer *dt = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    [dt setNumberOfTapsRequired:2];
    [self addGestureRecognizer:dt];
    
    _events = [[NSMutableSet alloc]init];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
	[EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
    NSLog(@"rebuilding framebuffer");
	[self createFramebuffer];
    
	[self drawView];
}


-(void)setScene:(NKSceneNode *)scene {
    _scene = scene;
    scene.nkView = self;
    
    w = self.bounds.size.width;
    h = self.bounds.size.height;
    wMult = w / self.bounds.size.width;
    hMult = h / self.bounds.size.height;
    
    lastTime = CFAbsoluteTimeGetCurrent();
    
    [self startAnimation];
}

-(void)drawScene {
    
    if (_scene.hitQueue.count) {
        [_scene processHitBuffer];
    }

    [_framebuffer bind];
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glViewport(0, 0, _scene.size.width, _scene.size.height);
    
    if (_scene) {
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        
        //NSLog(@"draw scene");
        F1t dt = (CFAbsoluteTimeGetCurrent() - lastTime) * 1000.;
        lastTime = CFAbsoluteTimeGetCurrent();
        
        [_scene updateWithTimeSinceLast:dt];
        [_scene draw];
    }
    else {
        glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
    }

    
}

// Stop animating and release resources when they are no longer needed.


- (void)startAnimation
{
    if (!animating) {
        NSLog(@"Start animating");
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        
        lastTime = CFAbsoluteTimeGetCurrent();
        animating = true;
    }
}

- (void)stopAnimation
{
    if (animating) {
        NSLog(@"Stop animating");
        [displayLink invalidate];
        animating = false;
    }
}

- (void)drawView
{
    
   	[EAGLContext setCurrentContext:context];
    
    [self drawScene];
    
    glBindRenderbuffer(GL_RENDERBUFFER, _framebuffer.frameBuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER];
    
    
}

-(void)destroyFramebuffer {
    _framebuffer = nil;
}

-(BOOL) createFramebuffer {
    [EAGLContext setCurrentContext:context];
    
    _framebuffer = [[NKFrameBuffer alloc ]initWithContext:context layer:(id<EAGLDrawable>)self.layer];
    
    if (_framebuffer) {
        return true;
    }
    
    NSLog(@"failed to create main ES framebuffer");
    return false;
}

- (void)dealloc
{
	[self stopAnimation];
	
	if([EAGLContext currentContext] == context)
	{
		[EAGLContext setCurrentContext:nil];
	}
	context = nil;
}

-(P2t)uiPointToNodePoint:(CGPoint)p {
    P2t size = self.scene.size.point;
    return P2Make(p.x*_mscale, size.height - (p.y*_mscale));
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *t in touches) {
        NKEvent* event = [[NKEvent alloc]initWithTouch:t];
        event.phase = NKEventPhaseBegin;
        event.startingScreenLocation = [self uiPointToNodePoint:[t locationInView:self]];
        
        [_events addObject:event];
        [_scene dispatchEvent:event];
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *t in touches) {
        for (NKEvent *e in _events) {
            if (e.touch == t) {
                e.phase = NKEventPhaseMove;
                e.screenLocation = [self uiPointToNodePoint:[t locationInView:self]];
                [e.node handleEvent:e];
            }
        }
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *t in touches) {
        NSMutableSet *rem = [[NSMutableSet alloc]init];
        for (NKEvent *e in _events) {
            if (e.touch == t) {
                e.phase = NKEventPhaseEnd;
                e.screenLocation = [self uiPointToNodePoint:[t locationInView:self]];
                [e.node handleEvent:e];
                [rem addObject:e];
            }
        }
        
        [_events minusSet:rem];
    }
}

-(void)doubleTap:(UITapGestureRecognizer*)recognizer {
    NKEvent* event = [[NKEvent alloc]initWithTouch:nil];
    event.startingScreenLocation = [self uiPointToNodePoint:[recognizer locationInView:self]];
    event.phase = NKEventPhaseDoubleTap;
    [_scene dispatchEvent:event];
}


@end


#endif
