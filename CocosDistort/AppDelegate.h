//
//  AppDelegate.h
//  CocosDistort
//
//  Created by Ferrari Pierre on 19.04.11.
//  Copyright piferrari.org 2011. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow			*window;
	RootViewController	*viewController;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) RootViewController *viewController;
@end
