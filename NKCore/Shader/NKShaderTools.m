//
//  NKShaderVariable.m
//  EMA Stage
//
//  Created by Leif Shackelford on 5/24/14.
//  Copyright (c) 2014 EMA. All rights reserved.
//

#import "NodeKitten.h"

#define nksf NSString stringWithFormat

NSString* nksString(NKS_ENUM string) {
    
    switch (string) {
            
        // GL VAR TYPES
            
        case NKS_VARIABLE_ATTRIBUTE:
            return @"attribute";
        case NKS_VARIABLE_UNIFORM:
            return @"uniform";
        case NKS_VARIABLE_VARYING:
            return @"varying";
        case NKS_VARIABLE_INLINE:
            return @"";
            
            // GL PRECISION
            
        case NKS_PRECISION_LOW:
            return @"lowp";
        case NKS_PRECISION_MEDIUM:
            return @"mediump";
        case NKS_PRECISION_HIGH:
            return @"highp";
        case NKS_PRECISION_NONE:
            return @"";
            
            // GL VECTOR TYPES
        case NKS_TYPE_VOID:
            return @"void";
        case NKS_TYPE_F1:
            return @"float";
        case NKS_TYPE_M9:
            return @"mat3";
        case NKS_TYPE_M16:
            return @"mat4";
        case NKS_TYPE_V2:
            return @"vec2";
        case NKS_TYPE_V3:
            return @"vec3";
        case NKS_TYPE_V4:
            return @"vec4";
        case NKS_TYPE_INT:
            return @"int";
        case NKS_TYPE_BOOL:
            return @"bool";
        case NKS_TYPE_SAMPLER_2D:
            return @"sampler2D";
        case NKS_TYPE_SAMPLER_2D_RECT:
            return @"sampler2DRect";
            
        case NKS_STRUCT_LIGHT:
            return @"LightProperties";
        case NKS_STRUCT_MATERIAL:
            return @"MaterialProperties";
            // NK VAR NAMES
            // ATTRIBUTES
            
        case NKS_V2_TEXCOORD:
            return @"texCoord0";
        case NKS_V3_NORMAL:
            return @"normal";
        case NKS_V3_EYE_DIRECTION:
            return @"eyeDirection";
        // UNIFORMS
            
        case NKS_M16_MVP:
            return @"modelViewProjectionMatrix";
        case NKS_M16_MV:
            return @"modelViewMatrix";
        case NKS_M16_P:
            return @"projectionMatrix";
            
        case NKS_M9_NORMAL:
            return @"normalMatrix";
        case NKS_V4_COLOR:
            return @"color";
        case NKS_INT_USE_UNIFORM_COLOR:
            return @"useUniformColor";
        case NKS_INT_NUM_TEXTURES:
            return @"numTextures";
        case NKS_F1_INSTANCE:
            return @"instance";
        case NKS_INT_NUM_PASSES:
            return @"numPasses";
        case NKS_INT_CURRENT_PASS:
            return @"currentPass";
            
        case NKS_V4_POSITION:
            return @"position";
        
        case NKS_LIGHT:
            return @"light";
        case NKS_I1_NUM_LIGHTS:
            return @"numLights";
        case NKS_V3_LIGHT_DIRECTION:
            return @"lightDirection";
        case NKS_V3_LIGHT_HALF_VECTOR:
            return @"halfVector";
        case NKS_F1_ATTENUATION:
            return @"attenuation";
            
        case NKS_S2D_TEXTURE:
            return @"texture";
        case NKS_TEXTURE_RECT_SCALE:
            return @"textureScale";
            // GL BUILT IN
        case NKS_V3_GL_POSITION:
            return @"gl_position";
        case NKS_V4_GL_FRAG_COLOR:
#if NK_USE_GL3
            return @"FragColor";
#else
            return @"gl_FragColor";
#endif
        case NKS_F1_GL_LINEWIDTH:
            return @"gl_Linewidth";
            
        case NKS_UINT_GL_INSTANCE_ID:
#if TARGET_OS_IPHONE
            return @"gl_InstanceIDEXT";
#else
            return @"gl_InstanceID";
#endif
            

            
            // EXTENSIONS
        case NKS_EXT_DRAW_INSTANCED:
#if TARGET_OS_IPHONE
            //return @"";
            return @"#extension GL_EXT_draw_instanced : enable";
#else
            return @"#extension GL_ARB_draw_instanced : enable";
#endif
            
        case NKS_EXT_GPU_SHADER:
#if TARGET_OS_IPHONE
            return @"";
            //return @"#extension GL_OES_element_index_uint : enable";
#else
            return @"#extension GL_EXT_gpu_shader4 : enable";
#endif
            
        // DEFAULT SHADERS
        case NKS_PASSTHROUGH_TEXTURE_SHADER:
            return @"passThroughTextureShader";
        case NKS_PASSTHROUGH_UNIFORM_SHADER:
            return @"passThroughColorShader";
        // MODULES
            
        case NKS_FALSE_COLOR_DARK_COLOR:
            return @"falseColor_darkColor";
        case NKS_FALSE_COLOR_LIGHT_COLOR:
            return @"falseColor_lightColor";
        case NKS_FALSE_COLOR_INTENSITY:
            return @"falseColor_intensity";
            
        default: return @"((NKS_STRING_ENUM_ERROR))";
    }
    
}

