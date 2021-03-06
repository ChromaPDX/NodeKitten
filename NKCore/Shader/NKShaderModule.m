//
//  NKFragModule.m
//  NodeKittenIOS
//
//  Created by Leif Shackelford on 7/12/14.
//  Copyright (c) 2014 chroma. All rights reserved.
//

#import "NodeKitten.h"

@implementation NKShaderModule

-(instancetype)init {
    if (self = [super init]){
        _uniforms = [[NSMutableArray alloc] init];
        _varyings = [[NSMutableArray alloc] init];
        _types = SHADER_STRING();
    }
    return self;
}

+(NKShaderModule*) colorModule:(NKS_COLOR_MODE)colorMode batchSize:(int)batchSize {
    
    NKShaderModule* module = [[NKShaderModule alloc] init];
    
    module.name = @"vertex color module";
    
    if (colorMode == NKS_COLOR_MODE_NONE) {
        return nil;
    }
    
    [module.varyings addObject:nksv(NKS_PRECISION_MEDIUM, NKS_TYPE_V4, NKS_V4_COLOR)];
    
    if (colorMode == NKS_COLOR_MODE_UNIFORM) {
        if (batchSize) {
            [module.uniforms addObject:nksua(NKS_PRECISION_MEDIUM, NKS_TYPE_V4, NKS_V4_COLOR, batchSize)];
        }
        else {
            [module.uniforms addObject:nksu(NKS_PRECISION_MEDIUM, NKS_TYPE_V4, NKS_V4_COLOR)];
        }
    }
    
    if (colorMode == NKS_COLOR_MODE_UNIFORM) {
        if (batchSize) {
#if NK_USE_GLES
            module.vertexMain = SHADER_STRING(
                                              v_color = u_color[gl_InstanceIDEXT];
                                              );
#else
            module.vertexMain = SHADER_STRING(
                                              v_color = u_color[gl_InstanceID];
                                              );
#endif
        }
        else {
            module.vertexMain = SHADER_STRING(
                                              v_color = u_color;
                                              );
        }
    }
    else if (colorMode == NKS_COLOR_MODE_VERTEX) {
        module.vertexMain = SHADER_STRING(
                                          v_color = a_color;
                                          );
    }
    
    NKShaderFunction *colorFunction = [[NKShaderFunction alloc]init];
    
    colorFunction.name = @"nkColorFunc";
    colorFunction.inputType = NKS_TYPE_V4;
    colorFunction.returnType = NKS_TYPE_V4;
    
    colorFunction.function = SHADER_STRING
    (
     return inputColor * v_color;
     );
    
    module.fragFunctions = @[colorFunction];
    
    // module.outputColor = nksv(NKS_PRECISION_MEDIUM, NKS_TYPE_V4, NKS_V4_COLOR);
    
    return module;
}

+(NKShaderModule*) materialModule:(int)numTex {
    
    NKShaderModule* module = [[NKShaderModule alloc] init];
    
    module.name = @"texture module";
    
    module.types = SHADER_STRING
    (
     struct MaterialProperties {
         vec3 emission;
         vec3 ambient;
         vec3 diffuse;
         vec3 specular;
         float shininess;
     }
     );
    
    return module;
}

+(NKShaderModule*) textureModule:(int)numTex {
    
    NKShaderModule* module = [[NKShaderModule alloc] init];
    
    module.name = @"texture module";
    
    if (numTex == -1){ // quick vid fix
        [module.uniforms addObject: nksu(NKS_PRECISION_LOW, NKS_TYPE_SAMPLER_CORE_VIDEO, NKS_S2D_TEXTURE)];
        [module.uniforms addObject: nksu(NKS_PRECISION_MEDIUM, NKS_TYPE_V2, NKS_TEXTURE_RECT_SCALE)];
        [module.varyings addObject: nksv(NKS_PRECISION_MEDIUM, NKS_TYPE_V2, NKS_V2_TEXCOORD)];
        
        if ([module uniformNamed:NKS_S2D_TEXTURE].type == NKS_TYPE_SAMPLER_2D) {
            module.vertexMain = @"v_texCoord0 = vec2(a_texCoord0.x, 1. - a_texCoord0.y);";
        }
        else {
            module.vertexMain = @"v_texCoord0 = vec2(a_texCoord0.x, 1. - a_texCoord0.y) * u_textureScale;";
        }
        
    }
    
    else if (numTex) {
        [module.uniforms addObject: nksu(NKS_PRECISION_LOW, NKS_TYPE_SAMPLER_2D, NKS_S2D_TEXTURE)];
        [module.varyings addObject: nksv(NKS_PRECISION_MEDIUM, NKS_TYPE_V2, NKS_V2_TEXCOORD)];
        
        module.vertexMain = @"v_texCoord0 = a_texCoord0;";
    }
    
    NKShaderFunction *texFunction = [[NKShaderFunction alloc]init];
    
    texFunction.name = @"nkTexFunc";
    texFunction.inputType = NKS_TYPE_V4;
    texFunction.returnType = NKS_TYPE_V4;
    
    if ([module uniformNamed:NKS_S2D_TEXTURE]) {
        
#if NK_USE_GL3
        texFunction.function = @"return inputColor * texture(u_texture,v_texCoord0);";
#else
        if ([module uniformNamed:NKS_S2D_TEXTURE].type == NKS_TYPE_SAMPLER_2D_RECT) {
            texFunction.function = @"vec4 textureColor = texture2DRect(u_texture,v_texCoord0); if (textureColor.a < .1) discard; return textureColor * inputColor;";
        }
        else {
            texFunction.function = @"vec4 textureColor = texture2D(u_texture,v_texCoord0); if (textureColor.a < .1) discard; return textureColor * inputColor;";
        }
#endif
    }
    
    module.fragFunctions = @[texFunction];
    
    return module;
    
}

