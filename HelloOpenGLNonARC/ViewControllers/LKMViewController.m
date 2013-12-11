//
//  LKMViewController.m
//  HelloOpenGLNonARC
//
//  Created by Luke Masterman on 24/10/2013.
//  Copyright (c) 2013 Luke Masterman. All rights reserved.
//

#import "LKMViewController.h"

@interface LKMViewController ()

@property (nonatomic, strong) EAGLContext *context;

@end

@implementation LKMViewController

- (void)viewDidLoad;
{
  [super viewDidLoad];
  
  self.glkView.context = _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:_context];
  
  
}

- (void)update;
{
  
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect;
{
  
}

- (GLKView *)glkView;
{
  return (id)self.view;
}

@end
