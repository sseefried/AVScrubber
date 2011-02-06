//
//  ScrubberView.m
//
//  Created by Sean Seefried on 23/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ScrubberView.h"



/* "Private" methods. The "()" means "empty category" */
@interface ScrubberView ()
- (void) drawRoundedRect:(CGRect)rect withContext:(CGContextRef)context;
- (void) drawStartMarker:(CGContextRef)context;
- (void) drawEndMarker:(CGContextRef)context;
- (void) drawMarker:(CGContextRef)context atNormalizedX:(CGFloat)normalizedX 
         isHighlighted:(BOOL)highlighted;
- (const char *)timeString:(CGFloat)normalizedX;
- (CGFloat)startEdgeX;
- (CGFloat)endEdgeX;
- (CGFloat)realX:(CGFloat)normalizedX;
- (CGFloat)position:(CGFloat)normalizedX;
- (CGFloat)normalizedX:(CGFloat)realX;

typedef struct {
  CGFloat r;
  CGFloat g;
  CGFloat b;
  CGFloat a;
} RGBAColour;

/* The three different "moving touch" states for this UI item. 
 * Either you are:
 * - moving the whole bar
 * - changing the start value
 * - changing the end value
 */  
enum { 
  kOutsideBar, // not moving it
  kMovingWholeBar,
  kChangingStart,
  kChangingEnd
};


/* Whether the start or end marker is selected */
enum {
  kStartMarkerSelected,
  kEndMarkerSelected
};

@end

@implementation ScrubberView

// The markers at the top of the bar required a certain amount of room.
CGFloat const kMarkerHeightBuffer = 15.0f; 
CGFloat const kEdgeTolerance      = 20.0f;  // How close to edge you need to tap to active drag of edge.
CGFloat const kMinimumBarWidth    = 20.0f; 

CGFloat const kMarkerTextPadding = 11.0;
CGFloat const kMarkerMargin      = 2.0;
CGFloat const kMarkerFontSize    = 12.0;

RGBAColour const unhighlighted = { .r = 1.0, .g = 0.6, .b = 0.0, .a = 1.0 };
RGBAColour const highlighted   = { .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 };

- (id)initWithCoder:(NSCoder *)aDecoder {
  [super initWithCoder:aDecoder];
  _start = 0.0;
  _end = 1.0;
  _duration = 145; // seconds
  _touchMovingMode = kOutsideBar;
  _markerSelected = kStartMarkerSelected;
  return self;
}

/* If start > end then the values are swapped before setting */
- (void) setStart:(CGFloat)start andEnd:(CGFloat)end {
  if (start < end) {
    _start = start;
    _end = end;
  } else {
    _start = end;
    _end = start;
  }
}

- (void) drawRect:(CGRect)rect {

  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetLineCap(context, kCGLineCapRound);

  CGFloat _width = (_end - _start) * rect.size.width;
  CGFloat _x     = [self realX:_start];
  
  CGRect newRect = { .origin = { .x = _x, .y = rect.origin.y + kMarkerHeightBuffer }, 
                     .size = { .width = _width, .height = rect.size.height - kMarkerHeightBuffer}};

  // Draw start marker
  [self drawStartMarker:context];
  [self drawEndMarker:context];
  [self drawRoundedRect:newRect withContext:context];
	UIGraphicsEndImageContext();
}

- (void) drawStartMarker:(CGContextRef)context {
  [self drawMarker:context atNormalizedX:_start isHighlighted:(_markerSelected == kStartMarkerSelected)];
}

- (void) drawEndMarker:(CGContextRef)context {
  [self drawMarker:context atNormalizedX:_end isHighlighted:(_markerSelected == kEndMarkerSelected)];
}

