//
//  NKNode.m
//  example-ofxTableView
//
//  Created by Chroma Developer on 2/17/14.
//
//

#import "NodeKitten.h"

@implementation NKNode

#define TEST_IGNORE 1
#pragma mark - init

-(instancetype)init {
    return [self initWithSize:V3Make(1., 1., 1.)];
}

-(instancetype)initWithSize:(V3t)size {
    self = [super init];
    
    if (self){
        
        self.name = @"NEW NODE";

        [self setSize:size];
        [self setScaleF:1.];
        [self setOrientationEuler:V3Make(0, 0, 0)];
        [self setPosition:V3Make(0, 0, 0)];
        
        _upVector = V3Make(0, 1, 0);
        
        _hidden = false;
        intAlpha = 1.;
        _alpha = 1.;
        parentAlpha = 1.;
        _colorBlendFactor = 1.;
        _usesDepth = true;
        
        _blendMode = NKBlendModeAlpha;
        
        _userInteractionEnabled = false;
        
    }
    
    return self;
}

//-(instancetype)initWithSize:(V3t)size {
//    
//    self = [super init];
//    
//    if (self) {
//        _size = size;
//    }
//    
//    return self;
//}

#pragma mark - Node Hierarchy

-(NSArray*)children {
    return _children;
}

-(void)setChildren:(NSArray *)children {
    _children = children;
}

- (void)addChild:(NKNode *)child {
    
    NSMutableArray *temp;
    if (!_children) {
        temp = [[NSMutableArray alloc]initWithCapacity:1];
    }
    else {
        temp = [_children mutableCopy];
    }
    
    if (![temp containsObject:child]) {
        [temp addObject:child];
        [child setParent:self];
    }
    
    _children = temp;
}



- (void)insertChild:(NKNode *)child atIndex:(NSInteger)index {
    
    NSMutableArray *temp = [_children mutableCopy];
    
    if (![temp containsObject:child]) {
        [temp insertObject:child atIndex:0];
        [child setParent:self];
    }
    
    _children = temp;
}

- (void)fadeInChild:(NKNode*)child duration:(NSTimeInterval)seconds{
    [self fadeInChild:child duration:seconds withCompletion:nil];
}

- (void)fadeOutChild:(NKNode*)child duration:(NSTimeInterval)seconds{
    [self fadeOutChild:child duration:seconds withCompletion:nil];
}

- (void)fadeInChild:(NKNode*)child duration:(NSTimeInterval)seconds withCompletion:(void (^)())block{
    [self addChild:child];
    
    [child setAlpha:0];
    [child runAction:[NKAction fadeAlphaTo:1. duration:seconds] completion:^{
        if (block){
            block();
        }
    }];
}

- (void)fadeOutChild:(NKNode*)child duration:(NSTimeInterval)seconds withCompletion:(void (^)())block{
    
    [child runAction:[NKAction fadeAlphaTo:0. duration:seconds] completion:^{
        
        if (block){
            block();
        }
        
        [child removeFromParent];
        
    }];
    
}

-(void)setUserInteractionEnabled:(bool)userInteractionEnabled {
    
    _userInteractionEnabled = userInteractionEnabled;

    if (_userInteractionEnabled && _parent) {
        if (!_uidColor) {
            [NKShaderManager newUIDColorForNode:self];
        }
        [_parent setUserInteractionEnabled:true];
    }
    
}


-(void)setParent:(NKNode *)parent {
    
    if (_parent) {
        V3t p = self.globalPosition;
        //NKLogV3(@"global position", p);
        [_parent removeChild:self];
        _parent = parent;
        [self setGlobalPosition:p];
    }
    else {
        _parent = parent;
    }
    
    self.scene = parent.scene;
    
    if (self.userInteractionEnabled && _parent) {
        [_parent setUserInteractionEnabled:true];
    }
}

-(void)setScene:(NKSceneNode *)scene {
    if (_userInteractionEnabled && !_uidColor) {
        [NKShaderManager newUIDColorForNode:self];
    }
    _scene = scene;
}

-(NKSceneNode*)scene {
    
    if (!_scene) { // CACHE POINTER
        
        if (_parent) {
            _scene = _parent.scene;
            return _parent.scene;
        }
        
        if ([self isKindOfClass:[NKSceneNode class]]) {
            _scene = (NKSceneNode*) self;
            return (NKSceneNode*) self;
        }
        
        return nil;
    }
    
    return _scene;
    
}

-(NKNode*)parent {
    return _parent;
}

-(S2t)size2d {
    return _size.point;
}

