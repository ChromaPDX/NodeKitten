//
//  NKAttributeBuffer.m
//  NKNikeField
//
//  Created by Leif Shackelford on 5/1/14.
//  Copyright (c) 2014 Chroma Developer. All rights reserved.
//

#import "NodeKitten.h"



@implementation NKVertexBuffer

{
    GLuint _vertexArray;
    GLuint _vertexBuffer;
}

- (id)initWithSize:(GLsizeiptr)size
  numberOfElements:(GLuint)numElements
              data:(const GLvoid *)data
             setup:(GeometrySetupBlock)geometrySetupBlock{
    
    self = [super init];
    if ( self )
    {
        _numberOfElements = numElements;
        [self loadVertexDataWithSize:size data:data setup:geometrySetupBlock];
        
    }
    return self;
}

-(V3t*)vertices {
    return vertices;
}

+(instancetype)axes {
    GLfloat gCubeVertexData[7*6] =
    {
        -1.0f, 0.0f, 0.0f,      .5f, 0.0f, 0.0f, 1.0f,
        1.0f, 0.0f, 0.0f,       1.0f, 0.5f, 0.5f, 1.0f,
        0.0f, -1.0f, 0.0f,      0.0f, .5f, 0.0f, 1.0f,
        0.0f, 1.0f, 0.0f,       0.5f, 1.0f, 0.5f, 1.0f,
        0.0f, 0.0f, -1.0f,      0.0f, 0.0f, .5f, 1.0f,
        0.0f, 0.0f, 1.0f,       0.5f, 0.5f, 1.0f, 1.0f
    };
    
    NKVertexBuffer *buf = [[NKVertexBuffer alloc] initWithSize:sizeof(gCubeVertexData) numberOfElements:sizeof(gCubeVertexData) / (sizeof(F1t)*7.) data:gCubeVertexData setup:newGeometrySetupBlock{
        glEnableVertexAttribArray(NKS_V4_POSITION);
        glVertexAttribPointer(NKS_V4_POSITION, 3, GL_FLOAT, GL_FALSE,
                              sizeof(F1t)*7, BUFFER_OFFSET(0));
        
        glEnableVertexAttribArray(NKS_V4_COLOR);
        glVertexAttribPointer(NKS_V4_COLOR, 3, GL_FLOAT, GL_FALSE,
                              sizeof(F1t)*7, BUFFER_OFFSET(12));
    }];
    
    
    return buf;
}

+(instancetype)defaultRect { // SPRITE
    
    GLfloat gCubeVertexData[8*6] =
    {
        0.5f, 0.5f, 0.0f,          1.0f, 0.0f, 0.0f,        1.0f, 1.0f,
        -0.5f, 0.5f, 0.0f,         1.0f, 0.0f, 0.0f,        0.0f, 1.0f,
        0.5f, -0.5f, 0.0f,         1.0f, 0.0f, 0.0f,        1.0f, 0.0f,
        -0.5f, 0.5f, 0.0f,         1.0f, 0.0f, 0.0f,        0.0f, 1.0f,
        -0.5f, -0.5f, 0.0f,        1.0f, 0.0f, 0.0f,        0.0f, 0.0f,
        0.5f, -0.5f, 0.0f,         1.0f, 0.0f, 0.0f,        1.0f, 0.0f,
    };
    
    NKVertexBuffer *buf = [[NKVertexBuffer alloc] initWithSize:sizeof(gCubeVertexData) numberOfElements:sizeof(gCubeVertexData) / (sizeof(F1t)*8.) data:gCubeVertexData setup:newGeometrySetupBlock{
        glEnableVertexAttribArray(NKS_V4_POSITION);
        glVertexAttribPointer(NKS_V4_POSITION, 3, GL_FLOAT, GL_FALSE,
                              sizeof(F1t)*8, BUFFER_OFFSET(0));
        
        glEnableVertexAttribArray(NKS_V3_NORMAL);
        glVertexAttribPointer(NKS_V3_NORMAL, 3, GL_FLOAT, GL_FALSE,
                              sizeof(F1t)*8, BUFFER_OFFSET(sizeof(F1t)*3));
        
        glEnableVertexAttribArray(NKS_V2_TEXCOORD);
        glVertexAttribPointer(NKS_V2_TEXCOORD, 2, GL_FLOAT, GL_FALSE,
                              sizeof(F1t)*8, BUFFER_OFFSET(sizeof(F1t)*6));
        
    }];
    
    return buf;
}

