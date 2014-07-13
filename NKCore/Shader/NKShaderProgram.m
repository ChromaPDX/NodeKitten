//
//  NOCShaderProgram.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NodeKitten.h"


@implementation NKShaderProgram
{
    NSString *_vertShaderPath;
    NSString *_fragShaderPath;
}

- (id)initWithName:(NSString *)name
{
    self = [super init];
    if(self)
    {
        self.name = name;
        
        _vertShaderPath = [[NSBundle mainBundle] pathForResource:self.name
                                                          ofType:@"vsh"];
        _fragShaderPath = [[NSBundle mainBundle] pathForResource:self.name
                                                          ofType:@"fsh"];
        // NOTE: Maybe this should just return nil?
        assert( [[NSFileManager defaultManager] fileExistsAtPath:_vertShaderPath] );
        assert( [[NSFileManager defaultManager] fileExistsAtPath:_fragShaderPath] );
        
        _vertexSource =  [NSString stringWithContentsOfFile:_vertShaderPath encoding:NSUTF8StringEncoding error:nil];
        _fragmentSource = [NSString stringWithContentsOfFile:_fragShaderPath encoding:NSUTF8StringEncoding error:nil];
    }
    return self;
}

- (instancetype)initWithVertexShader:(NSString *)vertShaderName fragmentShader:(NSString *)fragShaderName
{
    self = [super init];
    if(self)
    {
        int dotIndex = [vertShaderName rangeOfString:@"."].location;
        if ( dotIndex != NSNotFound )
        {
            self.name = [vertShaderName substringToIndex:dotIndex];
        }
        else
        {
            self.name = vertShaderName;
        }
        
        _vertShaderPath = [[NSBundle mainBundle] pathForResource:vertShaderName ofType:nil];
        _fragShaderPath = [[NSBundle mainBundle] pathForResource:fragShaderName ofType:nil];
        
        // NOTE: Maybe this should just return nil?
        assert( [[NSFileManager defaultManager] fileExistsAtPath:_vertShaderPath] );
        assert( [[NSFileManager defaultManager] fileExistsAtPath:_fragShaderPath] );
        
        _vertexSource =  [NSString stringWithContentsOfFile:_vertShaderPath encoding:NSUTF8StringEncoding error:nil];
        _fragmentSource = [NSString stringWithContentsOfFile:_fragShaderPath encoding:NSUTF8StringEncoding error:nil];
    }
    return self;
}


-(instancetype)initWithVertexSource:(NSString *)vertexSource fragmentSource:(NSString *)fragmentSource {
    self = [super init];
    if(self)
    {
        _vertexSource = vertexSource;
        _fragmentSource = fragmentSource;
    }
    return self;
}

+(instancetype)shaderNamed:(NSString*)name {
    if ([NKShaderManager programCache][name]) {
        return [NKShaderManager programCache][name];
    }
    NSLog(@"ERROR shader program named: %@ not found", name);
    return nil;
}


+(instancetype)newShaderNamed:(NSString*)name colorMode:(NKS_COLOR_MODE)colorMode numTextures:(NSUInteger)numTex numLights:(int)numLights withBatchSize:(int)batchSize {
    
    if ([NKShaderManager programCache][name]) {
        return [NKShaderManager programCache][name];
    }
    
    return [[NKShaderProgram alloc] initWithName:name colorMode:colorMode numTextures:numTex numLights:numLights withBatchSize:batchSize];
}

+(instancetype)newShaderNamed:(NSString *)name modules:(NSArray *)nmodules batchSize:(int)batchSize {
    if ([NKShaderManager programCache][name]) {
        return [NKShaderManager programCache][name];
    }
    
    return [[NKShaderProgram alloc]initWithNamed:name modules:nmodules batchSize:batchSize];
}

