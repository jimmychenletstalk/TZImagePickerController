//
//  LTGradientView.h
//  securedcomm
//
//  Created by onelab on 2021/4/29.
//  Copyright © 2021 Jimmy.Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTGradientView : UIView
@property (nonatomic, strong)NSArray *colorArray;
@property (nonatomic)CGFloat heightRatio;
@property (nonatomic)CGFloat widthRatio;

@property (nonatomic)CGFloat startHeightRatio;
@property (nonatomic)CGFloat startWidthRatio;
@property (nonatomic)BOOL fillAllColor;

@property (nonatomic)BOOL clipCorner;
@property (nonatomic)UIRectCorner corners;
@property (nonatomic)CGFloat drawCorner;

- (void)redrawView;
@end

NS_ASSUME_NONNULL_END