+(instancetype)sphereWithStacks:(GLint)stacks slices:(GLint)slices squash:(GLfloat)squash
{
    unsigned int colorIncrement = 0;
    unsigned int blue = 1.;
    unsigned int red = 1.;
    unsigned int green = 1.;
    
    colorIncrement = 1./stacks;
    
    float m_Scale = 1.;
    
    int numElements = (slices*2+2) * (stacks);
    
    // Vertices
    V3t *vertices = (V3t*)calloc(numElements,sizeof(V3t));
    F1t *vPtr = (F1t*)&vertices[0];
    
    // Normal pointers for lighting
    V3t *vertexNormals = (V3t*)calloc(numElements,sizeof(V3t));
    F1t *nPtr = (F1t*)&vertexNormals[0];
    
    V2t *textureCoords = (V2t*)calloc(numElements,sizeof(V2t));
    F1t *tPtr = (F1t*)&textureCoords[0];
    
    // Color
    C4t *vertexColors = (C4t*)calloc(numElements, sizeof(C4t));
    F1t *cPtr = (F1t*)&vertexColors[0];
    
    unsigned int phiIdx, thetaIdx;
    
    for(phiIdx = 0; phiIdx < stacks; phiIdx++)
    {
        //starts at -pi/2 goes to pi/2
        //the first circle
        float phi0 = M_PI * ((float)(phiIdx+0) * (1.0/(float)(stacks)) - 0.5);
        //second one
        float phi1 = M_PI * ((float)(phiIdx+1) * (1.0/(float)(stacks)) - 0.5);
        float cosPhi0 = cos(phi0);
        float sinPhi0 = sin(phi0);
        float cosPhi1 = cos(phi1);
        float sinPhi1 = sin(phi1);
        
        float cosTheta, sinTheta;
        //longitude
        for(thetaIdx = 0; thetaIdx < slices; thetaIdx++)
        {
            float theta = -2.0*M_PI * ((float)thetaIdx) * (1.0/(float)(slices - 1));
            cosTheta = cos(theta);
            sinTheta = sin(theta);
            
            //We're generating a vertical pair of points, such
            //as the first point of stack 0 and the first point of stack 1
            //above it. this is how triangle_strips work,
            //taking a set of 4 vertices and essentially drawing two triangles
            //at a time. The first is v0-v1-v2 and the next is v2-v1-v3, and so on.
            
            //get x-y-x of the first vertex of stack
            vPtr[0] = m_Scale*cosPhi0 * cosTheta;
            vPtr[1] = m_Scale*sinPhi0 * squash;
            vPtr[2] = m_Scale*(cosPhi0 * sinTheta);
            //the same but for the vertex immediately above the previous one.
            vPtr[3] = m_Scale*cosPhi1 * cosTheta;
            vPtr[4] = m_Scale*sinPhi1 * squash;
            vPtr[5] = m_Scale*(cosPhi1 * sinTheta);
            
            nPtr[0] = cosPhi0 * cosTheta;
            nPtr[1] = sinPhi0;
            nPtr[2] = cosPhi0 * sinTheta;
            nPtr[3] = cosPhi1 * cosTheta;
            nPtr[4] = sinPhi1;
            nPtr[5] = cosPhi1 * sinTheta;
            
            if(tPtr!=nil){
                GLfloat texX = (float)thetaIdx * (1.0f/(float)(slices-1));
                tPtr[0] = texX;
                tPtr[1] = (float)(phiIdx + 0) * (1.0f/(float)(stacks));
                tPtr[2] = texX;
                tPtr[3] = (float)(phiIdx + 1) * (1.0f/(float)(stacks));
            }
            
            cPtr[0] = red;
            cPtr[1] = green;
            cPtr[2] = blue;
            cPtr[4] = red;
            cPtr[5] = green;
            cPtr[6] = blue;
            cPtr[3] = cPtr[7] = 1.;
            
            cPtr += 2*4;
            vPtr += 2*3;
            nPtr += 2*3;
            
            if(tPtr != nil) tPtr += 2*2;
        }

        //Degenerate triangle to connect stacks and maintain winding order
        
        vPtr[0] = vPtr[3] = vPtr[-3];
        vPtr[1] = vPtr[4] = vPtr[-2];
        vPtr[2] = vPtr[5] = vPtr[-1];
        
        nPtr[0] = nPtr[3] = nPtr[-3];
        nPtr[1] = nPtr[4] = nPtr[-2];
        nPtr[2] = nPtr[5] = nPtr[-1];
        
        if(tPtr != nil){
            tPtr[0] = tPtr[2] = tPtr[-2];
            tPtr[1] = tPtr[3] = tPtr[-1];
        }
        
    }
    
    NKPrimitiveArray *elements = (NKPrimitiveArray*)calloc(numElements, sizeof(NKPrimitiveArray));
    
    for (int i = 0; i < numElements; i++) {
        memcpy(&elements[i].vertex, &vertices[i], sizeof(V3t));
        memcpy(&elements[i].normal, &vertexNormals[i], sizeof(V3t));
        memcpy(&elements[i].texCoord, &textureCoords[i], sizeof(V2t));
        memcpy(&elements[i].color, &vertexColors[i], sizeof(C4t));
    }
    
    free(vertices);
    free(vertexNormals);
    free(textureCoords);
    free(vertexColors);
    
    NSLog(@"V2t: %lu V3t: %lu V4t: %lu ", sizeof(V2t), sizeof(V3t), sizeof(V4t));
    NSLog(@"NKPrimitiveArraySize: %lu", sizeof(NKPrimitiveArray));
    
    NKVertexBuffer *buf = [[NKVertexBuffer alloc] initWithSize:sizeof(NKPrimitiveArray)*numElements numberOfElements:numElements data:elements setup:[NKVertexBuffer primitiveSetupBlock]];
                           
    buf.boundingBoxSize = V3MakeF(1.);
    
    
    //buf.drawMode = GL_LINES;
    
    free(elements);
    
    return buf;
    
}