-(instancetype)init {
    if ( self = [super init] ) {
        attributes = [NSMutableArray array];
        uniforms = [NSMutableSet set];
        varyings = [NSMutableSet set];
        vertMain = [NSMutableArray array];
        fragMain = [NSMutableArray array];
        modules = [NSMutableArray array];
        
        NSLog(@"init shader");
        
        // ADD BASICS
        
        [self addAttribute:nksa(NKS_TYPE_V4, NKS_V4_POSITION)];
        [self addAttribute:nksa(NKS_TYPE_V3, NKS_V3_NORMAL)];
        [self addAttribute:nksa(NKS_TYPE_V2, NKS_V2_TEXCOORD)];
        [self addAttribute:nksa(NKS_TYPE_V4, NKS_V4_COLOR)];
    }
    return self;
}

-(instancetype)initWithNamed:(NSString *)name modules:(NSArray *)nmodules batchSize:(int)batchSize {
    
    if ([NKShaderManager programCache][name]) {
        return [NKShaderManager programCache][name];
    }
    
    NSLog(@"new shader dict");
    
    if (self = [self init]){
        
        _name = name;
        _batchSize = batchSize;
        
        if (batchSize) {
            [self addUniform:nksua(NKS_PRECISION_HIGH, NKS_TYPE_M16, NKS_M16_MVP, batchSize)];
        }
        else {
            [self addUniform:nksu(NKS_PRECISION_HIGH, NKS_TYPE_M16, NKS_M16_MVP)];
        }
        
        // INSTANCE ID's for batch
        
        if (batchSize) {
            extensions = @[nks(NKS_EXT_DRAW_INSTANCED),nks(NKS_EXT_GPU_SHADER)];
        }
        
        modules = [nmodules mutableCopy];
        
        /////// COMPILE /////////
        
        [self calculateCommonVertexVaryings];
        [self writeShaderStrings];
        
        if ([self load]) {
            [NKShaderManager programCache][_name]=self;
            NSLog(@"*** generate shader *%d* named: %@ ***", self.glPointer, _name);
        }
        else {
            NSLog(@"ERROR LOADING SHADER");
        }
    }
    return self;
    
}

-(instancetype)initWithName:(NSString*)name colorMode:(NKS_COLOR_MODE)colorMode numTextures:(NSUInteger)numTex numLights:(int)numLights withBatchSize:(int)batchSize {
    
    if ( self = [self init] ) {
        
        _name = name;
        _batchSize = batchSize;
        
        if (batchSize) {
            [self addUniform:nksua(NKS_PRECISION_HIGH, NKS_TYPE_M16, NKS_M16_MVP, batchSize)];
        }
        else {
            [self addUniform:nksu(NKS_PRECISION_HIGH, NKS_TYPE_M16, NKS_M16_MVP)];
        }
        
        // INSTANCE ID's for batch
        
        if (batchSize) {
            extensions = @[nks(NKS_EXT_DRAW_INSTANCED),nks(NKS_EXT_GPU_SHADER)];
        }
        
        // ADD MODULES
        
        if (colorMode != NKS_COLOR_MODE_NONE) {
            [modules addObject:[NKShaderModule colorModule:colorMode batchSize:batchSize]];
        }
        
        if (numTex != 0) {
            [modules addObject:[NKShaderModule textureModule:numTex]];
        }
        
        if (numLights) {
#if NK_USE_GLES
            [modules addObject:[NKShaderModule lightModule:false batchSize:batchSize]];
#else
            [modules addObject:[NKShaderModule lightModule:true batchSize:batchSize]];
#endif
        }
        
        
        [self calculateCommonVertexVaryings];
        
      //  [self serializeModules];
        
        [self writeShaderStrings];
        
        if ([self load]) {
            [NKShaderManager programCache][_name]=self;
            NSLog(@"*** generate shader *%d* named: %@ ***", self.glPointer, _name);
        }
        else {
            NSLog(@"ERROR LOADING SHADER");
        }
        
    }
    
    
    return self;
    
}