+(NKShaderModule*) lightModule:(bool)highQuality batchSize:(int)batchSize {
    
    NKShaderModule* module = [[NKShaderModule alloc] init];

#if TARGET_OS_IPHONE
    module.types =
    @"struct LightProperties {\
    \n\
    highp vec3 position;\
    lowp vec3 ambient;\
    lowp vec3 color;\
    lowp vec3 halfVector;\
    lowp vec3 coneDirection;\
    float spotCosCutoff;\
    float spotExponent;\
    float constantAttenuation;\
    float linearAttenuation;\
    float quadraticAttenuation;\
    bool isEnabled;\
    bool isLocal;\
    bool isSpot;\
    };";
#else
    module.types =
    @"struct LightProperties {\
    \n\
    vec3 position;\
    vec3 ambient;\
    vec3 color;\
    vec3 halfVector;\
    vec3 coneDirection;\
    float spotCosCutoff;\
    float spotExponent;\
    float constantAttenuation;\
    float linearAttenuation;\
    float quadraticAttenuation;\
    bool isEnabled;\
    bool isLocal;\
    bool isSpot;\
    };";
#endif


    [module.uniforms addObjectsFromArray:@[nksu(NKS_PRECISION_NONE, NKS_TYPE_INT, NKS_I1_NUM_LIGHTS),
                                           nksu(NKS_PRECISION_NONE, NKS_STRUCT_LIGHT, NKS_LIGHT)
                                           ]];
    
    if (batchSize) {
        [module.uniforms addObject:nksua(NKS_PRECISION_HIGH, NKS_TYPE_M16, NKS_M16_MV, batchSize)];
        [module.uniforms addObject:nksua(NKS_PRECISION_MEDIUM, NKS_TYPE_M9, NKS_M9_NORMAL, batchSize)];
    }
    else {
        [module.uniforms addObject:nksu(NKS_PRECISION_HIGH, NKS_TYPE_M16, NKS_M16_MV)];
        [module.uniforms addObject:nksu(NKS_PRECISION_MEDIUM, NKS_TYPE_M9, NKS_M9_NORMAL)];
    }
    
    [module.varyings addObject:nksv(NKS_PRECISION_MEDIUM, NKS_TYPE_V3, NKS_V3_NORMAL)];
    [module.varyings addObject:nksv(NKS_PRECISION_MEDIUM, NKS_TYPE_V3, NKS_V3_EYE_DIRECTION)];
    
    [module.varyings addObject:nksv(NKS_PRECISION_LOW, NKS_TYPE_V3, NKS_V3_LIGHT_HALF_VECTOR)];
    [module.varyings addObject:nksv(NKS_PRECISION_LOW, NKS_TYPE_F1, NKS_F1_ATTENUATION)];
    
    [module.varyings addObject:nksv(NKS_PRECISION_MEDIUM, NKS_TYPE_V4, NKS_V4_POSITION)];
    [module.varyings addObject:nksv(NKS_PRECISION_LOW, NKS_TYPE_V3, NKS_V3_LIGHT_DIRECTION)];
    
    //module.outputColor = nksi(NKS_PRECISION_LOW, NKS_TYPE_V4, NKS_V4_LIGHT_COLOR);
    
    NKShaderFunction *lightFunction = [[NKShaderFunction alloc]init];
    
    lightFunction.name = @"nkLightFunc";
    lightFunction.inputType = NKS_TYPE_V4;
    lightFunction.returnType = NKS_TYPE_V4;
    
    if (highQuality) {
        
        module.name = @"HQ LIGHT PROGRAM";
        
        module.vertexMain = SHADER_STRING
        (
         v_eyeDirection = v_position.xyz;
         );
        
        lightFunction.function = SHADER_STRING
        (
         // HQ LIGHT MODULE
         
         vec3 scatteredLight = vec3(0.0);
         vec3 reflectedLight = vec3(0.0);
         
         float Strength = 4.;
         float Shininess = 10.;
         
         if (u_numLights > 0){
             for (int i = 0; i < u_numLights; i++){
                 
                 vec3 halfVector;
                 vec3 lightDirection = u_light.position - v_position.xyz;
                 
                 float attenuation = 1.0;
                 if (u_light.isLocal) { //
                     float lightDistance = length(lightDirection);
                     lightDirection = lightDirection / lightDistance; // (normalize) ? ;
                     attenuation = 1.0 / (u_light.constantAttenuation + (u_light.linearAttenuation * lightDistance) + (u_light.quadraticAttenuation * lightDistance * lightDistance));
                     if (u_light.isSpot) {
                         float spotCos = dot(lightDirection,-u_light.coneDirection);
                         if (spotCos < u_light.spotCosCutoff) attenuation = 0.0;
                         else attenuation *= pow(spotCos,u_light.spotExponent);
                     }
                     halfVector = normalize(lightDirection + v_eyeDirection);
                 }
                 else {
                     halfVector = u_light.halfVector;
                 }
                 
                 float diffuse = max(0.0, dot(v_normal, lightDirection));
                 float specular = max(0.0, dot(reflect(lightDirection, v_normal), halfVector));
                 
                 if (diffuse == 0.0) specular = 0.0;
                 else specular = pow(specular, Shininess) * Strength;
                 
                 // Accumulate all the u_lights’ effects
                 scatteredLight += u_light.ambient * attenuation + u_light.color * diffuse * attenuation;
                 reflectedLight += u_light.color * specular * attenuation;
             }
             //vec3 rgb = min(Color.rgb * scatteredLight + reflectedLight, vec3(1.0));
             //FragColor = vec4(rgb, Color.a);
             return vec4(min(scatteredLight + reflectedLight,vec3(1.0)), 1.0) * inputColor;
         }
         else {
             return inputColor;
         }
         );
        
    }
    
    // LOW QUALITY
    else {
        
        module.name = @"LQ LIGHT PROGRAM";
        
        module.vertexMain = SHADER_STRING
        (
         v_eyeDirection = v_position.xyz;
         
         if (u_light.isLocal) {
             
             v_lightDirection =  u_light.position - v_position.xyz;
             float lightDistance = length(v_lightDirection);
             v_lightDirection = v_lightDirection / lightDistance; // (normalize) ? ;
             v_attenuation = 1.0 / (u_light.constantAttenuation + (u_light.linearAttenuation * lightDistance) + (u_light.quadraticAttenuation * lightDistance * lightDistance));
             if (u_light.isSpot) {
                 float spotCos = dot(v_lightDirection,-u_light.coneDirection);
                 if (spotCos < u_light.spotCosCutoff) v_attenuation = 0.0;
                 else v_attenuation *= pow(spotCos,u_light.spotExponent);
             }
             v_halfVector = normalize(v_lightDirection + v_eyeDirection);
             
         }
         else {
             v_halfVector = u_light.halfVector;
         }
         );
        
        lightFunction.function = SHADER_STRING
        (
         // LQ LIGHT PROGRAM
         
         vec3 scatteredLight = vec3(0.0);
         vec3 reflectedLight = vec3(0.0);
         
         float Strength = 2.;
         float Shininess = 20.;
         
         if (u_numLights > 0){
             for (int i = 0; i < u_numLights; i++){
                 
                 float diffuse = max(0.0, dot(v_normal, v_lightDirection));
                 //float specular = max(0.0, dot(v_normal, v_halfVector));
                 float specular = max(0.0, dot(reflect(v_lightDirection, v_normal), v_halfVector));
                 
                 if (diffuse == 0.0) specular = 0.0;
                 else specular = pow(specular, Shininess) * Strength;
                 // Accumulate all the u_lights’ effects
                 scatteredLight += u_light.ambient * v_attenuation + u_light.color * diffuse * v_attenuation;
                 reflectedLight += u_light.color * specular * v_attenuation;
             }
             //lightColor = vec4(min(reflectedLight,vec3(1.0)), 1.0);
             return inputColor * vec4(min(scatteredLight+reflectedLight,vec3(1.0)), 1.0);
         }
         else {
             return inputColor;
         }
         
         );
    }
    
    module.fragFunctions = @[lightFunction];
    
    return module;
    
}