+(instancetype)lodSphere:(int)levels {
    
    int detail = 3;
    
    int totalCount = 0;
    int currentOffset = 0;
    int numLevels = levels;
    
    int *offsets = malloc(sizeof(int) * levels);
    int *sizes = malloc(sizeof(int) * levels);
    
    for (int i = 0; i < numLevels; i++) {
        
        int stacks = (numLevels - i) * detail;
        int slices = (numLevels - i) * detail + 2;
        
        int numElements = (slices*2+2) * (stacks);
        
        offsets[i] = totalCount;
        sizes[i] = numElements;
        
        totalCount += numElements;
        
    }
    
    float squash = 1.;
    
   // NSLog(@"init vert %d total elements", totalCount);
    
    NKPrimitiveArray *elements = (NKPrimitiveArray*)calloc(totalCount, sizeof(NKPrimitiveArray));
    
    for (int i = 0; i < numLevels; i++) {
        
        int stacks = (numLevels - i) * detail;
        int slices = (numLevels - i) * detail + 2;
        int numElements = (slices*2+2) * (stacks);
        
        unsigned int colorIncrement = 0;
        unsigned int blue = 1.;
        unsigned int red = 1.;
        unsigned int green = 1.;
        
        colorIncrement = 1./stacks;
        
        float m_Scale = 1.;
        
        // Vertices
        V3t *vertices = (V3t*)calloc(numElements,sizeof(V3t));
        F1t *vPtr = (F1t*)&vertices[0];
        
        // Normal pointers for lighting
        V3t *vertexNormals = (V3t*)calloc(numElements,sizeof(V3t));
        F1t *nPtr = (F1t*)&vertexNormals[0];
        
        V2t *textureCoords = (V2t*)calloc(numElements,sizeof(V2t));
        F1t *tPtr = (F1t*)&textureCoords[0];
        
        // Color
        C4t *vertexColors = (C4t*)calloc(numElements, sizeof(C4t));
        F1t *cPtr = (F1t*)&vertexColors[0];
        
        unsigned int phiIdx, thetaIdx;
        
        for(phiIdx = 0; phiIdx < stacks; phiIdx++)
        {
            //starts at -pi/2 goes to pi/2
            //the first circle
            float phi0 = M_PI * ((float)(phiIdx+0) * (1.0/(float)(stacks)) - 0.5);
            //second one
            float phi1 = M_PI * ((float)(phiIdx+1) * (1.0/(float)(stacks)) - 0.5);
            float cosPhi0 = cos(phi0);
            float sinPhi0 = sin(phi0);
            float cosPhi1 = cos(phi1);
            float sinPhi1 = sin(phi1);
            
            float cosTheta, sinTheta;
            //longitude
            for(thetaIdx = 0; thetaIdx < slices; thetaIdx++)
            {
                float theta = -2.0*M_PI * ((float)thetaIdx) * (1.0/(float)(slices - 1));
                cosTheta = cos(theta);
                sinTheta = sin(theta);
                
                //We're generating a vertical pair of points, such
                //as the first point of stack 0 and the first point of stack 1
                //above it. this is how triangle_strips work,
                //taking a set of 4 vertices and essentially drawing two triangles
                //at a time. The first is v0-v1-v2 and the next is v2-v1-v3, and so on.
                
                //get x-y-x of the first vertex of stack
                vPtr[0] = m_Scale*cosPhi0 * cosTheta;
                vPtr[1] = m_Scale*sinPhi0 * squash;
                vPtr[2] = m_Scale*(cosPhi0 * sinTheta);
                //the same but for the vertex immediately above the previous one.
                vPtr[3] = m_Scale*cosPhi1 * cosTheta;
                vPtr[4] = m_Scale*sinPhi1 * squash;
                vPtr[5] = m_Scale*(cosPhi1 * sinTheta);
                
                nPtr[0] = cosPhi0 * cosTheta;
                nPtr[1] = sinPhi0;
                nPtr[2] = cosPhi0 * sinTheta;
                nPtr[3] = cosPhi1 * cosTheta;
                nPtr[4] = sinPhi1;
                nPtr[5] = cosPhi1 * sinTheta;
                
                if(tPtr!=nil){
                    GLfloat texX = (float)thetaIdx * (1.0f/(float)(slices-1));
                    tPtr[0] = texX;
                    tPtr[1] = (float)(phiIdx + 0) * (1.0f/(float)(stacks));
                    tPtr[2] = texX;
                    tPtr[3] = (float)(phiIdx + 1) * (1.0f/(float)(stacks));
                }
                
                cPtr[0] = red;
                cPtr[1] = green;
                cPtr[2] = blue;
                cPtr[3] = cPtr[7] = 1.;
                cPtr[4] = red;
                cPtr[5] = green;
                cPtr[6] = blue;
                
                
                cPtr += 2*4;
                vPtr += 2*3;
                nPtr += 2*3;
                
                if(tPtr != nil) tPtr += 2*2;
            }
            //        blue+=colorIncrement;
            //        red-=colorIncrement;
            
            //Degenerate triangle to connect stacks and maintain winding order
            
            vPtr[0] = vPtr[3] = vPtr[-3];
            vPtr[1] = vPtr[4] = vPtr[-2];
            vPtr[2] = vPtr[5] = vPtr[-1];
            
            nPtr[0] = nPtr[3] = nPtr[-3];
            nPtr[1] = nPtr[4] = nPtr[-2];
            nPtr[2] = nPtr[5] = nPtr[-1];
            
            if(tPtr != nil){
                tPtr[0] = tPtr[2] = tPtr[-2];
                tPtr[1] = tPtr[3] = tPtr[-1];
            }
            
        }
        
       // NSLog(@"copy %d elements", numElements);
        
        for (int i = currentOffset; i < currentOffset + numElements; i++) {
            memcpy(&elements[i].vertex, &vertices[(i-currentOffset)], sizeof(V3t));
            memcpy(&elements[i].normal, &vertexNormals[(i-currentOffset)], sizeof(V3t));
            memcpy(&elements[i].texCoord, &textureCoords[(i-currentOffset)], sizeof(V2t));
            memcpy(&elements[i].color, &vertexColors[(i-currentOffset)], sizeof(C4t));
        }
        
        free(vertices);
        free(vertexNormals);
        free(textureCoords);
        free(vertexColors);
        
        // NSLog(@"add to NKPrimitiveArraySize: %lu", numElements * sizeof(NKPrimitiveArray));
        
        currentOffset += numElements;
    }
    
    //NSLog(@"V2t: %lu V3t: %lu V4t: %lu ", sizeof(V2t), sizeof(V3t), sizeof(V4t));
   
    
    NKVertexBuffer *buf = [[NKVertexBuffer alloc] initWithSize:sizeof(NKPrimitiveArray)*totalCount numberOfElements:numLevels data:elements setup:[NKVertexBuffer primitiveSetupBlock]];
    
    buf.elementOffset = offsets;
    buf.elementSize = sizes;
    
    
    free(elements);
    
    return buf;
    
}

