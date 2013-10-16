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
  GLuint _colourSlot;
  GLuint _projectionUniform;
  GLuint _modelViewUniform;
  GLuint _colorRenderBuffer;
  GLuint _depthRenderBuffer;
  GLint _height;
  GLint _width;
  GLfloat _currentRotation;
}
@property (nonatomic, strong) CAEAGLLayer *eaglLayer;
@property (nonatomic, strong) EAGLContext *context;

@end
