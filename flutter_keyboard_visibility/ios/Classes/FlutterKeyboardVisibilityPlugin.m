//
//  KeyboardVisibilityHandler.m
//  Runner
//
//  Created by admin on 07/11/2018.
//  Copyright © 2018 The Chromium Authors. All rights reserved.
//

#import "FlutterKeyboardVisibilityPlugin.h"

@import CoreLocation;

@interface FlutterKeyboardVisibilityPlugin() <FlutterStreamHandler>

@property (copy, nonatomic) FlutterEventSink flutterEventSink;
@property (assign, nonatomic) BOOL flutterEventListening;
@property (assign, nonatomic) BOOL isVisible;

@end


@implementation FlutterKeyboardVisibilityPlugin

+(void) registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterEventChannel *stream = [FlutterEventChannel eventChannelWithName:@"flutter_keyboard_visibility" binaryMessenger:[registrar messenger]];

    FlutterKeyboardVisibilityPlugin *instance = [[FlutterKeyboardVisibilityPlugin alloc] init];
    [stream setStreamHandler:instance];
}

-(instancetype)init {
    self = [super init];

    self.isVisible = NO;

    // set up the notifier
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didShow) name:UIKeyboardDidShowNotification object:nil];
    [center addObserver:self selector:@selector(willShow) name:UIKeyboardWillShowNotification object:nil];
	[center addObserver:self selector:@selector(didHide) name:UIKeyboardWillHideNotification object:nil];
	[center addObserver:self
                 selector:@selector(keyboardWillChangeFrame:)
                     name:UIKeyboardWillChangeFrameNotification
                   object:nil];

    return self;
}

- (void)keyboardWillChangeFrame:(NSNotification*)notification {
  NSDictionary* info = [notification userInfo];

  // Ignore keyboard notifications related to other apps.
  id isLocal = info[UIKeyboardIsLocalUserInfoKey];
  if (isLocal && ![isLocal boolValue]) {
    return;
  }

  // Ignore keyboard notifications if engine's viewController is not current viewController.
  if ([_engine.get() viewController] != self) {
    return;
  }

  CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
  CGRect screenRect = [[UIScreen mainScreen] bounds];

  // Get the animation duration
  NSTimeInterval duration =
      [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

  // Considering the iPad's split keyboard, Flutter needs to check if the keyboard frame is present
  // in the screen to see if the keyboard is visible.

   double yOfFrame = keyboardFrame.origin.y;
    NSLog(@"%f", yOfFrame);
  if (keyboardFrame.origin.y > 0) {

    NSLog(@"floating test %f", yOfFrame);
    self.targetViewInsetBottom = 0;
  } else if (CGRectIntersectsRect(keyboardFrame, screenRect)) {
    CGFloat bottom = CGRectGetHeight(keyboardFrame);
    CGFloat scale = [UIScreen mainScreen].scale;
    // The keyboard is treated as an inset since we want to effectively reduce the window size by
    // the keyboard height. The Dart side will compute a value accounting for the keyboard-consuming
    // bottom padding.
    self.targetViewInsetBottom = bottom * scale;
  } else {
    self.targetViewInsetBottom = 0;
  }
  [self startKeyBoardAnimation:duration];
}

- (void)didShow
{
    // if state changed and we have a subscriber, let him know
    if (!self.isVisible) {
        self.isVisible = YES;
        if (self.flutterEventListening) {
            self.flutterEventSink([NSNumber numberWithInt:1]);
        }
    }
}

- (void)willShow
{
    // if state changed and we have a subscriber, let him know
    if (!self.isVisible) {
        self.isVisible = YES;
        if (self.flutterEventListening) {
            self.flutterEventSink([NSNumber numberWithInt:1]);
        }
    }
}

- (void)didHide
{
    // if state changed and we have a subscriber, let him know
    if (self.isVisible) {
	    self.isVisible = NO;
		if (self.flutterEventListening) {
			self.flutterEventSink([NSNumber numberWithInt:0]);
		}
    }
}

-(FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    self.flutterEventSink = events;
    self.flutterEventListening = YES;

    // if keyboard is visible at startup, let our subscriber know
    if (self.isVisible) {
        self.flutterEventSink([NSNumber numberWithInt:1]);
    }

    return nil;
}

-(FlutterError*)onCancelWithArguments:(id)arguments {
    self.flutterEventListening = NO;
    return nil;
}

@end