+(instancetype)pointSprite {
    GLfloat point[3] = {0,0,0};
    NKVertexBuffer *buf = [[NKVertexBuffer alloc] initWithSize:sizeof(point) numberOfElements:1 data:point setup:newGeometrySetupBlock{
        glEnableVertexAttribArray(NKS_V4_POSITION);
        glVertexAttribPointer(NKS_V4_POSITION, 3, GL_FLOAT, GL_FALSE,
                              24, BUFFER_OFFSET(0));
    }];
    
    return buf;
}

+(instancetype)defaultCube {
    GLfloat gCubeVertexData[288] =
    {
        // Data layout for each line below is:
        // positionX, positionY, positionZ,     normalX, normalY, normalZ,
        1.f, -1.f, -1.f,        1.0f, 0.0f, 0.0f,   0.0f, 0.0f,
        1.f, 1.f, -1.f,         1.0f, 0.0f, 0.0f,   1.0f, 0.0f,
        1.f, -1.f, 1.f,         1.0f, 0.0f, 0.0f,   0.0f, 1.0f,
        1.f, -1.f, 1.f,         1.0f, 0.0f, 0.0f,   0.0f, 1.0f,
        1.f, 1.f, -1.f,         1.0f, 0.0f, 0.0f,   1.0f, 0.0f,
        1.f, 1.f, 1.f,          1.0f, 0.0f, 0.0f,   1.0f, 1.0f,
        
        1.f, 1.f, -1.f,         0.0f, 1.0f, 0.0f,   1.0f, 0.0f,
        -1.f, 1.f, -1.f,        0.0f, 1.0f, 0.0f,   0.0f, 0.0f,
        1.f, 1.f, 1.f,          0.0f, 1.0f, 0.0f,   1.0f, 1.0f,
        1.f, 1.f, 1.f,          0.0f, 1.0f, 0.0f,   1.0f, 1.0f,
        -1.f, 1.f, -1.f,        0.0f, 1.0f, 0.0f,   0.0f, 0.0f,
        -1.f, 1.f, 1.f,         0.0f, 1.0f, 0.0f,   0.0f, 1.0f,
        
        -1.f, 1.f, -1.f,        -1.0f, 0.0f, 0.0f,  1.0f, 0.0f,
        -1.f, -1.f, -1.f,       -1.0f, 0.0f, 0.0f,  0.0f, 0.0f,
        -1.f, 1.f, 1.f,         -1.0f, 0.0f, 0.0f,  1.0f, 1.0f,
        -1.f, 1.f, 1.f,         -1.0f, 0.0f, 0.0f,  1.0f, 1.0f,
        -1.f, -1.f, -1.f,       -1.0f, 0.0f, 0.0f,  0.0f, 0.0f,
        -1.f, -1.f, 1.f,        -1.0f, 0.0f, 0.0f,  0.0f, 1.0f,
        
        -1.f, -1.f, -1.f,       0.0f, -1.0f, 0.0f,  0.0f, 0.0f,
        1.f, -1.f, -1.f,        0.0f, -1.0f, 0.0f,  1.0f, 0.0f,
        -1.f, -1.f, 1.f,        0.0f, -1.0f, 0.0f,  0.0f, 1.0f,
        -1.f, -1.f, 1.f,        0.0f, -1.0f, 0.0f,  0.0f, 1.0f,
        1.f, -1.f, -1.f,        0.0f, -1.0f, 0.0f,  1.0f, 0.0f,
        1.f, -1.f, 1.f,         0.0f, -1.0f, 0.0f,  1.0f, 1.0f,
        
        1.f, 1.f, 1.f,          0.0f, 0.0f, 1.0f,   1.0f, 1.0f,
        -1.f, 1.f, 1.f,         0.0f, 0.0f, 1.0f,   0.0f, 1.0f,
        1.f, -1.f, 1.f,         0.0f, 0.0f, 1.0f,   1.0f, 0.0f,
        1.f, -1.f, 1.f,         0.0f, 0.0f, 1.0f,   1.0f, 0.0f,
        -1.f, 1.f, 1.f,         0.0f, 0.0f, 1.0f,   0.0f, 1.0f,
        -1.f, -1.f, 1.f,        0.0f, 0.0f, 1.0f,   0.0f, 0.0f,
        
        1.f, -1.f, -1.f,        0.0f, 0.0f, -1.0f,  1.0f, 0.0f,
        -1.f, -1.f, -1.f,       0.0f, 0.0f, -1.0f,  0.0f, 0.0f,
        1.f, 1.f, -1.f,         0.0f, 0.0f, -1.0f,  1.0f, 1.0f,
        1.f, 1.f, -1.f,         0.0f, 0.0f, -1.0f,  1.0f, 1.0f,
        -1.f, -1.f, -1.f,       0.0f, 0.0f, -1.0f,  0.0f, 0.0f,
        -1.f, 1.f, -1.f,        0.0f, 0.0f, -1.0f,  0.0f, 1.0f
    };
    
    NKVertexBuffer *buf = [[NKVertexBuffer alloc] initWithSize:sizeof(gCubeVertexData) numberOfElements:36 data:gCubeVertexData setup:newGeometrySetupBlock{
        glEnableVertexAttribArray(NKS_V4_POSITION);
        glVertexAttribPointer(NKS_V4_POSITION, 3, GL_FLOAT, GL_FALSE,
                              32, BUFFER_OFFSET(0));
        
        glEnableVertexAttribArray(NKS_V3_NORMAL);
        glVertexAttribPointer(NKS_V3_NORMAL, 3, GL_FLOAT, GL_FALSE,
                              32, BUFFER_OFFSET(12));
        
        glEnableVertexAttribArray(NKS_V2_TEXCOORD);
        glVertexAttribPointer(NKS_V2_TEXCOORD, 2, GL_FLOAT, GL_FALSE,
                              32, BUFFER_OFFSET(sizeof(F1t)*6));
    }];
    
    
    return buf;
}

