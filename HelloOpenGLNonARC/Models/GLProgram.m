#import "GLProgram.h"

#pragma mark - Function Pointer Definitions

typedef void (*GLInfoFunction)(GLuint program, GLenum pname, GLint* params);
typedef void (*GLLogFunction) (GLuint program, GLsizei bufsize, GLsizei* length, GLchar* infolog);

@interface GLProgram() {
  NSMutableArray  *_attributes;
  GLuint          _program;
  GLuint          _vertShader;
  GLuint          _fragShader;
}

@end


@implementation GLProgram

- (id)initWithVertexShaderFilename:(NSString *)vShaderFilename
            fragmentShaderFilename:(NSString *)fShaderFilename
{
  self = [super init];
  if (self) {
    _attributes = [[NSMutableArray alloc] init];
    _program    = glCreateProgram();
    
    NSString *vertShaderPathname = [[NSBundle mainBundle] pathForResource:vShaderFilename
                                                                   ofType:@"vsh"];
    
    if (![self compileShader:&_vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
      NSLog(@"Failed to compile vertex shader");
    }
    
    NSString *fragShaderPathname = [[NSBundle mainBundle] pathForResource:fShaderFilename
                                                                   ofType:@"fsh"];

    if (![self compileShader:&_fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
      NSLog(@"Failed to compile fragment shader");
    }
    
    glAttachShader(_program, _vertShader);
    glAttachShader(_program, _fragShader);
  }
  
  return self;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
  GLint status;
  const GLchar *source = (GLchar *)[[NSString stringWithContentsOfFile:file
                                                              encoding:NSUTF8StringEncoding
                                                                 error:nil] UTF8String];
  if (!source) {
    NSLog(@"Failed to load vertex shader");
    return NO;
  }
  
  *shader = glCreateShader(type);
  glShaderSource(*shader, 1, &source, NULL);
  glCompileShader(*shader);
  
  glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
  return GL_TRUE == status;
}

- (void)addAttribute:(NSString *)attributeName;
{
  if (![_attributes containsObject:attributeName])
  {
    [_attributes addObject:attributeName];
    glBindAttribLocation(_program,
                         [_attributes indexOfObject:attributeName],
                         [attributeName UTF8String]);
  }
}

- (GLuint)attributeIndex:(NSString *)attributeName;
{
  return [_attributes indexOfObject:attributeName];
}

- (GLuint)uniformIndex:(NSString *)uniformName;
{
  return glGetUniformLocation(_program, [uniformName UTF8String]);
}

- (BOOL)link;
{
  GLint status;
  
  glLinkProgram(_program);
  glValidateProgram(_program);
  
  glGetProgramiv(_program, GL_LINK_STATUS, &status);
  if (GL_FALSE == status) {
    return NO;
  }
  
  if (_vertShader) {
    glDeleteShader(_vertShader);
  }
  
  if (_fragShader) {
    glDeleteShader(_fragShader);
  }
  
  return YES;
}

- (void)use;
{
  glUseProgram(_program);
}

- (NSString *)vertexShaderLog;
{
  return [self logForOpenGLObject:_vertShader
                     infoCallback:(GLInfoFunction)&glGetProgramiv
                          logFunc:(GLLogFunction)&glGetProgramInfoLog];
  
}

- (NSString *)fragmentShaderLog;
{
  return [self logForOpenGLObject:_fragShader
                     infoCallback:(GLInfoFunction)&glGetProgramiv
                          logFunc:(GLLogFunction)&glGetProgramInfoLog];
}

- (NSString *)programLog;
{
  return [self logForOpenGLObject:_program
                     infoCallback:(GLInfoFunction)&glGetProgramiv
                          logFunc:(GLLogFunction)&glGetProgramInfoLog];
}

- (NSString *)logForOpenGLObject:(GLuint)object
                    infoCallback:(GLInfoFunction)infoFunc
                         logFunc:(GLLogFunction)logFunc;
{
  GLint logLength    = 0;
  GLint charsWritten = 0;
  
  infoFunc(object, GL_INFO_LOG_LENGTH, &logLength);
  if (logLength < 1) {
    return nil;
  }
  
  char *logBytes = malloc(logLength);
  logFunc(object, logLength, &charsWritten, logBytes);
  NSString *log = [[NSString alloc] initWithBytes:logBytes
                                           length:logLength
                                         encoding:NSUTF8StringEncoding];
  free(logBytes);
  
  return log;
}


- (void)dealloc;
{
  if (_vertShader) {
    glDeleteShader(_vertShader);
  }
  
  if (_fragShader) {
    glDeleteShader(_fragShader);
  }
  
  if (_program) {
    glDeleteProgram(_program);
  }
}

@end