-(V3t)size {
    return _size;
}

-(void)setSize2d:(S2t)size {
    w = size.width;
    h = size.height;
    _size.x = w;
    _size.y = h;
}

-(void)setSize:(V3t)size {
    _size = size;
    w = _size.x;
    h = _size.y;
    d = _size.z;
}


-(int)numNodes {
    
    int count = 0;
    
    for (NKNode* child in _children) {
        count += [child numNodes];
        count++;
    }
    
    return count;
    
}

-(int)numVisibleNodes {
    
    int count = 0;
    
    for (NKNode* child in _children) {
        if (!child.isHidden) {
            count += [child numVisibleNodes];
            count++;
        }
    }
    
    return count;
    
}

-(R4t)calculateAccumulatedFrame {
    
    R4t rect = [self getDrawFrame];
    
    for (NKNode* child in _children) {
        
        R4t childFrame = [child getDrawFrame];
        
        if (childFrame.x < rect.x) {
            rect.x = childFrame.x;
        }
        
        
        if (childFrame.x + childFrame.size.width > rect.x + rect.size.width) {
            rect.size.width = rect.x + childFrame.x + childFrame.size.width;
        }
        
        if (childFrame.y < rect.y) {
            rect.y = childFrame.y;
        }
        
        
        if (childFrame.y + childFrame.size.height > rect.y + rect.size.height) {
            rect.size.height = rect.y + childFrame.y + childFrame.size.height;
        }
        
    }
    
    return rect;
}

- (void)removeChildrenInArray:(NSArray *)nodes{
    NSMutableArray *childMut = [_children mutableCopy];
    [childMut removeObjectsInArray:nodes];
    _children = childMut;
}

- (void)removeAllChildren{
    _children = nil;
}

-(void)removeChild:(NKNode *)node {
    [node removeFromParent];
}

-(void)removeChildNamed:(NSString *)name {
    for (NKNode *n in _children) {
        if ([n.name isEqualToString:name]) {
            [n removeFromParent];
            return;
        }
    }
}

-(NKNode*)childNodeWithName:(NSString *)name {
    for (NKNode *n in _children) {
        if ([n.name isEqualToString:name]) {
            return n;
        }
    }
    return nil;
}

-(NKNode*)randomChild {
    if (!_children.count) {
        return self;
    }
    return _children[arc4random() % _children.count];
}

-(NKNode*)randomLeaf {
    
    if (_children.count) {
        return [[self randomChild] randomLeaf];
    }
    
    return self;
    
}

-(NSArray*)allChildren {
    
    NSMutableArray* allChildren = [[NSMutableArray alloc] init];
    
    for (NKNode*child in _children) {
        [allChildren addObject:child];
        [allChildren addObjectsFromArray:child.children];
    }
    
    return allChildren;
    
}

- (void)removeFromParent{
    
    for (NKNode *child in _children) {
        [child removeFromParent];
    }
    
    [self unload];
    
    if (_parent){
        [_parent removeChildrenInArray:@[self]];
    }
    
    if (_scene){
        [_scene removeChildrenInArray:@[self]];
    }
}

-(void)unload {
    
    for (NKNode* node in _children) {
        [node unload];
    }
    
    [animationHandler removeAllActions];
    
    if (_body) {
        [[NKBulletWorld sharedInstance]removeNode:self];
    }
    
    if (_uidColor) {
        [[NKShaderManager uidColors] removeObjectForKey:_uidColor];
    }
    
    if (self.uidColor) {
        [[NKShaderManager uidColors] removeObjectForKey:self.uidColor];
    }
    
}
#pragma mark - Actions

-(int)hasActions {
    return [animationHandler hasActions];
}

- (void)runAction:(NKAction*)action {
    if (!animationHandler) {
        animationHandler = [[NodeAnimationHandler alloc]initWithNode:self];
    }
    [animationHandler runAction:action];
}

-(void)repeatAction:(NKAction*)action {
    if (!animationHandler) {
        animationHandler = [[NodeAnimationHandler alloc]initWithNode:self];
    }
    [animationHandler runAction:[NKAction repeatActionForever:action]];
}

- (void)runAction:(NKAction *)action completion:(void (^)())block {
    if (!animationHandler) {
        animationHandler = [[NodeAnimationHandler alloc]initWithNode:self];
    }
    [animationHandler runAction:action completion:block];
}

#pragma mark - UPDATE / DRAW

