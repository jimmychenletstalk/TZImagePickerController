//
//  LTAlbumTableViewCell.h
//  securedcomm
//
//  Created by onelab on 2021/11/30.
//  Copyright © 2021 Jimmy.Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LTGradientView.h"
NS_ASSUME_NONNULL_BEGIN

@interface LTAlbumTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *selectedCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *bottomLabel;
@property (weak, nonatomic) IBOutlet LTGradientView *selectedCountBGView;
@property (weak, nonatomic) IBOutlet UIImageView *albumImageView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;
+ (UINib *)nib;
+ (NSString *)cellReuseIdentifier;
@end

NS_ASSUME_NONNULL_END