NSString *shaderStringFromFile(NSString* name){
    NSString *path = [[NSBundle mainBundle]pathForResource:name ofType:@"nks.txt"];
    //NSString *headerFile = @"ERROR";
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"no file at path, %@",path);
        return nil;
    }
    return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
}

NSString* shaderStringWithDirective(NSString* name, NSString* directive){
    NSString *file = shaderStringFromFile(name);
    NSArray *parts = [file componentsSeparatedByString:directive];
    return parts[1];
}

NSString* shaderStringWithArray(NSArray *array){
    NSMutableString *ms = [[NSMutableString alloc]init];
    
    for (NSString *o in array) {
        if ([o isKindOfClass:[NKShaderVariable class]]) {
            [ms appendString:[(NKShaderVariable*)o nameString]];
        }
        else if ([o isKindOfClass:[NSNumber class]]){
            [ms appendFormat:@"%@",[(NSNumber*)o stringValue]];
        }
        else  if ([o isKindOfClass:[NSString class]]) {
            [ms appendString:(NSString*)o];
            if ([o characterAtIndex:o.length-1] == ';' || [o characterAtIndex:o.length-1] == '{' || [o characterAtIndex:o.length-1] == '}') {
                [ms appendString:@"\n"];
            }
        }
    }
    
    return ms;
}

NSString* shaderLineWithArray(NSArray *array) {
    NSString *ms = shaderStringWithArray(array);

    return [ms stringByAppendingString:@";\n"];

}

NSString* operatorString(NSArray* variables, NSString *operator) {
    NSMutableString *mult = [[nksf:@"%@", [variables[0] nameString]] mutableCopy];
    for (int i = 1; i < variables.count; i++) {
        [mult appendString:[nksf:@" %@ %@", operator, [variables[i] nameString]]];
    }
    return mult;
}

@implementation NKShaderFunction

-(NSString*)functionString {

    NSMutableString *functionString = [[NSString stringWithFormat:@"%@ %@ (%@ inputColor){ \n" ,nks(_returnType),_name,nks(_inputType) ] mutableCopy];
    
    [functionString appendString:_function];
    
    [functionString appendString:@"}\n"];
    
    return functionString;
}

@end

@implementation NKShaderVariable

+(instancetype)variableWith:(NKS_ENUM)variable type:(NKS_ENUM)type name:(NKS_ENUM)name {
    return [NKShaderVariable variableWith:variable precision:NKS_PRECISION_NONE type:type name:name];
}

+(instancetype)variableWith:(NKS_ENUM)variable precision:(NKS_ENUM)precision type:(NKS_ENUM)type name:(NKS_ENUM)name {
    
    NKShaderVariable *var = [[NKShaderVariable alloc] init];
    
    var.variable = variable;
    var.precision = precision;
    var.type = type;
    var.name = name;
    
    return var;
}

+(instancetype)variableArrayWith:(NKS_ENUM)variable precision:(NKS_ENUM)precision type:(NKS_ENUM)type name:(NKS_ENUM)name arraySize:(GLuint)arraySize {
    
    NKShaderVariable *var = [NKShaderVariable variableWith:variable precision:precision type:type name:name];
    var.arraySize = arraySize;
    
    return var;
}

-(NSString*)nameString {
    switch (_variable) {
        case NKS_VARIABLE_ATTRIBUTE:
            return [nksf:@"a_%@",nks(_name)];
            break;
            
        case NKS_VARIABLE_UNIFORM:
            return [nksf:@"u_%@",nks(_name)];
            break;
            
        case NKS_VARIABLE_VARYING:
            return [nksf:@"v_%@",nks(_name)];
            break;
            
        case NKS_VARIABLE_INLINE:
            return nks(_name);
            break;
            
        default:
            return @"NKS_ERROR";
    }

}

//-(NSString*)typeString {
// }

-(NSString*)description {
    return [self nameString];
}

-(NSString*)declarationStringForSection:(NKS_ENUM)section {
    
    NSMutableString *dec;
    
#if NK_USE_GL3
    
    if (_variable == NKS_VARIABLE_VARYING) {
        
        switch (section) {
            case NKS_VERTEX_SHADER:
                dec = [@"out" mutableCopy];
                break;
                
            case NKS_FRAGMENT_SHADER:
                dec = [@"in" mutableCopy];
                break;
                
            default:
                break;
        }
    }
    else if (_variable == NKS_VARIABLE_ATTRIBUTE) {
        dec = [[NSString stringWithFormat:@"layout (location = %d) in",_name] mutableCopy];
    }
    else {
        dec = [nks(_variable) mutableCopy];
    }
    
#else
    dec = [nks(_variable) mutableCopy];
#endif
#if NK_USE_GLES
    [dec appendFormat:@" %@",nks(_precision)];
#endif
    [dec appendFormat:@" %@",nks(_type) ];
    [dec appendFormat:@" %@",[self nameString]];
    if (_arraySize) [dec appendFormat:@"[%d]",_arraySize];
    [dec appendFormat:@";"];
    return dec;
}