- (void) drawMarker:(CGContextRef)context atNormalizedX:(CGFloat)normalizedX 
         isHighlighted:(BOOL)isHighlighted {
  CGRect  rect = [self bounds];
  CGFloat    x = [self realX:normalizedX];

  
  CGFloat miny = CGRectGetMinY(rect) + kMarkerTextPadding;
  CGFloat maxy = CGRectGetMaxY(rect);
  
//  CGContextSetShouldSmoothFonts(context, YES);
//  CGContextSetShouldAntialias(context, YES);
//  CGContextSetAllowsFontSubpixelPositioning(context, YES);
//  CGContextSetShouldSubpixelPositionFonts(context, YES);
//  CGContextSetAllowsFontSubpixelQuantization(context, YES);
//  CGContextSetShouldSubpixelQuantizeFonts(context, YES);
  
  
  RGBAColour c = isHighlighted ? highlighted : unhighlighted;

  CGContextSetRGBStrokeColor(context, c.r, c.g, c.b, c.a);
  CGContextSetRGBFillColor(context, c.r, c.g, c.b, c.a);
  CGContextMoveToPoint(context, x,miny);
  CGContextAddLineToPoint(context, x,maxy);
  CGContextClosePath(context); 
  CGContextDrawPath(context, kCGPathFillStroke); 
  
  CGContextSetTextDrawingMode(context, kCGTextFill);
  CGContextSelectFont(context, "Helvetica", kMarkerFontSize, kCGEncodingMacRoman);
  CGAffineTransform transform = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0);
  CGContextSetTextMatrix(context, transform);
  const char *s = [self timeString:normalizedX];
  NSUInteger len = strlen(s);
  CGContextShowTextAtPoint(context, x - (len * kMarkerFontSize / 4), miny - kMarkerMargin, s, len);
}

- (const char *)timeString:(CGFloat) normalizedX {
  CGFloat position = [self position:normalizedX];
  NSUInteger tenths = ((NSUInteger) (position * 10)) % 10;
  NSUInteger seconds = ((NSUInteger) position) % 60;
  NSUInteger minutes = ((NSUInteger) position) / 60;
  
  NSString *s = [NSString stringWithFormat:@"%2d:%02d.%d", minutes, seconds, tenths];
  const char *str = [s cStringUsingEncoding:[NSString defaultCStringEncoding]];
  return str;
}


- (void) drawRoundedRect:(CGRect)rect withContext:(CGContextRef) context {
  
  CGContextSetRGBStrokeColor(context, 1.0, 0.6, 0.0, 1.0);
	CGContextSetRGBFillColor(context, 1.0, 0.4, 0.3, 0.5);

  // As a bonus, we'll combine arcs to create a round rectangle! 
  
  // If you were making this as a routine, you would probably accept a rectangle 
  // that defines its bounds, and a radius reflecting the "rounded-ness" of the rectangle. 

  
  
  CGFloat radius = 10.0; 
  // NOTE: At this point you may want to verify that your radius is no more than half 
  // the width and height of your rectangle, as this technique degenerates for those cases. 
  
  // In order to draw a rounded rectangle, we will take advantage of the fact that 
  // CGContextAddArcToPoint will draw straight lines past the start and end of the arc 
  // in order to create the path from the current position and the destination position. 
  
  // In order to create the 4 arcs corectly, we need to know the min, mid and max positions 
  // on the x and y lengths of the given rectangle. 
  CGFloat minx = CGRectGetMinX(rect), midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect); 
  CGFloat miny = CGRectGetMinY(rect), midy = CGRectGetMidY(rect), maxy = CGRectGetMaxY(rect); 
  
  // Next, we will go around the rectangle in the order given by the figure below. 
  //       minx    midx    maxx 
  // miny    2       3       4 
  // midy    1       9       5 
  // maxy    8       7       6 
  // Which gives us a coincident start and end point, which is incidental to this technique, but still doesn't 
  // form a closed path, so we still need to close the path to connect the ends correctly. 
  // Thus we start by moving to point 1, then adding arcs through each pair of points that follows. 
  // You could use a similar tecgnique to create any shape with rounded corners. 
  
  // Start at 1 
  CGContextMoveToPoint(context, minx, midy); 
  // Add an arc through 2 to 3 
  CGContextAddArcToPoint(context, minx, miny, midx, miny, radius); 
  // Add an arc through 4 to 5 
  CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius); 
  // Add an arc through 6 to 7 
  CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius); 
  // Add an arc through 8 to 9 
  CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius); 
  // Close the path 
  CGContextClosePath(context); 
  // Fill & stroke the path 
  CGContextDrawPath(context, kCGPathFillStroke); 

}

