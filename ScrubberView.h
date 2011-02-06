//
//  ScrubberView.h
//
//  Created by Sean Seefried on 23/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <tgmath.h>

@interface ScrubberView: UIView {

  @private 

  IBOutlet UILabel *_infoLabel;
  CGFloat _start;
  CGFloat _end;
  /* When moving the entire bar, the bar is "anchored" to 
   * the point where you initially touched it. _anchorX is 
   * the X co-ordinate of this 
   */
  CGFloat _anchorX;
  int _touchMovingMode;
  int _markerSelected; // whether the start or end marker is highleted.
  CGFloat _duration;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void) setStart:(CGFloat)start andEnd:(CGFloat)end;


@end
