//
//  OpenGLView.m
//  HelloOpenGL
//
//  Created by Luke Masterman on 10/10/2013.
//  Copyright (c) 2013 Luke Masterman. All rights reserved.
//

#import "OpenGLView.h"
#import "CC3GLMatrix.h"
#import "mug.h"

@interface OpenGLView ()

@property (nonatomic, strong) CAEAGLLayer *eaglLayer;
@property (nonatomic, strong) EAGLContext *context;

@end

@implementation OpenGLView {
  GLuint _positionSlot;
  GLuint _normals;
  GLuint _colourUniform;
  GLuint _projectionUniform;
  GLuint _modelViewUniform;
  GLuint _lightPosUniform;
  GLuint _colorRenderBuffer;
  GLuint _depthRenderBuffer;
  GLuint _texCoordSlot;
  GLuint _textureUniform;
  GLuint _texture;
  GLint _translationX;
  GLint _translationY;
  GLfloat _currentRotationX;
  GLfloat _currentRotationY;
}

+ (Class)layerClass;
{
    return [CAEAGLLayer class];
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
    [self setUpDisplayLink];
    [self setupPanGestureRecognizer];
    _texture = [self setupTexture:@"mug_texture_map_test_soph.png"];
  }
  return self;
}

- (id)initWithFrame:(CGRect)frame andTexture:(NSString*)texture;
{
  self = [super initWithFrame:frame];
  if (self) {
    [self setupLayer];
    [self setupContext];
    [self setupRenderBuffer];
    [self setupDepthBuffer];
    [self setupFrameBuffer];
    [self compileShaders];
    [self setUpDisplayLink];
    [self setupPanGestureRecognizer];
    _texture = [self setupTexture:texture];
  }
  return self;
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
    NSString *messageString = @(messages);
    NSLog(@"%@", messageString);
    exit(1);
  }
  return shaderHandle;
}

- (void)compileShaders;
{
  GLuint vertexShader   = [self compileShader:@"SimpleVertex"   withType:GL_VERTEX_SHADER];
  GLuint fragmentShader = [self compileShader:@"SimpleFragment" withType:GL_FRAGMENT_SHADER];

  GLuint programHandle = glCreateProgram();
  glAttachShader(programHandle, vertexShader);
  glAttachShader(programHandle, fragmentShader);
  glLinkProgram(programHandle);
  
  GLint linkSuccess;
  glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
  if (linkSuccess == GL_FALSE) {
    GLchar messages[256];
    glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
    NSString *messageString = @(messages);
    NSLog(@"%@", messageString);
    exit(1);
  }
  glUseProgram(programHandle);
  
  _positionSlot = glGetAttribLocation(programHandle, "Position");
  _normals = glGetAttribLocation(programHandle, "Normals");
  _texCoordSlot = glGetAttribLocation(programHandle, "TexCoordIn");
  _colourUniform = glGetUniformLocation(programHandle, "SourceColour");
  _textureUniform = glGetUniformLocation(programHandle, "Texture");
  _projectionUniform = glGetUniformLocation(programHandle, "Projection");
  _modelViewUniform = glGetUniformLocation(programHandle, "ModelView");
  _lightPosUniform = glGetUniformLocation(programHandle, "LightPosition");
  glEnableVertexAttribArray(_texCoordSlot);
  glEnableVertexAttribArray(_positionSlot);
  glEnableVertexAttribArray(_normals);
}

- (GLuint)setupTexture:(NSString *)fileName;
{
  CGImageRef texImage = [UIImage imageNamed:fileName].CGImage;
  if (!texImage) {
    NSLog(@"Failed to load image %@", fileName);
    exit(1);
  }
  
  size_t width = CGImageGetWidth(texImage);
  size_t height = CGImageGetHeight(texImage);
  
  GLubyte * texData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
  
  CGContextRef texContext = CGBitmapContextCreate(texData, width, height, 8, width*4,
                                                     CGImageGetColorSpace(texImage), kCGImageAlphaPremultipliedLast);
  
  CGContextDrawImage(texContext, CGRectMake(0, 0, width, height), texImage);
  
  CGContextRelease(texContext);
  
  GLuint texName;
  glGenTextures(1, &texName);
  glBindTexture(GL_TEXTURE_2D, texName);
  
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, texData);
  
  free(texData);
  return texName;
}



- (void)setupPanGestureRecognizer;
{
  UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
  [self addGestureRecognizer:panGesture];
}

- (void)setupLayer;
{
  _eaglLayer = (CAEAGLLayer*) self.layer;
  _eaglLayer.opaque = YES;
}

- (void)setupContext;
{
  _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
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
  //glEnable(GL_CULL_FACE);
  CC3GLMatrix *projection = [CC3GLMatrix matrix];
  float h = 4.0f * self.frame.size.height / self.frame.size.width;
  [projection populateFromFrustumLeft:-0.5
                             andRight:0.5
                            andBottom:-h/8
                               andTop:h/8
                              andNear:4
                               andFar:20];
  glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
  
  CC3GLMatrix *modelView = [CC3GLMatrix matrix];
  [modelView populateFromTranslation:CC3VectorMake(0, 0, -5)];
  _currentRotationY += _translationX;
  _currentRotationX += _translationY;
  [modelView rotateBy:CC3VectorMake(-_currentRotationX, _currentRotationY, 0)];
  glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.glMatrix);
  glUniform4f(_colourUniform, 1.0, 0.0, 0.0, 1.0);
  glUniform3f(_lightPosUniform, 1.0, 1.0, -5.0);
  glViewport(0, 0, self.frame.size.width, self.frame.size.height);
  
  glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, mugVerts);
  glVertexAttribPointer(_normals, 3, GL_FLOAT, GL_FALSE, 0, mugNormals);
  glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, 0, mugTexCoords);
  
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, _texture);
  glUniform1i(_textureUniform, 0);
  
  glDrawArrays(GL_TRIANGLES, 0, mugNumVerts);
  
  [_context presentRenderbuffer:GL_RENDERBUFFER];
}

-(void)setUpDisplayLink {
  CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
  [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)handlePan:(UIPanGestureRecognizer *)panGestureRecognizer;
{
  CGPoint translation = [panGestureRecognizer translationInView:self];
  _translationX = translation.x;
  _translationY = translation.y;
  [panGestureRecognizer setTranslation:CGPointMake(0, 0) inView:self];

  
  
  NSLog(@"%@", NSStringFromCGPoint(translation));
}

@end