+(instancetype)cubeWithWidthSections:(int)resX height:(int)resY depth:(int) resZ {
   
    int numElements = (resX * 2) * (resY* 2) * (resZ * 2) + 3;
 
    V3t *vertices = (V3t*)calloc(numElements,sizeof(V3t));
    F1t *vPtr = (F1t*)vertices;
    
    V3t *normals = (V3t*)calloc(numElements,sizeof(V3t));
    F1t *nPtr = (F1t*)normals;
    
    V2t *texcoords = (V2t*)calloc(numElements,sizeof(V2t));

    C4t *colors = (C4t*)calloc(numElements, sizeof(C4t));
    
    V3t vert;
    V2t texcoord;
    V3t normal;
    C4t color;
    int vertOffset = 0;
    
    int elementCounter = 0;
    
    // TRIANGLES //
    float rx = resX;
    float ry = resY;
    float rz = resZ;
    
    // Front Face //
    normal = V3Make(0, 0, 1);
    // add the vertexes //
    for(int iy = 0; iy < resY; iy++) {
        //for (int s = 0; s < 2; s++) {
        for(int ix = 0; ix < resX*2; ix++) {
            
            switch (iy % 2) {
                case 0:
                    vert.x = (ix / 2) / (resX - 1) * 2 - 1.;
                    vert.y = (iy / ry + (ix % 2) / ry) * 2 - 1.;
                    vert.z = 1 * 2 - 1.;
                    break;
                    
                case 1:
                    vert.x = (((resX-1) - ix) / 2) / (resX - 1) * 2 - 1.;
                    vert.y = (iy / ry + (ix % 2) / ry) * 2 - 1.;
                    vert.z = 1 * 2 - 1;
                    break;
                    
                default:
                    break;
            }
            
            texcoord.x = vert.x;
            texcoord.y = vert.y;
            
            *(vertices + elementCounter) = vert;
            *(texcoords + elementCounter) = texcoord;
            *(normals + elementCounter) = normal;
            
            vPtr+=3;
            nPtr+=3;
            elementCounter++;
        }
        
        //Degenerate triangle to connect stacks and maintain winding order
        
        vPtr[0] = vPtr[-1];
        vPtr[1] = vPtr[-1];
        vPtr[2] = vPtr[-1];
        
        nPtr[0] = nPtr[-1];
        nPtr[1] = nPtr[-1];
        nPtr[2] = nPtr[-1];
        
        vPtr+=3;
        nPtr+=3;
        
        elementCounter++;
    }
   
    numElements = elementCounter;
    
    NSLog(@"cube with %d vertices", numElements);
    NKPrimitiveArray *elements = (NKPrimitiveArray*)calloc(numElements, sizeof(NKPrimitiveArray));
    
    for (int i = 0; i < numElements; i++) {
        memcpy(&elements[i].vertex, &vertices[i], sizeof(V3t));
        memcpy(&elements[i].normal, &normals[i], sizeof(V3t));
        memcpy(&elements[i].texCoord, &texcoords[i], sizeof(V2t));
        memcpy(&elements[i].color, &colors[i], sizeof(C4t));
    }
    
    free(vertices);
    free(normals);
    free(texcoords);
    free(colors);
    
//    NSLog(@"V2t: %lu V3t: %lu V4t: %lu ", sizeof(V2t), sizeof(V3t), sizeof(V4t));
//    NSLog(@"NKPrimitiveArraySize: %lu", sizeof(NKPrimitiveArray));
    
    NKVertexBuffer *buf = [[NKVertexBuffer alloc] initWithSize:sizeof(NKPrimitiveArray)*numElements numberOfElements:numElements data:elements setup:[NKVertexBuffer primitiveSetupBlock]];
    
    //buf.drawMode = GL_LINES;
    
    free(elements);
    
    return buf;
    
}