-(void)calculateCommonVertexVaryings {
    
    // ADD COMMON VERTEX VARYINGS FOR MODULES
    
    // NORMAL MATRIX
    
    if ([self uniformNamed:NKS_M9_NORMAL]) {
        if (_batchSize) {
#if NK_USE_GLES
            [vertMain addObject:@"v_normal = normalize(u_normalMatrix[gl_InstanceIDEXT] * a_normal);"];
#else
            [vertMain addObject:@"v_normal = normalize(u_normalMatrix[gl_InstanceID] * a_normal);"];
#endif
        }
        else {
            [vertMain addObject:@"v_normal = normalize(u_normalMatrix * a_normal);"];
        }
    }
    
    // EYE POSITION USING MODEL MATRIX
    
    if ([self uniformNamed:NKS_M16_MV]) {
        if (_batchSize) {
#if NK_USE_GLES
            [vertMain addObject:@"v_position = u_modelViewMatrix[gl_InstanceIDEXT] * a_position;"];
#else
            [vertMain addObject:@"v_position = u_modelViewMatrix[gl_InstanceID] * a_position;"];
#endif
        }
        else {
            [vertMain addObject:@"v_position = u_modelViewMatrix * a_position;"];
        }
    }
    
    // MODEL VIEW PROJECTION MATRIX
    
    if ([self uniformNamed:NKS_M16_MVP]) {
        
        if (_batchSize) {
#if NK_USE_GLES
            [vertMain addObject:@"gl_Position = u_modelViewProjectionMatrix[gl_InstanceIDEXT] * a_position;"];
#else
            [vertMain addObject:@"gl_Position = u_modelViewProjectionMatrix[gl_InstanceID] * a_position;"];
#endif
        }
        else {
            [vertMain addObject:@"gl_Position = u_modelViewProjectionMatrix * a_position;"];
        }
        
    }
    
}

-(NSArray*)uniformNames {
    NSMutableArray *names = [NSMutableArray array];
    
    for (NKShaderVariable *v in uniforms) {
        [names addObject:v.nameString];
    }
    
    return names;
    
}

-(NSString*)vertexString {
    
    NSMutableString *shader = [NKS_GLSL_VERSION mutableCopy];
  [shader appendNewLine:@"\n//*** NK VERTEX SHADER ***//\n"];
    
#if NK_USE_GL3
    [shader appendNewLine:@"#version 330 core"];
#else
    for (NSString* s in extensions) {
        [shader appendNewLine:s];
    }
#endif
    
    
#if NK_USE_GLES
    [shader appendNewLine:@"precision highp float;"];
#else
    
#endif
    
    for (NKShaderModule *module in modules){
        [shader appendString:module.types];
    }
    
    for (NKShaderVariable* v in attributes) {
        [shader appendNewLine:[v declarationStringForSection:NKS_VERTEX_SHADER]];
    }
    for (NKShaderVariable* v in uniforms) {
        [shader appendNewLine:[v declarationStringForSection:NKS_VERTEX_SHADER]];
    }
    for (NKShaderVariable* v in varyings) {
        [shader appendNewLine:[v declarationStringForSection:NKS_VERTEX_SHADER]];
    }
    
    for (NKShaderModule *module in modules){
        for (NKShaderVariable* v in module.uniforms){
            [shader appendNewLine:[v declarationStringForSection:NKS_VERTEX_SHADER]];
        }
        for (NKShaderVariable* v in module.varyings){
            [shader appendNewLine:[v declarationStringForSection:NKS_VERTEX_SHADER]];
        }
    }
    
    [shader appendNewLine:@"void main() {"];
    
    for (NSString* s in vertMain) {
        [shader appendNewLine:s];
    }
    
    for (NKShaderModule *module in modules){
        if (module.vertexMain) {
            [shader appendString:module.vertexMain];
        }
    }
    

    
    [shader appendNewLine:@"}"];
    
    return shader;
}

