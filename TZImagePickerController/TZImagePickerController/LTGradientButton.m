//
//  LTGradientButton.m
//  securedcomm
//
//  Created by onelab on 2021/5/14.
//  Copyright © 2021 Jimmy.Chen. All rights reserved.
//

#import "LTGradientButton.h"

@implementation LTGradientButton

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self setupView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setupView];
    }
    return self;
}

- (void)setupView
{
    self.backgroundColor = [UIColor clearColor];
    self.heightRatio = 0.24;
    self.widthRatio = 1.0f;
    self.startWidthRatio = 0.0f;
    self.startHeightRatio = 0.0f;
    self.fillAllColor = YES;
}

- (void)redrawView
{
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if (self.colorArray.count >0) {
        //reference: http://myappglog.blogspot.tw/2013/07/blog-post.html and http://www.cnblogs.com/zenny-chen/archive/2012/02/23/2364152.html
        CGContextRef contextRef = UIGraphicsGetCurrentContext();
        if (self.fillAllColor) {
            CGContextSetFillColorWithColor(contextRef, [self.colorArray.lastObject CGColor]);
            CGContextFillRect(contextRef, CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height));
        }
        
        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
        NSMutableArray *gradientColors = [NSMutableArray new];
        for (UIColor *color in self.colorArray){
            [gradientColors addObject:(id)[color CGColor]];
        }
        CGGradientRef gradientRef = CGGradientCreateWithColors(colorSpaceRef, (CFArrayRef)gradientColors, nil);
        
        CGPoint beginPoint = CGPointMake(CGRectGetWidth(rect)*self.startWidthRatio, CGRectGetHeight(rect)*self.startHeightRatio);
        CGPoint endPoint = CGPointMake(CGRectGetWidth(rect)*self.widthRatio, CGRectGetHeight(rect)*self.heightRatio);
        CGContextDrawLinearGradient(contextRef, gradientRef, beginPoint, endPoint, 0);
        
        CGColorSpaceRelease(colorSpaceRef);
        CGGradientRelease(gradientRef);
    }
}


@end