+(GeometrySetupBlock)primitiveSetupBlock {
    return newGeometrySetupBlock {
            glEnableVertexAttribArray(NKS_V4_POSITION);
            glVertexAttribPointer(NKS_V4_POSITION, 3, GL_FLOAT, GL_FALSE,
                                  sizeof(NKPrimitiveArray), BUFFER_OFFSET(0));
            
            glEnableVertexAttribArray(NKS_V3_NORMAL);
            glVertexAttribPointer(NKS_V3_NORMAL, 3, GL_FLOAT, GL_FALSE,
                                  sizeof(NKPrimitiveArray), BUFFER_OFFSET(sizeof(V3t)));
            
            glEnableVertexAttribArray(NKS_V2_TEXCOORD);
            glVertexAttribPointer(NKS_V2_TEXCOORD, 2, GL_FLOAT, GL_FALSE,
                                  sizeof(NKPrimitiveArray), BUFFER_OFFSET(sizeof(V3t)*2));
            
            glEnableVertexAttribArray(NKS_V4_COLOR);
            glVertexAttribPointer(NKS_V4_COLOR, 4, GL_FLOAT, GL_FALSE,
                                  sizeof(NKPrimitiveArray), BUFFER_OFFSET(sizeof(V3t)*2+sizeof(V2t)));
        };
}

+(GeometrySetupBlock)riggedMeshSetupBlock {
    return newGeometrySetupBlock {
        glEnableVertexAttribArray(NKS_V4_POSITION);
        glVertexAttribPointer(NKS_V4_POSITION, 3, GL_FLOAT, GL_FALSE,
                              sizeof(NKRiggedStuct), BUFFER_OFFSET(0));
        
        glEnableVertexAttribArray(NKS_V3_NORMAL);
        glVertexAttribPointer(NKS_V3_NORMAL, 3, GL_FLOAT, GL_FALSE,
                              sizeof(NKRiggedStuct), BUFFER_OFFSET(sizeof(V3t)));
        
        glEnableVertexAttribArray(NKS_V2_TEXCOORD);
        glVertexAttribPointer(NKS_V2_TEXCOORD, 3, GL_FLOAT, GL_FALSE,
                              sizeof(NKRiggedStuct), BUFFER_OFFSET(sizeof(V3t)*2));
        
        glEnableVertexAttribArray(NKS_V3_TANGENT);
        glVertexAttribPointer(NKS_V3_TANGENT, 3, GL_FLOAT, GL_FALSE,
                              sizeof(NKRiggedStuct), BUFFER_OFFSET(sizeof(V3t)*3));
        
        glEnableVertexAttribArray(NKS_V3_BINORMAL);
        glVertexAttribPointer(NKS_V3_BINORMAL, 3, GL_FLOAT, GL_FALSE,
                              sizeof(NKRiggedStuct), BUFFER_OFFSET(sizeof(V3t)*4));
        
        glEnableVertexAttribArray(NKS_F1_BONE_WEIGHT);
        glVertexAttribPointer(NKS_F1_BONE_WEIGHT, 1, GL_FLOAT, GL_FALSE,
                              sizeof(NKRiggedStuct), BUFFER_OFFSET(sizeof(V3t)*5));
    };
}

-(void)loadVertexDataWithSize:(GLsizeiptr)size
                         data:(const GLvoid *)data
                        setup:(void(^)())geometrySetupBlock {
    
    NSLog(@"load vertex buffer with: %ld vertices", _numVertices);
    
    //glEnable(GL_DEPTH_TEST);
#if NK_USE_GLES
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
#else
#ifdef NK_USE_ARB_EXT
    glGenVertexArraysAPPLE(1, &_vertexArray);
    glBindVertexArrayAPPLE(_vertexArray);
#else
    glGenVertexArrays(1, &_vertexArray);
    glBindVertexArray(_vertexArray);
#endif
#endif
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    
    glBufferData(GL_ARRAY_BUFFER,
                 size,
                 data,
                 GL_STATIC_DRAW);
    
    geometrySetupBlock();
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
#if NK_USE_GLES
    glBindVertexArrayOES(0);
#else
#ifdef NK_USE_ARB_EXT
    glBindVertexArrayAPPLE(0);
#else
    glBindVertexArray(0);
#endif
#endif
    
}