- (void)updateWithTimeSinceLast:(F1t) dt {
    // IF OVERRIDE, CALL SUPER
    
    if (_body && _body.isDynamic){
        [_body getTransform:&_localTransform];
        //NKLogV3(@"update physics position: ", V3GetM16Translation(localTransform));
        _dirty = true;
    }
    
    [animationHandler updateWithTimeSinceLast:dt];
    
    for (NKNode *child in _children) {
        [child updateWithTimeSinceLast:dt];
    }
}

-(void)pushStyle{
    _scene.cullFace = _cullFace;
    _scene.blendMode = _blendMode;
    _scene.usesDepth = _usesDepth;
}

-(void)draw {
//    
    if (_framebuffer) {
        [_framebuffer bind];
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glViewport(0, 0, _framebuffer.size.width, _framebuffer.size.height);
        //NSLog(@"binding fb: %d, %d %d", _framebuffer.renderTexture.glName, _framebuffer.size.width, _framebuffer.size.height);
    }
    
    [self customDraw];
    
    NSMutableSet *transparentChildren;
    
    for (NKNode *child in _children) {
        if (child.alpha == 1.) {
            [child draw];
        }
        else {
            if (!transparentChildren) {
                transparentChildren = [[NSMutableSet alloc] init];
            }
            [transparentChildren addObject:child];
        }
    }
    
    for (NKNode *tc in transparentChildren){
        [tc draw];
    }
    
    if (_framebuffer) {
        if (self.scene.framebuffer) {
            [self.scene.framebuffer bind];
        }
        else {
            [_framebuffer unbind];
            //NSLog(@"unbinding to scene");
        }
    }

}


-(void)setupViewMatrix {
    // OVERRIDE
}

-(void)drawWithHitShader {
    
    if (_userInteractionEnabled) {
         [self customdrawWithHitShader];
    }
    
    for (NKNode *child in _children) {
        [child drawWithHitShader];
    }
}

-(void)customDraw {
    // OVERRIDE IN SUB CLASS
}

-(void)customdrawWithHitShader {
    // OVERRIDE IN SUB CLASS
}

#pragma mark - GEOMETRY

-(P2t)inverseProjectedPoint:(P2t)location {
    
    M16t globalTransform = [self globalTransform];
    
    //    bool isInvertible;
    
    V3t transformed = V3MultiplyM16(globalTransform, V3Make(location.x, location.y, 0));
    
    //    if (!isInvertible) {
    //        NSLog(@"node inversion failed");
    //    }
    
    P2t p = P2Make(transformed.x, transformed.y);
    
    return p;
    
}
-(bool)containsPoint:(P2t)location {
    
    // OLD METHOD
    // ADDING LOCAL TRANSFORMATION
    
    P2t p = location;
    //P2tp = [self transformedPoint:location];
    
    //NSLog(@"world coords: %f %f %f", p.x, p.y, p.z);
    
    R4t r = [self getWorldFrame];
    
    //bool withinArea = false;
    if ( p.x > r.x && p.x < r.x + r.size.width && p.y > r.y && p.y < r.y + r.size.height)
    {
        // [self logCoords];
        return true;
    }
    return false;
    
    //    P2t p = [self inverseProjectedPoint:location];
    //
    //    V3t globalPos = [self globalPosition];
    //
    //    R4t r = R4Make(globalPos.x - _size.x * _anchorPoint3d.x, globalPos.y - _size.y *_anchorPoint3d.y, _size.x, _size.y);
    //
    //    //bool withinArea = false;
    //    if ( p.x > r.x && p.x < r.x + r.size.width && p.y > r.y && p.y < r.y + r.size.height)
    //    {
    //        // [self logCoords];
    //        return true;
    //    }
    //    return false;
    
}

-(V3t)globalPosition{
    return V3GetM16Translation([self globalTransform]);
}

-(R4t)getWorldFrame{
    V3t g = [self globalPosition];
    return R4Make(g.x - _size.x * _anchorPoint.x, g.y - _size.y *_anchorPoint.y, _size.x, _size.y);
    
}


-(R4t)getDrawFrame {
    //[self logCoords];
    //V3t g = node->getPosition();
    //return R4Make(g.x - _size.width * _anchorPoint.x, g.y - _size.height *_anchorPoint.y, _size.width, _size.height);
    return R4Make(-_size.x * _anchorPoint.x, -_size.y *_anchorPoint.y, _size.x, _size.y);
}


-(bool)shouldCull {
    return 0;
}

#pragma mark - MATH



#pragma mark - PROPERTIES

#pragma mark - MATRIX

