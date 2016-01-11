//
//  UIImageAdditions.m
//  Kal
//
//  Created by Victor Ilyukevich on 1/11/16.
//
//

#import "UIImageAdditions.h"
#import "KalView.h"

@implementation UIImage (KalAdditions)

+ (instancetype)kal_imageNamed:(NSString *)name
{
  static NSBundle *bundle = nil;
  if (bundle == nil) {
    NSBundle *frameworkBundle = [NSBundle bundleForClass:[KalView class]];
    NSString *bundlePath = [frameworkBundle pathForResource:@"Kal" ofType:@"bundle"];
    bundle = [NSBundle bundleWithPath:bundlePath];
  }

  return [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
}

@end
