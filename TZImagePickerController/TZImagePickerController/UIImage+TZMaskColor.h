//
//  UIimage+TZMaskColor.h
//  TZImagePickerController
//
//  Created by onelab on 2021/12/22.
//  Copyright © 2021 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (TZMaskColor)
- (UIImage *)tz_imageMaskedWithColor:(UIColor *)maskColor;
@end

NS_ASSUME_NONNULL_END
