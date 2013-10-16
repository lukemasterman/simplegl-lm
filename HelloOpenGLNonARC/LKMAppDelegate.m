//
//  LKMAppDelegate.m
//  HelloOpenGL
//
//  Created by Luke Masterman on 10/10/2013.
//  Copyright (c) 2013 Luke Masterman. All rights reserved.
//

#import "LKMAppDelegate.h"

@implementation LKMAppDelegate
@synthesize glView = _glView;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  self.window = [[[UIWindow alloc] initWithFrame:screenBounds] autorelease];
  UIViewController* viewController = [[[UIViewController alloc] init] autorelease];
  self.window.rootViewController = viewController;
  UIView *view = [[[UIView alloc] init] autorelease];
  _glView = [[[OpenGLView alloc]initWithFrame:screenBounds] autorelease];
  [self.window.rootViewController setView:view];
  [self.window.rootViewController.view addSubview:_glView];
  [self.window makeKeyAndVisible];
    
  return YES;
}

- (void)dealloc;
{
  [_glView release];
  [super dealloc];
}

@end