# pragma mark -
# pragma 

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

  /* Multitouch should be disabled so this will get only touch object */
  UITouch *touch = [touches anyObject];

  CGPoint pt = [touch locationInView:self];

  CGFloat distToStart = fabs(pt.x - [self startEdgeX]);
  CGFloat distToEnd   = fabs(pt.x - [self endEdgeX]);
  
  if ( distToStart <= distToEnd && distToStart < kEdgeTolerance )  {
    _touchMovingMode = kChangingStart;
    _markerSelected = kStartMarkerSelected;
  } else if ( distToEnd <= distToStart && distToEnd < kEdgeTolerance )  {
    _touchMovingMode = kChangingEnd;
    _markerSelected = kEndMarkerSelected;
  } else if (pt.x >= [self startEdgeX] && pt.x <= [self endEdgeX]) {
    _touchMovingMode = kMovingWholeBar;
    _anchorX = pt.x;
  } else {
    _touchMovingMode = kOutsideBar;
  }
  _infoLabel.text = [NSString stringWithFormat:@"(moving mode = %d)", _touchMovingMode];
  [self setNeedsDisplay]; // needed to update marker highlighting
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  _infoLabel.text = @"touchesEnded";
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  _infoLabel.text = @"touchesMoved";   


  
  /* Multitouch should be disabled so this will get only touch object */
  UITouch *touch = [touches anyObject];
  
  CGPoint pt = [touch locationInView:self];
  CGRect r = [self bounds];
  CGFloat minWidth = kMinimumBarWidth / r.size.width;
  
  if ( _touchMovingMode == kChangingStart) {
    CGFloat newStart = [self normalizedX:pt.x];
    if ( newStart < _end - minWidth ) { 
      _start = newStart;
      _infoLabel.text = [NSString stringWithFormat:@"start = %f", _start];
    }
  } else if ( _touchMovingMode == kChangingEnd ) {
    CGFloat newEnd = [self normalizedX:pt.x];
    if ( newEnd > _start + minWidth ) {
      _end = newEnd;
      _infoLabel.text = [NSString stringWithFormat:@"end = %f", _end];
    }
  } else if ( _touchMovingMode == kMovingWholeBar ) {
    CGFloat displacement = pt.x - _anchorX;
    CGFloat newStart = [self normalizedX:([self realX:_start] + displacement)];
    CGFloat newEnd   = [self normalizedX:([self realX:_end]   + displacement)];    

    if ( newStart >= 0.0 && newEnd <= 1.0 ) {
      _start = newStart;
      _anchorX = pt.x;
      _end = newEnd;
    }
  }

  [self setNeedsDisplay];
}


/* There are two co-ordinate systems in used. The first is the
 * normalized scale where X is in range (0.0, 1.0). The second is
 * the real scale where X is in range (r.origin.x, r.origin.x + r.size.width)
 * where r == [self bounds]
 */


/* Converts from normalized scale to real scale */
- (CGFloat)realX:(CGFloat)normalizedX {
  CGRect r = [self bounds];
//  NSLog(@"r.size.width = %f, r.origin.x = %f", r.size.width, r.origin.x);
  return (normalizedX * r.size.width + r.origin.x);
  
}

- (CGFloat)position:(CGFloat)normalizedX {
  return (normalizedX * _duration);
  
}

/* Converts from real scale to normalized scale */
- (CGFloat)normalizedX:(CGFloat)realX {
  CGRect r = [self bounds];
  return (realX - r.origin.x) / r.size.width;
}


/* Returns the x co-ordinate of the "start" edge of the bar */
- (CGFloat)startEdgeX {
  CGRect r = [self bounds];
  return (r.size.width * _start) + r.origin.x;
}
        
/* Returns the x co-ordinate of the "end" edge of the bar */
- (CGFloat)endEdgeX {
  CGRect r = [self bounds];
  return (r.size.width * _end) + r.origin.x;
}
           
@end
