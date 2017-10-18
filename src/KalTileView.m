/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

@import CoreText;

#import "KalTileView.h"
#import "KalDate.h"
#import "KalPrivate.h"

extern CGSize kalTileSize(void);

@implementation KalTileView

@synthesize date;

- (id)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;
    origin = frame.origin;
    [self setIsAccessibilityElement:YES];
    [self setAccessibilityTraits:UIAccessibilityTraitButton];
    [self resetState];
  }
  return self;
}

- (void)drawRect:(CGRect)rect
{
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGFloat fontSize = 21.5f;
  UIFont *font = [UIFont systemFontOfSize:fontSize];
  UIColor *textColor = nil;
  UIImage *markerImage = nil;
  UIImage *specialMarkerImage = nil;

  CGContextTranslateCTM(ctx, 0, kalTileSize().height);
  CGContextScaleCTM(ctx, 1, -1);

  if ([self isToday] && self.selected) {
    [self drawBackgroundImage:[[UIImage kal_imageNamed:@"kal_tile_today_selected.png"] stretchableImageWithLeftCapWidth:2 topCapHeight:2]];
    textColor = [UIColor colorWithPatternImage:[UIImage kal_imageNamed:@"kal_tile_text_fill.png"]];
    markerImage = [UIImage kal_imageNamed:@"kal_marker_today.png"];
    specialMarkerImage = [UIImage kal_imageNamed:@"pink_kal_marker_today.png"];
  } else if ([self isToday] && !self.selected) {
    [self drawBackgroundImage:[[UIImage kal_imageNamed:@"kal_tile_today.png"] stretchableImageWithLeftCapWidth:2 topCapHeight:2]];
    textColor = [UIColor colorWithRed:0.271 green:0.655 blue:0.616 alpha:1];
    markerImage = [UIImage kal_imageNamed:@"kal_marker_today.png"];
    specialMarkerImage = [UIImage kal_imageNamed:@"pink_kal_marker_today.png"];
  } else if (self.selected) {
    [self drawBackgroundImage:[[UIImage kal_imageNamed:@"kal_tile_selected.png"] stretchableImageWithLeftCapWidth:2 topCapHeight:2]];
    textColor = [UIColor colorWithPatternImage:[UIImage kal_imageNamed:@"kal_tile_text_fill.png"]];
    markerImage = [UIImage kal_imageNamed:@"kal_marker_selected.png"];
    specialMarkerImage = [UIImage kal_imageNamed:@"pink_kal_marker_selected.png"];
  } else if (self.belongsToAdjacentMonth) {
    textColor = [UIColor colorWithPatternImage:[UIImage kal_imageNamed:@"kal_tile_dim_text_fill.png"]];
    markerImage = [UIImage kal_imageNamed:@"kal_marker_dim.png"];
    specialMarkerImage = [UIImage kal_imageNamed:@"pink_kal_marker_dim.png"];
  } else {
    textColor = [UIColor colorWithPatternImage:[UIImage kal_imageNamed:@"kal_tile_text_fill.png"]];
    markerImage = [UIImage kal_imageNamed:@"kal_marker.png"];
    specialMarkerImage = [UIImage kal_imageNamed:@"pink_kal_marker.png"];
  }

  // We need to offset tile content to compensate for the workaround used in setSelected: (see below)
  BOOL horizontalOffset = 1.0f;
  if (![self isToday] && !self.selected) {
    horizontalOffset = 0.0f;
  }

  CGFloat x = (kalTileSize().width - 6.0) / 2.0;
  if ([UIScreen mainScreen].scale == 1.0) {
    x = roundf(x);
  }

  if (flags.marked) {
    if (flags.speciallyMarked) {
      [markerImage drawInRect:CGRectMake(x - 4 + horizontalOffset, 5.f, 6.f, 7.f)];
      [specialMarkerImage drawInRect:CGRectMake(x + 4 + horizontalOffset, 5.f, 6.f, 7.f)];
    }
    else {
      [markerImage drawInRect:CGRectMake(x + horizontalOffset, 5.f, 6.f, 7.f)];
    }
  }
  else if (flags.speciallyMarked) {
    [specialMarkerImage drawInRect:CGRectMake(x + horizontalOffset, 5.f, 6.f, 7.f)];
  }
  
  NSUInteger n = [self.date day];
  NSString *dayText = [NSString stringWithFormat:@"%lu", (unsigned long)n];
  CGSize textSize = [dayText sizeWithAttributes:@{ NSFontAttributeName: font }];
  CGFloat textX, textY;
  textX = roundf(0.5f * (kalTileSize().width - textSize.width)) + horizontalOffset;
  textY = 10.f + roundf(0.5f * (kalTileSize().height - textSize.height));
  [textColor setFill];

  NSDictionary *attributes = @{
    NSForegroundColorAttributeName : textColor,
    NSFontAttributeName:font};

  NSAttributedString *attributedString = [[[NSAttributedString alloc] initWithString:dayText attributes:attributes] autorelease];

  CTLineRef displayLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
  CGContextSetTextPosition(ctx, textX, textY);
  CTLineDraw(displayLine, ctx);
  CFRelease(displayLine);

  if (self.highlighted) {
    [[UIColor colorWithWhite:0.25f alpha:0.3f] setFill];
    CGContextFillRect(ctx, CGRectMake(0.f, 0.f, kalTileSize().width, kalTileSize().height));
  }
}