-(NSString*)fragmentString {
    
    NSMutableString *shader = [NKS_GLSL_VERSION mutableCopy];
    
    [shader appendNewLine:@"\n//*** NK FRAGMENT SHADER ***//\n"];
    
#if NK_USE_GL3
    [shader appendNewLine:@"#version 330 core"];
    
    [shader appendNewLine:@"layout ( location = 0 ) out vec4 FragColor;"];
    
#else
    for (NSString* s in extensions) {
        [shader appendNewLine:s];
    }
#endif
    
#if NK_USE_GLES
    [shader appendNewLine:@"precision highp float;"];
#else
#endif
    
    for (NKShaderModule *module in modules){
        if (module.types) {
            [shader appendString:module.types];
        }
    }
    
    for (NKShaderVariable* v in uniforms) {
        [shader appendNewLine:[v declarationStringForSection:NKS_FRAGMENT_SHADER]];
    }
    for (NKShaderVariable* v in varyings) {
        [shader appendNewLine:[v declarationStringForSection:NKS_FRAGMENT_SHADER]];
    }
    
    for (NKShaderModule *module in modules){
        for (NKShaderVariable* v in module.uniforms){
            [shader appendNewLine:[v declarationStringForSection:NKS_FRAGMENT_SHADER]];
        }
        for (NKShaderVariable* v in module.varyings){
            [shader appendNewLine:[v declarationStringForSection:NKS_FRAGMENT_SHADER]];
        }
    }
    
     for (NKShaderModule *m in modules){
         for (NKShaderFunction* f in m.fragFunctions) {
             [shader appendNewLine:f.functionString];
         }
     }
    
    [shader appendNewLine:@"void main() {"];
    
    [shader appendNewLine:@"vec4 inputColor = vec4(1.0);"];
    
    for (NSString* s in fragMain) {
        [shader appendNewLine:s];
    }
    
    [shader appendString:[NSString stringWithFormat:@"%@ = ",nks(NKS_V4_GL_FRAG_COLOR)]];
                          
    for (int i = modules.count-1; i >= 0 ; i--){
        
        NKShaderModule *module = modules[i];
        NKShaderFunction *function = module.fragFunctions[0];
        
        if (i == 0) {
            [shader appendString:[NSString stringWithFormat:@"%@(inputColor", function.name ]];
            for (int p = 0; p < modules.count; p++){
                [shader appendString:@")"];
            }
            [shader appendString:@";\n"];
        }
        else {
                [shader appendString:[NSString stringWithFormat:@"%@(", function.name ]];
        }
    }
    
//    NSMutableArray *colorMults = [NSMutableArray array];
//
//    for (NKShaderModule *module in modules) {
//        [colorMults addObject:module.outputColor];
//    }
//    
//    [shader appendString:shaderLineWithArray(@[nks(NKS_V4_GL_FRAG_COLOR), @" = ", operatorString(colorMults, @"*"),@";"])];
    
    [shader appendNewLine:@"}"];
    
    return shader;
    
}

- (void)writeShaderStrings {
#if NK_LOG_GL
    NSLog(@"format shader strings");
#endif
    _vertexSource = [self vertexString];
#if NK_LOG_GL
    NSLog(@"%@",_vertexSource);
#endif
    _fragmentSource = [self fragmentString];
#if NK_LOG_GL
    NSLog(@"%@",_fragmentSource);
#endif
#if NK_LOG_GL
    NSLog(@"load shader");
#endif
    
}

