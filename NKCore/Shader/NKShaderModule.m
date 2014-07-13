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

+(NKShaderModule*) vertexColorModule:(NKS_COLOR_MODE)colorMode batchSize:(int)batchSize {
    
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
    
    module.outputColor = [module.varyings copy];
    
    return module;
}

+(NKShaderModule*) fragmentColorModule:(NKS_COLOR_MODE)colorMode batchSize:(int)batchSize {
    
    NKShaderModule* module = [[NKShaderModule alloc] init];
    
    return module;
}

+(NKShaderModule*) lightModule:(bool)highQuality batchSize:(int)batchSize {
    
    NKShaderModule* module = [[NKShaderModule alloc] init];
    
    module.types = SHADER_STRING
    (
     struct LightProperties {
         vec3 position;
         vec3 ambient;
         vec3 color;
         
         vec3 halfVector;
         vec3 coneDirection;
         
         float spotCosCutoff;
         float spotExponent;
         float constantAttenuation;
         float linearAttenuation;
         float quadraticAttenuation;
         
         int isEnabled;
         int isLocal;
         int isSpot;
     };
     );
    
    if (highQuality) {
        module.name = @"HQ LIGHT PROGRAM";
        
        module.vertexMain = SHADER_STRING
        (
         v_eyeDirection = v_position.xyz;
         );
        
        module.fragmentMain = SHADER_STRING
        (
         // HQ LIGHT MODULE
         vec3 scatteredLight = vec3(0.0);
         vec3 reflectedLight = vec3(0.0);
         
         float Strength = 4.;
         float Shininess = 10.;
         
         if (u_numLights > 0){
             for (int i = 0; i < u_numLights; i++){
                 
                 vec3 halfVector;
                 vec3 lightDirection;
                 
                 float attenuation = 1.0;
                 if (u_light.isLocal == 1) {
                     lightDirection = u_light.position - v_position.xyz;
                     float lightDistance = length(lightDirection);
                     lightDirection = lightDirection / lightDistance; // (normalize) ? ;
                     attenuation = 1.0 / (u_light.constantAttenuation + (u_light.linearAttenuation * lightDistance) + (u_light.quadraticAttenuation * lightDistance * lightDistance));
                     if (u_light.isSpot == 1) {
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
             
             lightColor = vec4(min(scatteredLight + reflectedLight,vec3(1.0)), 1.0);
         }
         else {
             lightColor = vec4(1.0);
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
        
        module.fragmentMain = SHADER_STRING
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
             lightColor = vec4(min(scatteredLight+reflectedLight,vec3(1.0)), 1.0);
         }
         else {
             lightColor = vec4(1.0);
         }
         );
    }
    
    return module;
    
}


-(NSString*)description {
    return [self name];
}

@end