-(void)setLocalTransform:(M16t)localTransform {
    [self setDirty:true];
    
    _localTransform = localTransform;
    _scale = V3GetM16Scale(_localTransform);
    
    if (_body) {
        [_body setTransform:[self globalTransform]];
    }
    
}

-(M16t)globalTransform {
    
    if (_dirty) {
        _dirty = false;
        if (!_parent) {
            return _cachedGlobalTransform = _localTransform;
        }
        return _cachedGlobalTransform = M16Multiply([_parent globalTransform],_localTransform);
    }
    else {
        return _cachedGlobalTransform;
    }
    
}

#pragma mark - POSITION

-(V3t)position {
    return _position;
}

// BASE, all position methods should call this:
-(void)setPosition:(V3t)position {
    _position = position;
    M16SetV3Translation(&_localTransform, _position);
    
    [self setDirty:true];
    
    if (_body){
        [_body setTransform:[self globalTransform]];
    }
}

-(void)setPosition2d:(V2t)position {
    [self setPosition:V3Make(position.x, position.y, _position.z)];
}

-(void)setXPosition:(float)position {
    _position.x = position;
    self.position = _position;
}
-(void)setYPosition:(float)position {
    _position.y = position;
    self.position = _position;
}
-(void)setZPosition:(float)position {
    _position.z = position;
    self.position = _position;
}

-(void) setGlobalPosition:(const V3t)p {
	if(_parent == NULL) {
		[self setPosition:p];
	} else {
        M16t global = [_parent globalTransform];
        M16Invert(&global);
        [self setPosition:V3MultiplyM16WithTranslation(global, p)];
	}
}

-(void)setDirty:(bool)dirty {
        _dirty = dirty;
        if (dirty) {
            for (NKNode *n in _children) {
                [n setDirty:dirty];
            }
        }
}


-(M16t)tranformMatrixInNode:(NKNode*)n{
    
    if (_parent == n || !_parent) {
        return _localTransform;
    }
    else {
        // recursive add
        return M16Multiply([_parent tranformMatrixInNode:n], _localTransform);
    }
}

-(P2t)positionInNode:(NKNode *)n {
    V3t p = [self convertPoint3d:V3Make(0,0,0) toNode:n];
    return P2Make(p.x, p.y);
}

-(V3t)positionInNode3d:(NKNode *)n {
    return V3GetM16Translation([self tranformMatrixInNode:n]);
}

#pragma mark - ANCHOR

-(void)setAnchorPoint:(V3t)anchorPoint {
    _anchorPoint = anchorPoint;
}

-(V3t)anchorPoint {
    return _anchorPoint;
}

-(void)setAnchorPoint2d:(P2t)anchorPoint {
    _anchorPoint.x = anchorPoint.x;
    _anchorPoint.y = anchorPoint.y;
}

-(P2t)anchorPoint2d {
    return P2Make(_anchorPoint.x, _anchorPoint.y);
}

#pragma mark - Orientation

-(M16t)localTransform {
    return _localTransform;
}

-(void) createMatrix {
    [self setDirty:true];
    
    _localTransform = M16Multiply(M16MakeScale(_scale), M16MakeRotate(_orientation));
    M16SetV3Translation(&(_localTransform), _position);
    
    if (_body) {
        [_body setTransform:[self globalTransform]];
    }
    //	if(scale[0]>0) axis[0] = localTransform.getRowAsVec3f(0)/scale[0];
    //	if(scale[1]>0) axis[1] = localTransform.getRowAsVec3f(1)/scale[1];
    //	if(scale[2]>0) axis[2] = localTransform.getRowAsVec3f(2)/scale[2];
    
    // [self logMatrix:localTransform];
}

//----------------------------------------
-(void) setOrientation:(const Q4t)q {
	_orientation = q;
	[self createMatrix];
}

//----------------------------------------
-(void) setOrientationEuler:(const V3t)eulerAngles {
    [self setOrientation:Q4FromV3(eulerAngles)];
}

-(Q4t) orientation{
	return _orientation;
}

-(Q4t)getGlobalOrientation {
    return Q4GetM16Rotate([self globalTransform]);
}

-(V3t)getOrientationEuler {
    return V3FromQ4(Q4GetM16Rotate([self globalTransform]));
}

-(F1t)getYOrientation {
    V3t raw = V3FromQ4(Q4GetM16Rotate([self localTransform]));
    
    if (raw.x < 0) {
        return -raw.y;
    }
    
    return raw.y;
}

-(void)setZRotation:(F1t)rotation {
    Q4t zRot = Q4FromAngleAndV3(rotation, V3Make(0,0,1));
    [self setOrientation:zRot];
}