#pragma mark - POST PROCESS MODULES

+(NKShaderModule*) falseColorModule:(F1t)intensity darkColor:(NKByteColor*)darkColor lightColor:(NKByteColor*)lightColor {
    
    NKShaderModule* module = [[NKShaderModule alloc] init];

    module.name = @"FALSE COLOR";
    
    [module.uniforms addObject:nksu(NKS_PRECISION_LOW, NKS_TYPE_V4, NKS_FALSE_COLOR_DARK_COLOR)];
    [module.uniforms addObject:nksu(NKS_PRECISION_LOW, NKS_TYPE_V4, NKS_FALSE_COLOR_LIGHT_COLOR)];
    [module.uniforms addObject:nksu(NKS_PRECISION_LOW, NKS_TYPE_F1, NKS_FALSE_COLOR_INTENSITY)];
    
    NKShaderFunction *falseColor = [[NKShaderFunction alloc]init];
    
    falseColor.name = @"nkFalseColor";
    falseColor.inputType = NKS_TYPE_V4;
    falseColor.returnType = NKS_TYPE_V4;
    
    falseColor.constants = SHADER_STRING
    (
     const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
    );
    
    falseColor.function = SHADER_STRING
    (
     if (inputColor.a < .1) discard;
     float luminance = dot(inputColor.rgb, luminanceWeighting);
     return mix(inputColor,vec4( mix(u_falseColor_darkColor.rgb, u_falseColor_lightColor.rgb, luminance), inputColor.a),u_falseColor_intensity);
     );
    
    module.fragFunctions = @[falseColor];
    
    module.uniformUpdateBlock = newUniformUpdateBlock {
        [[module uniformNamed:NKS_FALSE_COLOR_DARK_COLOR] bindV4:darkColor.C4Color];
        [[module uniformNamed:NKS_FALSE_COLOR_LIGHT_COLOR] bindV4:lightColor.C4Color];
        [[module uniformNamed:NKS_FALSE_COLOR_INTENSITY] bindF1:intensity];
    };
    
    return module;
    
}