-(instancetype)initWithVertexData:(const GLvoid *)data numberOfElements:(GLuint)numElements ofSize:(GLsizeiptr)size {
    
    return [self initWithSize:size numberOfElements:numElements data:data setup:newGeometrySetupBlock{
        glEnableVertexAttribArray(NKS_V4_POSITION);
        glVertexAttribPointer(NKS_V4_POSITION, 3, GL_FLOAT, GL_FALSE,
                              sizeof(V3t), BUFFER_OFFSET(0));
    }];
    
}

- (void)dealloc
{
    
    glDeleteBuffers(1, &_vertexBuffer);
#if NK_USE_GLES
    glDeleteVertexArraysOES(1, &_vertexArray);
#else
    #ifdef NK_USE_ARB_EXT
    glDeleteVertexArraysAPPLE(1, &_vertexArray);
#else
    glDeleteVertexArrays(1, &_vertexArray);
#endif
#endif
    
}

+(V6t)boundingSizeForVertexSet:(NSArray*)set {
    
    float minx = 1000000., maxx = -1000000.;
    float miny = 1000000., maxy = -1000000.;
    float minz = 1000000., maxz = -1000000.;
    
    for (NKVertexBuffer *buf in set) {
        
        V3t* vertices = buf.vertices;
        
        for (int i = 0; i < buf.numVertices; i++){ // FIND LARGEST VALUE
            
            if (vertices[i].x < minx)
                minx = vertices[i].x;
            if (vertices[i].x > maxx)
                maxx = vertices[i].x;
            
            if (vertices[i].y < miny)
                miny = vertices[i].y;
            if (vertices[i].y > maxy)
                maxy = vertices[i].y;
            
            if (vertices[i].z < minz)
                minz = vertices[i].z;
            if (vertices[i].z > maxz)
                maxz = vertices[i].z;
            
        };
    }
    
    V6t box;
    
    box.x = P2Make(minx, maxx);
    box.y = P2Make(miny, maxy);
    box.z = P2Make(minz, maxz);
    
    return box;
    
}

-(V3t)centerOfBoundingSize:(V6t)box {
    return V3Make((box.x.min+box.x.max)*.5, (box.y.min+box.y.max)*.5, (box.z.min+box.z.max)*.5);
}

-(V3t)sizeOfBoundingSize:(V6t)box {
    float width = fabsf(box.x.max - box.x.min);
    float height = fabsf(box.y.max - box.y.min);
    float depth = fabsf(box.z.max - box.z.min);

    return V3Make(width, height, depth);

}

-(void)normalizeAndCenter {
    V6t mySize = [NKVertexBuffer boundingSizeForVertexSet:@[self]];
    
    V3t center = [self centerOfBoundingSize:mySize];
    
    V3t modelSize = [self sizeOfBoundingSize:mySize];
    V3t modelInverse = V3Divide(V3MakeF(2.), modelSize);
    
    V3t offsetNormalized = V3Divide(V3MultiplyScalar(center, 2.), modelSize);
    
    //V3t center = V3Divide(V3MultiplyScalar(center), modelSize);
    _center = center;
    
    NKLogV3(@"my center :", _center);
    
    for (int p = 0; p < self.numVertices; p++){
            vertices[p] = V3Subtract(V3Multiply(vertices[p], modelInverse),offsetNormalized);
            //vertices[p] = V3Multiply(vertices[p], modelInverse);
            //NKLogV3(@"normalized vertex", vertices[p]);
    }
    
}

-(V3t)normalizeForGroupWithSize:(F1t)unitSize groupBoundingBox:(V6t)box center:(bool)center {

    //NKLogV3(@"group offset Normalized", offsetNormalized);
    // store for later ratio
    V6t myBoundingSize = [NKVertexBuffer boundingSizeForVertexSet:@[self]];
    
    V3t mySize = [self sizeOfBoundingSize:myBoundingSize];
    
    [self normalizeAndCenter];
    
    V3t groupSize = [self sizeOfBoundingSize:box];
    
    V3t groupCenter = [self centerOfBoundingSize:box];

      NKLogV3(@"groupCenter: ", groupCenter);
    
    V3t groupAspect = V3UnitRetainAspect(groupSize);
    
    V3t aspectExpand = V3MultiplyScalar(V3Multiply(groupAspect, V3Divide(mySize, groupSize)), unitSize);
    

    V3t myRelative;
    NKLogV3(@"my relative center", myRelative = V3Subtract(_center, groupCenter ));
    
    _center = V3MultiplyScalar(V3DivideScalar(myRelative, V3Largest(groupSize)), unitSize*2.);

    NKLogV3(@"my center normalized:", _center);
    
//    _center = V3MakeF(0);
//    
//    _center = V3Subtract(V3Divide(V3MultiplyScalar(_center, unitSize), groupSize), groupCenterNormalized);
//
//    _center = V3Divide(_center, aspectExpand);
    
    //return V3Make(2., 2., 2.);
        NKLogV3(@"my final size:", aspectExpand);
    return aspectExpand;
}