-(void)setOrbit:(V3t)orbit {
    _longitude = orbit.x;
    _latitude = orbit.y;
    _radius = orbit.z;
    
//    if (_latitude >= 360) _latitude-=360.;
//    else if (_latitude <= -360) _latitude+=360.;
//    if (_longitude >= 360) _longitude-=360.;
//    else if (_longitude <= -360) _longitude+=360.;
}

-(V3t)currentOrbit {
    return [self orbitForLongitude:_longitude latitude:_latitude radius:_radius];
}

-(V3t)orbitForLongitude:(float)longitude latitude:(float)latitude radius:(float)radius { //centerPoint:(V3t)centerPoint {
    V3t p = V3RotatePoint(V3Make(0, 0, radius), longitude, V3Make(0, 1, 0));
    return V3RotatePoint(p, latitude, V3Make(1, 0, 0));
}

-(void)rotateMatrix:(M16t)M16 {
    M16t m = M16MakeScale(_scale);
    _localTransform = M16Multiply(m,M16);
    M16SetV3Translation(&_localTransform, _position);
}

//-(void)globalRotateMatrix:(M16t)M16 {
//    M16t m = M16MakeScale(scale);
//    //localTransform = M16TranslateWithV3(localTransform, position);
//    M16SetV3Translation(&m, position);
//    m = M16Multiply(m, M16);
//    localTransform = M16Multiply(m, M16InvertColumnMajor([_parent globalTransform], 0));
//}

-(void)lookAtNode:(NKNode*)node {
    [self lookAtPoint:[node globalPosition]];
}

-(void)lookAtPoint:(V3t)point {

    M16t new = [self getLookMatrix:point];

    [self rotateMatrix:new];
}

-(M16t)getLookMatrix:(V3t)lookAtPosition {

   return M16MakeLookAt(self.globalPosition, lookAtPosition, [self upVector]);
    
}

-(V3t)upVector {
    if (!_parent){
        return _upVector;
    }
    return V3MultiplyM16([_parent globalTransform], _upVector);
}

#pragma mark - SCALE

- (void)setXScale:(F1t)s {
    V3t nScale = _scale;
    nScale.x = s;
    [self setScale:nScale];
}

- (void)setYScale:(F1t)s {
    V3t nScale = _scale;
    nScale.y = s;
    [self setScale:nScale];
}

-(void)setScaleF:(F1t)s {
    _scale = V3MakeF(s);
}

-(void)setScale:(V3t)scale{
    _scale = scale;
	[self createMatrix];
}

-(V3t)scale {
    return _scale;
}

-(V2t)scale2d {
    return _scale.point;
}

#pragma mark - ALPHA / BLEND

-(void)setTransparency:(F1t)transparency { // just node
    intAlpha = transparency;
    _alpha = transparency * parentAlpha;
}

-(void)setAlpha:(F1t)alpha {
    intAlpha = alpha;
    _alpha = intAlpha * parentAlpha;
    
    for (NKNode* n in _children) {
        [n recursiveAlpha:(_alpha)];
    }
}

-(void)recursiveAlpha:(F1t)alpha{
    parentAlpha = alpha;
    _alpha = intAlpha * parentAlpha;
    
    for (NKNode* n in _children) {
        [n recursiveAlpha:(_alpha)];
    }
}

#pragma mark - COLOR

-(F1t)colorBlendFactor {
    return _colorBlendFactor;
}

-(void)setColorBlendFactor:(F1t)colorBlendFactor {
    _colorBlendFactor = colorBlendFactor;
}

-(void)setColor:(NKByteColor*)color {
    _color = [color copy];
}

-(NKByteColor*)color {
    return _color;
}

-(C4t)glColor {
    C4t color;
    
    if (_colorBlendFactor == 1.) {
        color = _color.C4Color;
    }
    else if (_colorBlendFactor == 0){
        color = C4Make(1., 1., 1., 1.);
    }
    else {
        color = [[self color] colorWithBlendFactor:_colorBlendFactor];
    }
    
    color.a *= self.alpha;
    
    return color;
}

#pragma mark - ACTIONS

-(void)removeAllActions {
    [animationHandler removeAllActions];
}

#pragma mark - EVENT HANDLING

-(void)setEventBlock:(EventBlock)eventBlock {
    _eventBlock = eventBlock;
}

-(void)handleEvent:(NKEvent*)event {
    if (_eventBlock) {
        _eventBlock(event);
    }
}


@end