- (void)drawBackgroundImage:(UIImage*)image {
  if ([UIScreen mainScreen].scale == 2.0) {
    [image drawInRect:CGRectMake(0.5, -0.5, kalTileSize().width+0.5, kalTileSize().height+0.5)];
  }
  else {
    [image drawInRect:CGRectMake(0, -1, kalTileSize().width+1, kalTileSize().height+1)];
  }
}

- (void)resetState
{
  // realign to the grid
  CGRect frame = self.frame;
  frame.origin = origin;
  frame.size = kalTileSize();
  self.frame = frame;
  
  [date release];
  date = nil;
  flags.type = KalTileTypeRegular;
  flags.highlighted = NO;
  flags.selected = NO;
  flags.marked = NO;
}

- (void)setDate:(KalDate *)aDate
{
  if (date == aDate)
    return;

  [date release];
  date = [aDate retain];

  [self setNeedsDisplay];
}

- (BOOL)isSelected { return flags.selected; }

- (void)setSelected:(BOOL)selected
{
  if (flags.selected == selected)
    return;

  // workaround since I cannot draw outside of the frame in drawRect:
  if (![self isToday]) {
    CGRect rect = self.frame;
    if (selected) {
      rect.origin.x--;
      rect.size.width++;
      rect.size.height++;
    } else {
      rect.origin.x++;
      rect.size.width--;
      rect.size.height--;
    }
    self.frame = rect;
  }
  
  flags.selected = selected;
  [self setNeedsDisplay];
}

- (BOOL)isHighlighted { return flags.highlighted; }

- (void)setHighlighted:(BOOL)highlighted
{
  if (flags.highlighted == highlighted)
    return;
  
  flags.highlighted = highlighted;
  [self setNeedsDisplay];
}

- (BOOL)isMarked { return flags.marked; }

- (void)setMarked:(BOOL)marked
{
  if (flags.marked == marked)
    return;
  
  flags.marked = marked;
  [self setNeedsDisplay];
}

- (BOOL)isSpeciallyMarked { return flags.speciallyMarked; }

- (void)setSpeciallyMarked:(BOOL)speciallyMarked
{
  if (flags.speciallyMarked == speciallyMarked)
    return;

  flags.speciallyMarked = speciallyMarked;
  [self setNeedsDisplay];
}

- (KalTileType)type { return flags.type; }

- (void)setType:(KalTileType)tileType
{
  if (flags.type == tileType)
    return;
  
  // workaround since I cannot draw outside of the frame in drawRect:
  CGRect rect = self.frame;
  if (tileType == KalTileTypeToday) {
    rect.origin.x--;
    rect.size.width++;
    rect.size.height++;
  } else if (flags.type == KalTileTypeToday) {
    rect.origin.x++;
    rect.size.width--;
    rect.size.height--;
  }
  self.frame = rect;
  
  flags.type = tileType;
  [self setNeedsDisplay];
}

- (BOOL)isToday { return flags.type == KalTileTypeToday; }

- (BOOL)belongsToAdjacentMonth { return flags.type == KalTileTypeAdjacent; }

- (void)dealloc
{
  [date release];
  [super dealloc];
}

@end