-(void)bufferData {
    
    stride = 0;
    
    if (vertices){
        verticesOffset = stride;
        stride+=3;
    }
    if (normals){
        normalsOffset = stride;
        stride+=3;
    }
    if (texCoords){
        texCoordsOffset = stride;
        stride+=3;
    }
    if (colors){
        colorsOffset = stride;
        stride+=4;
    }
    if (tangents){
        tangentsOffset = stride;
        stride+=3;
    }
    if (biNormals){
        biNormalsOffset = stride;
        stride+=3;
    }
    if (boneWeights){
        boneWeightsOffset = stride;
        stride+=1;
    }
    
    interlacedData = (F1t*)calloc(sizeof(F1t)*stride*self.numVertices, sizeof(F1t));
    
    for (int i = 0; i < self.numVertices; i++){
        if (vertices)
            memcpy(interlacedData+(i*stride),vertices+i, sizeof(V3t));
        if (normals)
            memcpy(interlacedData+(i*stride)+normalsOffset, vertices+i, sizeof(V3t));
        if (texCoords)
            memcpy(interlacedData+(i*stride)+texCoordsOffset, texCoords+i, sizeof(V3t));
        if (colors)
            memcpy(interlacedData+(i*stride)+colorsOffset, colors+i, sizeof(C4t));
        if (tangents)
            memcpy(interlacedData+(i*stride)+tangentsOffset, tangents+i, sizeof(V3t));
        if (biNormals)
            memcpy(interlacedData+(i*stride)+biNormalsOffset, biNormals+i, sizeof(V3t));
        if (boneWeights)
            memcpy(interlacedData+(i*stride)+boneWeightsOffset, boneWeights+i, sizeof(V3t));
    }
    
    [self loadVertexDataWithSize:self.numVertices*sizeof(F1t)*stride data:interlacedData setup: newGeometrySetupBlock {
        
        //NSLog(@"stride %d floats, %d bytes", stride, stride*sizeof(F1t));
        
        if (vertices){
            glEnableVertexAttribArray(NKS_V4_POSITION);
            glVertexAttribPointer(NKS_V4_POSITION, 3, GL_FLOAT, GL_FALSE,
                                  sizeof(F1t)*stride, BUFFER_OFFSET(0));
        }
        if (normals) {
            glEnableVertexAttribArray(NKS_V3_NORMAL);
            glVertexAttribPointer(NKS_V3_NORMAL, 3, GL_FLOAT, GL_FALSE,
                                  sizeof(F1t)*stride, BUFFER_OFFSET(sizeof(F1t)*normalsOffset));
        }
        
        if (texCoords){
            glEnableVertexAttribArray(NKS_V2_TEXCOORD);
            glVertexAttribPointer(NKS_V2_TEXCOORD, 3, GL_FLOAT, GL_FALSE,
                                  sizeof(F1t)*stride, BUFFER_OFFSET(sizeof(F1t)*texCoordsOffset));
        }
        
        if (colors) {
            glEnableVertexAttribArray(NKS_V4_COLOR);
            glVertexAttribPointer(NKS_V4_COLOR, 4, GL_FLOAT, GL_FALSE,
                                  sizeof(F1t)*stride, BUFFER_OFFSET(sizeof(F1t)*colorsOffset));
        }
        
        if (tangents) {
            glEnableVertexAttribArray(NKS_V3_TANGENT);
            glVertexAttribPointer(NKS_V3_TANGENT, 3, GL_FLOAT, GL_FALSE,
                                  sizeof(F1t)*stride, BUFFER_OFFSET(sizeof(F1t)*tangentsOffset));
        }
        
        if (biNormals) {
            glEnableVertexAttribArray(NKS_V3_BINORMAL);
            glVertexAttribPointer(NKS_V3_BINORMAL, 3, GL_FLOAT, GL_FALSE,
                                  sizeof(F1t)*stride, BUFFER_OFFSET(sizeof(F1t)*biNormalsOffset));
        }
        
        if (boneWeights) {
            glEnableVertexAttribArray(NKS_F1_BONE_WEIGHT);
            glVertexAttribPointer(NKS_F1_BONE_WEIGHT, 1, GL_FLOAT, GL_FALSE,
                                  sizeof(F1t)*stride, BUFFER_OFFSET(sizeof(F1t)*boneWeightsOffset));
        }
    }];
    
    if (interlacedData) {
        free(interlacedData);
    }
    
}

- (void)bind
{
#if NK_USE_GLES
    glBindVertexArrayOES(_vertexArray);
#else
    #ifdef NK_USE_ARB_EXT
    glBindVertexArrayAPPLE(_vertexArray);
#else
    glBindVertexArray(_vertexArray);
#endif
#endif
    
}

- (void)bind:(void(^)())drawingBlock
{
    [self bind];
    drawingBlock();
    [self unbind];
}

- (void)unbind
{
#if NK_USE_GLES
    glBindVertexArrayOES(0);
#else
#ifdef NK_USE_ARB_EXT
    glBindVertexArrayAPPLE(0);
#else
    glBindVertexArray(0);
#endif
#endif
}

@end


@implementation NKIndexBuffer
{
    GLuint _elementBuffer;
}

- (id)initWithSize:(GLsizeiptr)size
              data:(const GLvoid *)data
{
    self = [super init];
    if ( self )
    {
        glGenBuffers(1, &_elementBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _elementBuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                     size,
                     data,
                     GL_STATIC_DRAW);
    }
    return self;
}

- (void)dealloc
{
    glDeleteBuffers(1, &_elementBuffer);
}

- (void)bind
{
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _elementBuffer);
}

//- (void)bind:(void(^)())drawingBlock
//{
//    [self bind];
//    drawingBlock();
//    [self unbind];
//}

- (void)unbind
{
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _elementBuffer);
}


@end