#pragma mark - BINDING UNIFORMS

-(void)bindI1:(int)data {
    glUniform1i(_glLocation, data);
}

-(void)bindF1:(F1t)f {
    glUniform1f(_glLocation, f);
}

-(void)bindV2:(V2t)data {
#ifdef NK_USE_ARB_EXT
    glUniform2fvARB(_glLocation, 1, data.v);
#else
    glUniform2fv(_glLocation, 1, data.v);
#endif
}
-(void)bindV3:(V3t)data {
#ifdef NK_USE_ARB_EXT
    glUniform3fvARB(_glLocation, 1, data.v);
#else
    glUniform3fv(_glLocation, 1, data.v);
#endif
}

-(void)bindV4:(V4t)data {
#ifdef NK_USE_ARB_EXT
    glUniform4fvARB(_glLocation, 1, data.v);
#else
    glUniform4fv(_glLocation, 1, data.v);
#endif
}

-(void)bindM9:(M9t)data {
    glUniformMatrix3fv(_glLocation, 1, GL_FALSE, data.m);
}

-(void)bindM16:(M16t)data {
    glUniformMatrix4fv(_glLocation, 1, GL_FALSE, data.m);
}

-(void)bindV4Array:(V4t*)data count:(int)count {
#ifdef NK_USE_ARB_EXT
    glUniform4fvARB(_glLocation, count, data->v); glUniform4fv(_glLocation, count, data->v);
#else
    glUniform4fv(_glLocation, count, data->v);
#endif
}

-(void)bindM9Array:(M9t*)data count:(int)count {
    glUniformMatrix3fv(_glLocation, count, GL_FALSE, data->m);
}

-(void)bindM16Array:(M16t*)data count:(int)count {
    glUniformMatrix4fv(_glLocation, count, GL_FALSE, data->m);
}


-(void)bindLightProperties:(NKLightProperties*)data count:(int)count {
    for (int i = 0; i < count; i++) {
        glUniform3f(_glLocation, data->position.x, data->position.y, data->position.z);
        glUniform3fv(_glLocation+1, 1, data->ambient.v);
        glUniform3fv(_glLocation+2, 1, data->color.v);
        glUniform3fv(_glLocation+3, 1, data->coneDirection.v);
        glUniform3fv(_glLocation+4, 1, data->halfVector.v);
        
        glUniform1fv(_glLocation+5, 1, &data->spotCosCutoff);
        glUniform1fv(_glLocation+6, 1, &data->spotExponent);
        glUniform1fv(_glLocation+7, 1, &data->constantAttenuation);
        glUniform1fv(_glLocation+8, 1, &data->linearAttenuation);
        glUniform1fv(_glLocation+9, 1, &data->quadraticAttenuation);
        
        glUniform1i(_glLocation+10, data->isEnabled);
        glUniform1i(_glLocation+11, data->isLocal);
        glUniform1i(_glLocation+12, data->isSpot);
    }
}

@end


#pragma mark - CATEGORIES

@implementation NSMutableString (ShaderTools)

-(void)appendNewLine:(NSString*)newLine {
    [self appendFormat:@"%@ \n",newLine];
}

@end

@implementation NSString (ShaderTools)

-(NSArray*)arrayWithNoSpaces {
    NSArray *ca = [self componentsSeparatedByString:@" "];
    NSMutableArray *c = [NSMutableArray array];
    
    for (int i = 0; i < ca.count; i++){
        if (![ca[i] isEqualToString:@" "] && ![ca[i] isEqualToString:@""]){
            [c addObject:ca[i]];
        }
    }
    return c;
}

+(NSString*)nksIf:(NKShaderVariable *)var greaterThan:(float)greater trueString:(NSString *)trueString falseString:(NSString *)falseString {
    
    return [nksf:@"if (%@ > %f){ \n %@ \n } \n else { \n %@ \n }",
            nks(var.name),
            greater,
            trueString,
            falseString
            ];
}

+(NSString*)nksEquals:(NKShaderVariable*)varA r:(NKShaderVariable*)varB {
    return [nksf:@"%@ = %@;", varA.nameString, varB.nameString];
}

@end

@implementation NSMutableDictionary (ShaderTools)

@end

@implementation NSDictionary (ShaderTools)

-(NSString*)appendValueIfKey:(NSString*)key toShaderString:(NSString*)shader {
    NSString* value = [self valueForKey:key];
    if (value) {
        [shader appendNewLine:value];
    }
    // FIX THIS
    return value;
}

@end
