//
//  UIColor+TZColor.h
//  TZImagePickerController
//
//  Created by onelab on 2021/12/21.
//  Copyright © 2021 谭真. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;
NS_ASSUME_NONNULL_BEGIN

@interface UIColor (TZColor)
+ (UIColor* )tzColor_colorWithHex:(NSString*)hexStr; //hexStr format: #FF112233

@end

NS_ASSUME_NONNULL_END
