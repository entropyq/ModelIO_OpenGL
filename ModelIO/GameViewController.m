//
//  GameViewController.m
//  ModelIO
//
//  Created by Matt Loflin on 11/28/16.
//  Copyright © 2016 Pair, Inc. All rights reserved.
//

#import "GameViewController.h"
#import <OpenGLES/ES2/glext.h>

#import <GLKit/GLKit.h>
#import <ModelIO/ModelIO.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

GLfloat gCubeVertexData[216] = 
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.5f, -0.5f, -0.5f,        1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,          1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    
    0.5f, 0.5f, -0.5f,         0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 1.0f, 0.0f,
    
    -0.5f, 0.5f, -0.5f,        -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        -1.0f, 0.0f, 0.0f,
    
    -0.5f, -0.5f, -0.5f,       0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         0.0f, -1.0f, 0.0f,
    
    0.5f, 0.5f, 0.5f,          0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, 0.0f, 1.0f,
    
    0.5f, -0.5f, -0.5f,        0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 0.0f, -1.0f
};

@interface GameViewController () {
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
//    GLuint _vertexArray;
//    GLuint _vertexBuffer;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

@property (nonatomic, strong) MDLAsset *mdlAsset;
@property (nonatomic, strong) NSArray<MDLMesh*> *mdlMeshes;
@property (nonatomic, strong) NSArray<GLKMesh*> *glkMeshes;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    [self setupGL];
    [self loadMDLAsset];
}

- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    
    glEnable(GL_DEPTH_TEST);
    
//    glGenVertexArraysOES(1, &_vertexArray);
//    glBindVertexArrayOES(_vertexArray);

//    glGenBuffers(1, &_vertexBuffer);
//    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);

//    glEnableVertexAttribArray(GLKVertexAttribPosition);
//    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
//    glEnableVertexAttribArray(GLKVertexAttribNormal);
//    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));

//    glBindVertexArrayOES(0);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
//    glDeleteBuffers(1, &_vertexBuffer);
//    glDeleteVertexArraysOES(1, &_vertexArray);

    self.effect = nil;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
    
    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    // Compute the model view matrix for the object rendered with ES2
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    _rotation += self.timeSinceLastUpdate * 0.5f;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
//    glBindVertexArrayOES(_vertexArray);

    // Render the object with GLKit
    [self.effect prepareToDraw];
    
//    glDrawArrays(GL_TRIANGLES, 0, 36);

    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    
//    glDrawArrays(GL_TRIANGLES, 0, 36);