+(NKShaderModule*) boxBlurModule:(F1t)size intNumPasses:(F1t)passes {
    
    NKShaderModule* module = [[NKShaderModule alloc] init];
    
    module.name = @"NAME";
    
    [module.uniforms addObject:nksu(NKS_PRECISION_LOW, NKS_TYPE_V4, NKS_FALSE_COLOR_DARK_COLOR)];
    
    NKShaderFunction *function = [[NKShaderFunction alloc]init];
    
    function.name = @"functionName";
    function.inputType = NKS_TYPE_V4;
    function.returnType = NKS_TYPE_V4;
    
    function.constants = SHADER_STRING
    (
    );
    
    function.function = SHADER_STRING
    (
    );
    
    module.fragFunctions = @[function];
    
    module.uniformUpdateBlock = newUniformUpdateBlock {
    };
    
    return module;

}

+(NKShaderModule*) templateModule:(F1t)size {
    
    NKShaderModule* module = [[NKShaderModule alloc] init];
    
    module.name = @"NAME";
    
    [module.uniforms addObject:nksu(NKS_PRECISION_LOW, NKS_TYPE_V4, NKS_FALSE_COLOR_DARK_COLOR)];
    
    NKShaderFunction *function = [[NKShaderFunction alloc]init];
    
    function.name = @"functionName";
    function.inputType = NKS_TYPE_V4;
    function.returnType = NKS_TYPE_V4;
    
    function.constants = SHADER_STRING
    (
    );
    
    function.function = SHADER_STRING
    (
    );
    
    module.fragFunctions = @[function];
    
    module.uniformUpdateBlock = newUniformUpdateBlock {
    };
    
    return module;
    
}



-(NKShaderVariable*)uniformNamed:(NKS_ENUM)name {
    
    for (NKShaderVariable *v in _uniforms){
        if (v.name == name) return v;
    }
    
    return nil;
}

-(NKShaderVariable*)varyingNamed:(NKS_ENUM)name {
    
    for (NKShaderVariable *v in _varyings){
        if (v.name == name) return v;
    }
    
    return nil;
}

-(NSString*)description {
    return [self name];
}

@end
