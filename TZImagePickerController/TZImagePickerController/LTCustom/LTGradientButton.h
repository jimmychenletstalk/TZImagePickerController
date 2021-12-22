//
//  LTGradientButton.h
//  securedcomm
//
//  Created by onelab on 2021/5/14.
//  Copyright © 2021 Jimmy.Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTGradientButton : UIButton
@property (nonatomic, strong)NSArray *colorArray;
@property (nonatomic)CGFloat heightRatio;
@property (nonatomic)CGFloat widthRatio;

@property (nonatomic)CGFloat startHeightRatio;
@property (nonatomic)CGFloat startWidthRatio;
@property (nonatomic)BOOL fillAllColor;
- (void)redrawView;
@end

NS_ASSUME_NONNULL_END