#warning Uncomment the line below and the app runs fine on an iPhone 5s running 9.3.5 (13G36), iPhone 4s running 9.2 (13C75), and the simulator using iOS 9. However, it continues to crash on the simulator and devices running iOS 10.
    //MDLAxisAlignedBoundingBox boundingBox = self.mdlAsset.boundingBox;



    for (GLKMesh *glkMesh in self.glkMeshes) {
        MDLVertexDescriptor *vertexDescriptor = glkMesh.vertexDescriptor;

        // TODO: Remove this check if we determine that these two are always equal.
        if (vertexDescriptor.attributes.count != vertexDescriptor.layouts.count) {
            NSLog(@"attribute and layout counts do not match: %lu vs %lu", (unsigned long)vertexDescriptor.attributes.count, (unsigned long)vertexDescriptor.layouts.count);
        }

        for (NSUInteger i = 0; i < glkMesh.vertexDescriptor.layouts.count; ++i) {
            MDLVertexAttribute *attribute = glkMesh.vertexDescriptor.attributes[i];
            MDLVertexBufferLayout *layout = glkMesh.vertexDescriptor.layouts[i];

            GLuint attributeIndex;

            if ([attribute.name isEqualToString:MDLVertexAttributePosition]) {
                attributeIndex = glGetAttribLocation(_program, "position");
            } else if ([attribute.name isEqualToString:MDLVertexAttributeNormal]) {
                attributeIndex = glGetAttribLocation(_program, "normal");
            } else {
                continue;
            }

            MDLVertexFormat vertexFormat = attribute.format;
            GLKVertexAttributeParameters vertexAttributeParameters = GLKVertexAttributeParametersFromModelIO(vertexFormat);
            glVertexAttribPointer(attributeIndex, //GLuint(attribute.bufferIndex),
                                  vertexAttributeParameters.size,
                                  vertexAttributeParameters.type,
                                  vertexAttributeParameters.normalized,
                                  (GLsizei)(layout.stride),
                                  (GLvoid*) attribute.offset);
            glEnableVertexAttribArray(attributeIndex); //GLuint(attribute.bufferIndex)
        }

        for (NSUInteger j = 0; j < glkMesh.submeshes.count; ++j) {
            GLKSubmesh *glkSubmesh = glkMesh.submeshes[j];

            switch (glkSubmesh.elementBuffer.type) {
                case MDLMeshBufferTypeVertex:
                    glBindBuffer(GL_ARRAY_BUFFER, glkSubmesh.elementBuffer.glBufferName);
                    break;
                case MDLMeshBufferTypeIndex:
                    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, glkSubmesh.elementBuffer.glBufferName);
                    break;
            }

            glDrawElements(glkSubmesh.mode, glkSubmesh.elementCount, glkSubmesh.type, 0);
        }

        for (MDLVertexAttribute *attribute in glkMesh.vertexDescriptor.attributes) {
            GLuint attributeIndex;

            if ([attribute.name isEqualToString:MDLVertexAttributePosition]) {
                attributeIndex = glGetAttribLocation(_program, "position");
            } else if ([attribute.name isEqualToString:MDLVertexAttributeNormal]) {
                attributeIndex = glGetAttribLocation(_program, "normal");
            } else {
                continue;
            }

            glDisableVertexAttribArray(attributeIndex);
        }
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
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
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}



- (void)loadMDLAsset
{
    NSURL *modelURL = [NSURL fileURLWithPath:[NSBundle.mainBundle pathForResource:@"capsule" ofType:@"obj"]];
    self.mdlAsset = [[MDLAsset alloc] initWithURL:modelURL
                                 vertexDescriptor:[self assetVertexDescriptor]
                                  bufferAllocator:[self assetMeshBufferAllocator]];

    //self.mdlMeshes = (NSArray<MDLMesh*> *)[asset childObjectsOfClass:[MDLMesh class]];
    NSArray<MDLMesh*> *mdlMeshes;
    NSError *newMeshesError;
    self.glkMeshes = [GLKMesh newMeshesFromAsset:self.mdlAsset sourceMeshes:&mdlMeshes error:&newMeshesError];
    if (newMeshesError) {
        NSLog(@"Error generating array of meshes: %@", newMeshesError.localizedDescription);
    }
    self.mdlMeshes = mdlMeshes;
}

- (nonnull GLKMeshBufferAllocator*)assetMeshBufferAllocator
{
    return [GLKMeshBufferAllocator new];
}

- (nonnull MDLVertexDescriptor*)assetVertexDescriptor
{
    MDLVertexDescriptor *vertexDescriptor = [MDLVertexDescriptor new];

    MDLVertexAttribute *positionAttribute = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributePosition //@"position"
                                                                              format:MDLVertexFormatFloat3
                                                                              offset:0
                                                                         bufferIndex:0];
    MDLVertexAttribute *normalAttribute = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributeNormal //@"normal"
                                                                            format:MDLVertexFormatFloat3
                                                                            offset:12
                                                                       bufferIndex:0];

    for (MDLVertexBufferLayout *layout in vertexDescriptor.layouts) {
        layout.stride = 24;
    }

    [vertexDescriptor addOrReplaceAttribute:positionAttribute];
    [vertexDescriptor addOrReplaceAttribute:normalAttribute];

    return vertexDescriptor;
}

@end
