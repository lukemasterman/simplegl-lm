//
//  OpenGLView.m
//  HelloOpenGL
//
//  Created by Luke Masterman on 10/10/2013.
//  Copyright (c) 2013 Luke Masterman. All rights reserved.
//

#import "OpenGLView.h"
#import "CC3GLMatrix.h"

@implementation OpenGLView

+ (Class)layerClass;
{
    return [CAEAGLLayer class];
}

- (void)dealloc;
{
  [_context release];
  _context = nil;
  [super dealloc];
}

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType;
{
  NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
  NSError* error;
  NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
  if (!shaderString) {
    NSLog(@"Error loading shader: %@", error.localizedDescription);
    exit(1);
  }
  GLuint shaderHandle = glCreateShader(shaderType);
  
  const char * shaderStringUTF8 = [shaderString UTF8String];
  int shaderStringLength = [shaderString length];
  glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
  glCompileShader(shaderHandle);
  GLint compileSuccess;
  glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
  if (compileSuccess == GL_FALSE) {
    GLchar messages[256];
    glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
    NSString *messageString = [NSString stringWithUTF8String:messages];
    NSLog(@"%@", messageString);
    exit(1);
  }
  return shaderHandle;
}

- (void)compileShaders {
  GLuint vertexShader = [self compileShader:@"SimpleVertex"
                                   withType:GL_VERTEX_SHADER];
  GLuint fragmentShader = [self compileShader:@"SimpleFragment"
                                     withType:GL_FRAGMENT_SHADER];
  
  GLuint programHandle = glCreateProgram();
  glAttachShader(programHandle, vertexShader);
  glAttachShader(programHandle, fragmentShader);
  glLinkProgram(programHandle);
  
  GLint linkSuccess;
  glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
  if (linkSuccess == GL_FALSE) {
    GLchar messages[256];
    glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
    NSString *messageString = [NSString stringWithUTF8String:messages];
    NSLog(@"%@", messageString);
    exit(1);
  }
  glUseProgram(programHandle);
  
  _positionSlot = glGetAttribLocation(programHandle, "Position");
  _colourSlot = glGetAttribLocation(programHandle, "SourceColour");
  _projectionUniform = glGetUniformLocation(programHandle, "Projection");
  _modelViewUniform = glGetUniformLocation(programHandle, "ModelView");
  glEnableVertexAttribArray(_positionSlot);
  glEnableVertexAttribArray(_colourSlot);
}

- (void)setupVBOs;
{
  GLuint vertexBuffer;
  glGenBuffers(1, &vertexBuffer);
  glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
  
  GLuint indexBuffer;
  glGenBuffers(1, &indexBuffer);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
}

- (id)initWithFrame:(CGRect)frame;
{
  self = [super initWithFrame:frame];
  if (self) {
    [self setupLayer];
    [self setupContext];
   [self setupRenderBuffer];
    [self setupDepthBuffer];
    
    [self setupFrameBuffer];
    [self compileShaders];
    [self setupVBOs];
    [self setUpDisplayLink];
  }
  return self;
}

- (void)setupLayer;
{
  _eaglLayer = (CAEAGLLayer*) self.layer;
  _eaglLayer.opaque = YES;
}

- (void)setupContext;
{
  EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
  _context = [[EAGLContext alloc] initWithAPI:api];
  if (!_context) {
      NSLog(@"Failed to initialise OpenGL ES 2.0 Context");
      exit(1);
  }
  
  if (![EAGLContext setCurrentContext:_context]) {
      NSLog(@"Failed to set current Open GL context");
      exit(1);
  }
}

- (void)setupRenderBuffer;
{
  glGenBuffers(1, &_colorRenderBuffer);
  glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
  [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupDepthBuffer;
{
  glGenRenderbuffers(1, &_depthRenderBuffer);
  glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16,
                        self.frame.size.width, self.frame.size.height);
}

- (void)setupFrameBuffer;
{
  GLuint framebuffer;
  glGenFramebuffers(1, &framebuffer);
  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                            GL_RENDERBUFFER, _colorRenderBuffer);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                            GL_RENDERBUFFER, _depthRenderBuffer);
  glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
  GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
  if(status != GL_FRAMEBUFFER_COMPLETE)
  {
    NSLog(@"Status = %u", status);
  }
}


- (void)render:(CADisplayLink*)displayLink;
{
  glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
  
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glEnable(GL_DEPTH_TEST);
  CC3GLMatrix *projection = [CC3GLMatrix matrix];
  float h = 4.0f * self.frame.size.height / self.frame.size.width;
  [projection populateFromFrustumLeft:-2
                             andRight:2
                            andBottom:-h/2
                               andTop:h/2
                              andNear:4
                               andFar:14];
  glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
  
  CC3GLMatrix *modelView = [CC3GLMatrix matrix];
  [modelView populateFromTranslation:CC3VectorMake(sin(CACurrentMediaTime()), 0, -7)];
  _currentRotation += displayLink.duration * 90;
  [modelView rotateBy:CC3VectorMake(_currentRotation, _currentRotation, 2 * _currentRotation)];
  glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.glMatrix);
  
  glViewport(0, 0, self.frame.size.width, self.frame.size.height);
  
  glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE,
                        sizeof(Vertex), 0);
  glVertexAttribPointer(_colourSlot, 4, GL_FLOAT, GL_FALSE,
                        sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
  
  glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]),
                 GL_UNSIGNED_BYTE, 0);
  
  [_context presentRenderbuffer:GL_RENDERBUFFER];
}

-(void)setUpDisplayLink {
  CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
  [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

//Vertex Data

typedef struct
{
  float Position[3];
  float Colour[4];
} Vertex;

const Vertex Vertices[] =
{
  {{1, -1, 0}, {1, 0, 0, 1}},
  {{1, 1, 0}, {0, 1, 0, 1}},
  {{-1, 1, 0}, {0, 0, 1, 1}},
  {{-1, -1, 0}, {1, 0, 1, 1}},
  {{1, -1, -2}, {1, 0, 0, 1}},
  {{1, 1, -2}, {0, 1, 0, 1}},
  {{-1, 1, -2}, {0, 0, 1, 1}},
  {{-1, -1, -2}, {1, 0, 1, 1}}
};

const GLubyte Indices[] =
{
  0, 1, 2,
  2, 3, 0,
  0, 5, 4,
  0, 5, 1,
  0, 4, 3,
  4, 3, 7,
  4, 6, 5,
  4, 7, 6,
  7, 6, 2,
  2, 3, 7,
  2, 6, 5,
  5, 1, 2
};

@end