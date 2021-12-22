//
//  UIColor+TZColor.m
//  TZImagePickerController
//
//  Created by onelab on 2021/12/21.
//  Copyright © 2021 谭真. All rights reserved.
//

#import "UIColor+TZColor.h"

@implementation UIColor (TZColor)
+ (UIColor* )tzColor_colorWithHex:(NSString*)hexStr //hexStr format: #FF112233
{
    if (hexStr.length==6) {
        hexStr = [NSString stringWithFormat:@"FF%@", hexStr];
    }
    if (hexStr.length==8) {
        hexStr = [NSString stringWithFormat:@"#%@", hexStr];
    }
    NSString *hexAlpha = [[hexStr substringWithRange:NSMakeRange(1, 2)] uppercaseString];
    NSString *hexColor = [[hexStr substringWithRange:NSMakeRange(3, 6)] uppercaseString];
    unsigned color = 0;
    unsigned alpha = 0;
    NSScanner *scannerColor = [NSScanner scannerWithString:hexColor];
    NSScanner *scannerAlpha = [NSScanner scannerWithString:hexAlpha];
    
    [scannerColor setScanLocation:0];
    [scannerColor scanHexInt:&color];
    [scannerAlpha setScanLocation:0];
    [scannerAlpha scanHexInt:&alpha];
    //
    unsigned char r, g, b, a;
    b = color & 0xFF;
    g = (color >> 8) & 0xFF;
    r = (color >> 16) & 0xFF;
    a = alpha & 0xFF;
    
//    NSLog(@"R=%d G=%d B=%d A =%d", r, g, b, a);
    //
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a/255.0];
}
@end