- (BOOL)load
{
    
    GLuint vertShader, fragShader;
    
    // Create shader program.
    self.glPointer = glCreateProgram();
    
    // Create and compile vertex shader.
    if ( ![self compileShader:&vertShader type:GL_VERTEX_SHADER shaderSource:_vertexSource] )
    {
#if NK_LOG_GL
        NSLog(@"%@",_vertexSource);
#endif
        NSAssert(0,@"Failed to compile VERTEX shader: %@", self.name);
        //NSLog(@"Failed to compile VERTEX shader: %@", self.name);
        return NO;
    }
    
    // Create and compile fragment shader.
    if ( ![self compileShader:&fragShader type:GL_FRAGMENT_SHADER shaderSource:_fragmentSource] )
    {
#if NK_LOG_GL
        NSLog(@"%@",_fragmentSource);
#endif
        NSAssert(0,@"Failed to compile FRAGMENT shader: %@", self.name);
        //NSLog(@"Failed to compile FRAGMENT shader: %@", self.name);
        return NO;
    }
    
    GetGLError();
    
    // Attach vertex shader to program.
    glAttachShader(self.glPointer, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(self.glPointer, fragShader);
    
    GetGLError();
    
    numAttributes = 0;
    
    //#if TARGET_OS_IPHONE
    for (NKShaderVariable *v in attributes) {
        NSString *attrName = v.nameString;
        glEnableVertexAttribArray(numAttributes);
        glBindAttribLocation(self.glPointer, numAttributes, [attrName UTF8String]);
        numAttributes++;
    }
    //#endif
    
    GetGLError();
    
    // Link program.
    if ( ![self linkProgram:self.glPointer] )
    {
        
        NSLog(@"Failed to link program: %@", self.name);
        
        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (self.glPointer)
        {
            glDeleteProgram(self.glPointer);
            self.glPointer = 0;
        }
        
        return NO;
    }
    
    GetGLError();
    
    for (NKShaderVariable *v in attributes) {
        
        v.glLocation = glGetAttribLocation(self.glPointer, [v.nameString UTF8String]);
        if (v.glLocation) {
            //glEnableVertexAttribArray(v.glLocation);
        }
        
#if NK_LOG_GL
        NSLog(@"Attribute location %d, string %@",v.glLocation, v.nameString);
#endif
    }
    
    GetGLError();
    
    for (NKShaderVariable *v in uniforms) {
        int uniLoc = glGetUniformLocation(self.glPointer, [v.nameString UTF8String]);
        if (uniLoc > -1)
        {
            v.glLocation = uniLoc;//_uniformLocations[uniName] = @(uniLoc);
            //NSLog(@"Uniform location %d, %@",v.glLocation, v.nameString);
        }
        else
        {
            NSLog(@"WARNING: Couldn't find location for uniform named: %@", v.nameString);
        }
    }
    
    for (NKShaderModule *m in modules){
        
        for (NKShaderVariable *v in m.uniforms) {
            int uniLoc = glGetUniformLocation(self.glPointer, [v.nameString UTF8String]);
            if (uniLoc > -1)
            {
                v.glLocation = uniLoc;//_uniformLocations[uniName] = @(uniLoc);
                //NSLog(@"Uniform location %d, %@",v.glLocation, v.nameString);
            }
            else
            {
                NSLog(@"WARNING: Couldn't find location for uniform named: %@", v.nameString);
            }
        }
        
    }
    
    GetGLError();
    
    if ([self uniformNamed:NKS_LIGHT]) {
        
        NSLog(@"getting positions for Light properties");
        
        [self uniformNamed:NKS_LIGHT].glLocation = glGetUniformLocation(self.glPointer, "u_light.position");
        
//                NSArray *members = @[@"isEnabled",@"isLocal",@"isSpot",@"ambient",@"color",@"position",@"halfVector",@"coneDirection",
//                                     @"spotCosCutoff", @"spotExponent",@"constantAttenuation",@"linearAttenuation",@"quadraticAttenuation"];
//        
//                for (NSString *member in members) {
//        
//                    NSString *name = [@"u_light." stringByAppendingString:member];
//                    int uniLoc = glGetUniformLocation(self.glPointer, [name UTF8String]);
//                    if (uniLoc > -1)
//                    {
//                         NSLog(@"Uniform location %d, %@",uniLoc, name);
//                    }
//        
//                }
        
    }
    // Store the locations in an immutable collection
    
    // Release vertex and fragment shaders.
    if (vertShader)
    {
        glDetachShader(self.glPointer, vertShader);
        glDeleteShader(vertShader);
    }
    
    if (fragShader)
    {
        glDetachShader(self.glPointer, fragShader);
        glDeleteShader(fragShader);
    }
    
    GetGLError();
    
    return YES;
    
}


- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    return [self compileShader:shader type:type shaderSource:
            [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil]];
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type shaderSource:(NSString *)shaderSource {
    
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[shaderSource UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader: %@", self.name);
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if NK_LOG_GL
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
    
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if NK_LOG_GL
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
    {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
    {
        return NO;
    }
    
    return YES;
}

#pragma mark - QUERY

-(BOOL)isEqual:(id)object {
    return _glPointer == ((NKShaderProgram*)object).glPointer;
}

-(void)addAttribute:(NKShaderVariable*)attribute {
    [attributes addObject:attribute];
}

-(void)addUniform:(NKShaderVariable*)uniform{
    [uniforms addObject:uniform];
}

-(void)addVarying:(NKShaderVariable*)varying {
    [varyings addObject:varying];
}

-(void)addModule:(NKShaderModule*)module {
    [modules addObject:module];
}

-(NKShaderVariable*)attributeNamed:(NKS_ENUM)name {
    
    for (NKShaderVariable *v in attributes){
        if (v.name == name) return v;
    }
    return nil;
}

-(NKShaderVariable*)uniformNamed:(NKS_ENUM)name {
    for (NKShaderModule *module in modules) {
        for (NKShaderVariable *v in module.uniforms){
            if (v.name == name) return v;
        }
    }
    
    for (NKShaderVariable *v in uniforms){
        if (v.name == name) return v;
    }
    
    return nil;
}

-(NKShaderVariable*)varyingNamed:(NKS_ENUM)name {
    
    for (NKShaderModule *module in modules) {
        for (NKShaderVariable *v in module.varyings){
            if (v.name == name) return v;
        }
    }
    
    for (NKShaderVariable *v in varyings){
        if (v.name == name) return v;
    }
    
    return nil;
}


-(NKShaderVariable*)vertVarNamed:(NKS_ENUM)name {
    for (NKShaderVariable *v in vertMain){
        if ([v isKindOfClass:[NKShaderVariable class]]) {
            if (v.name == name) return v;
        }
    }
    return nil;
}

-(NKShaderVariable*)fragVarNamed:(NKS_ENUM)name {
    for (NKShaderVariable *v in fragMain){
        if ([v isKindOfClass:[NKShaderVariable class]]) {
            if (v.name == name) return v;
        }
    }
    return nil;
}

- (void)unload
{
    if (self.glPointer)
    {
        NSLog(@"unload shader %d", self.glPointer);
        glDeleteProgram(self.glPointer);
        self.glPointer = 0;
    }
}

-(void)dealloc {
    [self unload];
}

- (void)use
{
    glUseProgram(self.glPointer);
}

#define gl_debug

//- (void)enableAttribute3D:(NSString *)attribName withArray:(const GLvoid*)arrayValues
//{
//    NSNumber *attrVal = self.attributes[attribName];
//    assert(attrVal);
//    GLuint attrLoc = [attrVal intValue];
//    glVertexAttribPointer(attrLoc, 3, GL_FLOAT, GL_FALSE, 0, arrayValues);
//    glEnableVertexAttribArray(attrLoc);
//}
//
//- (void)enableAttribute2D:(NSString *)attribName withArray:(const GLvoid*)arrayValues
//{
//    NSNumber *attrVal = self.attributes[attribName];
//    assert(attrVal);
//    GLuint attrLoc = [attrVal intValue];
//    glVertexAttribPointer(attrLoc, 2, GL_FLOAT, GL_FALSE, 0, arrayValues);
//    glEnableVertexAttribArray(attrLoc);
//}

//- (void)disableAttributeArray:(NSString *)attribName
//{
//    NSNumber *attrVal = self.attributes[attribName];
//    assert(attrVal);
//    GLuint attrLoc = [attrVal intValue];
//    glDisableVertexAttribArray(attrLoc);
//}

@end
