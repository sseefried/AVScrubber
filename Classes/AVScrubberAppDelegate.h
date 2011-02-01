//
//  AVScrubberAppDelegate.h
//  AVScrubber
//
//  Created by Sean Seefried on 23/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVScrubberViewController;

@interface AVScrubberAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    AVScrubberViewController *viewController;


}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet AVScrubberViewController *viewController;

@end

