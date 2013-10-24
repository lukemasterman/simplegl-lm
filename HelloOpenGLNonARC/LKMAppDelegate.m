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
  self.window = [[UIWindow alloc] initWithFrame:screenBounds];
  UIViewController* viewController = [[UIViewController alloc] init];
  self.window.rootViewController = viewController;
  UIView *view = [[UIView alloc] init];
  _glView = [[OpenGLView alloc]initWithFrame:screenBounds];
  [self.window.rootViewController setView:view];
  [self.window.rootViewController.view addSubview:_glView];
  [self.window makeKeyAndVisible];

    
  return YES;
}


@end
