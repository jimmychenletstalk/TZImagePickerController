//
//  LTAlbumTableViewCell.m
//  securedcomm
//
//  Created by onelab on 2021/11/30.
//  Copyright © 2021 Jimmy.Chen. All rights reserved.
//

#import "LTAlbumTableViewCell.h"
#import "UIColor+TZColor.h"
#import "UIImage+TZMaskColor.h"
#import "TZImagePickerController.h"
@implementation LTAlbumTableViewCell
+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
}

+ (NSString *)cellReuseIdentifier
{
    return NSStringFromClass([self class]);
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.topLabel.textColor = [UIColor tzColor_colorWithHex:@"FFFFFF"];
    self.bottomLabel.textColor =  [UIColor tzColor_colorWithHex:@"8D92A6"];
    self.topLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.bottomLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.albumImageView.layer.masksToBounds = YES;
    self.albumImageView.layer.cornerRadius = 4.0f;
    self.albumImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.arrowImageView.image = [[UIImage tz_imageNamedFromMyBundle:@"icon_sign_arrowright"]tz_imageMaskedWithColor:[UIColor tzColor_colorWithHex:@"FFFFFF"]];
    
    self.selectedCountBGView.colorArray = @[[UIColor tzColor_colorWithHex:@"34B7FF"], [UIColor tzColor_colorWithHex:@"00D780"]];
    self.selectedCountBGView.heightRatio = 1;
    self.selectedCountBGView.layer.masksToBounds = YES;
    self.selectedCountBGView.layer.cornerRadius = self.selectedCountBGView.frame.size.height/2;
    self.selectedCountLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.selectedCountLabel.textColor = [UIColor tzColor_colorWithHex:@"FFFFFF"];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.selectedCountBGView.layer.cornerRadius = self.selectedCountBGView.frame.size.height/2;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
