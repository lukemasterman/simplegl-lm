//
//  LKMAppDelegate.h
//  HelloOpenGL
//
//  Created by Luke Masterman on 10/10/2013.
//  Copyright (c) 2013 Luke Masterman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OpenGLView.h"

@interface LKMAppDelegate : UIResponder <UIApplicationDelegate>
{
  OpenGLView* _glView;
}

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) OpenGLView *glView;

@end
