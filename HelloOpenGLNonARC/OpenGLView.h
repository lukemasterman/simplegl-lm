//
//  OpenGLView.h
//  HelloOpenGL
//
//  Created by Luke Masterman on 10/10/2013.
//  Copyright (c) 2013 Luke Masterman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@interface OpenGLView : UIView
{
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
@property (nonatomic, strong) CAEAGLLayer *eaglLayer;
@property (nonatomic, strong) EAGLContext *context;

@end
