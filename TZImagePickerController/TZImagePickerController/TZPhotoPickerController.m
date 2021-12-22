//
//  TZPhotoPickerController.m
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import "TZPhotoPickerController.h"
#import "TZImagePickerController.h"
#import "TZPhotoPreviewController.h"
#import "TZAssetCell.h"
#import "TZAssetModel.h"
#import "UIView+TZLayout.h"
#import "TZImageManager.h"
#import "TZVideoPlayerController.h"
#import "TZGifPhotoPreviewController.h"
#import "TZLocationManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "TZImageRequestOperation.h"
#import "UIColor+TZColor.h"
#import "UIImage+TZMaskColor.h"
//#import "TZPhotoPickerController+DrawPhoto.h"
//#import "HighlightedButton.h"
//#import "StyleUtil.h"
//#import "OLSCLogManager.h"
#import "LTGradientButton.h"
//@import Masonry;
@interface TZPhotoPickerController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate, PHPhotoLibraryChangeObserver, TZAlbumPickerControllerDelegate> {
    NSMutableArray *_models;
    
    UIView *_bottomToolBar;
    UIButton *_previewButton;
    UIButton *_doneButton;
    LTGradientButton *_sendButton;
    UIButton *_postButton;
    
    UIImageView *_numberImageView;
    UILabel *_numberLabel;
    UIButton *_originalPhotoButton;
    UILabel *_originalPhotoLabel;
    UIView *_divideLine;
    
    BOOL _shouldScrollToBottom;
    BOOL _showTakePhotoBtn;
    
    CGFloat _offsetItemCount;
}
@property CGRect previousPreheatRect;
@property (nonatomic, assign) BOOL isSelectOriginalPhoto;
@property (nonatomic, strong) TZCollectionView *collectionView;
@property (nonatomic, strong) UILabel *noDataLabel;
@property (strong, nonatomic) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) UIImagePickerController *imagePickerVc;
@property (strong, nonatomic) CLLocation *location;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, assign) BOOL isSavingMedia;
@property (nonatomic, assign) BOOL isFetchingMedia;
@property (assign, nonatomic) BOOL tapOnPost;

@property (nonatomic, strong) TZAlbumPickerController *albumPicker;
@end

static CGSize AssetGridThumbnailSize;
static CGFloat itemMargin = 5;

@implementation TZPhotoPickerController

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (UIImagePickerController *)imagePickerVc {
    if (_imagePickerVc == nil) {
        _imagePickerVc = [[UIImagePickerController alloc] init];
        _imagePickerVc.delegate = self;
        // set appearance / 改变相册选择页的导航栏外观
        _imagePickerVc.navigationBar.barTintColor = self.navigationController.navigationBar.barTintColor;
        _imagePickerVc.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
        UIBarButtonItem *tzBarItem, *BarItem;
        if (@available(iOS 9, *)) {
            tzBarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[TZImagePickerController class]]];
            BarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIImagePickerController class]]];
        } else {
            tzBarItem = [UIBarButtonItem appearanceWhenContainedIn:[TZImagePickerController class], nil];
            BarItem = [UIBarButtonItem appearanceWhenContainedIn:[UIImagePickerController class], nil];
        }
        NSDictionary *titleTextAttributes = [tzBarItem titleTextAttributesForState:UIControlStateNormal];
        [BarItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    }
    return _imagePickerVc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    self.isFirstAppear = YES;
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    _isSelectOriginalPhoto = tzImagePickerVc.isSelectOriginalPhoto;
    _shouldScrollToBottom = YES;
    self.view.backgroundColor = [UIColor tzColor_colorWithHex:@"03071a"];

    self.navigationItem.title = @"";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage tz_imageNamedFromMyBundle:@"icon_navigation_close"] style:UIBarButtonItemStylePlain target:tzImagePickerVc action:@selector(cancelButtonClick)];
    
    [self setupNavToAlbum:NO];
    
    _showTakePhotoBtn = _model.isCameraRoll && ((tzImagePickerVc.allowTakePicture && tzImagePickerVc.allowPickingImage) || (tzImagePickerVc.allowTakeVideo && tzImagePickerVc.allowPickingVideo));
    // [self resetCachedAssets];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStatusBarOrientationNotification:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 3;
}

- (void)backView{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showAlbum:(id)sender{
    if (self.albumPicker.view.superview) {
        [self hideAlbum];
    }else{
        if (!self.albumPicker) {
            self.albumPicker = [[TZAlbumPickerController alloc] init];
            self.albumPicker.isFirstAppear = YES;
            self.albumPicker.columnNumber = self.columnNumber;
            self.albumPicker.delegate = self;
        }
        self.albumPicker.tempImagePickerVc = self.navigationController;
        [self.albumPicker configTableView];
        if (!self.albumPicker.view.superview) {
            self.albumPicker.view.frame = CGRectMake(self.collectionView.frame.origin.x, self.collectionView.frame.origin.y - (self.collectionView.frame.size.height+_bottomToolBar.frame.size.height), self.collectionView.frame.size.width, self.collectionView.frame.size.height+_bottomToolBar.frame.size.height);
            [self.view addSubview:self.albumPicker.view];
            //change nav
            [UIView animateWithDuration:0.3 animations:^{
                self.albumPicker.view.frame = CGRectMake(self.collectionView.frame.origin.x, self.collectionView.frame.origin.y, self.collectionView.frame.size.width, self.collectionView.frame.size.height+_bottomToolBar.frame.size.height);
            }];
            [self setupNavToAlbum:YES];
        }
    }
}

- (void)setupNavToAlbum:(BOOL)toAlbum{
    NSTextAttachment *arrowIconAttachment = [[NSTextAttachment alloc] init];
    
    
    arrowIconAttachment.image = toAlbum?[[[UIImage tz_imageNamedFromMyBundle:@"icon_sign_arrowup"]tz_imageMaskedWithColor:[UIColor tzColor_colorWithHex:@"ffffff"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]:[[[UIImage tz_imageNamedFromMyBundle:@"icon_sign_arrowdown"]tz_imageMaskedWithColor:[UIColor tzColor_colorWithHex:@"ffffff"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    NSAttributedString *arrowIconAttachmentString = [NSAttributedString attributedStringWithAttachment:arrowIconAttachment];
    NSAttributedString *labelString = [[NSAttributedString alloc]initWithString:[NSString stringWithFormat:@"%@ ",_model.name?:@""]];
    NSMutableAttributedString *titleString= [[NSMutableAttributedString alloc] init];
    [titleString appendAttributedString:labelString];
    [titleString appendAttributedString:arrowIconAttachmentString];
    [titleString addAttribute:NSBaselineOffsetAttributeName value:@(-1.0f) range:NSMakeRange(titleString.length-1, 1)];
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 271, 24)];
    label.textAlignment = NSTextAlignmentLeft;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont boldSystemFontOfSize:20];
    label.text = _model.name;
    label.attributedText = titleString;
    [label sizeToFit];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showAlbum:)];
    [label addGestureRecognizer:tapGesture];
    label.userInteractionEnabled = YES;
    UIBarButtonItem *labelItem = [[UIBarButtonItem alloc]initWithCustomView:label];
    self.navigationItem.leftBarButtonItem = labelItem;
}

- (void)albumDidSelectAlbum:(TZAlbumModel *)model andColum:(NSInteger)colum{
    self.model = model;
    self.columnNumber = colum;
    [self fetchAssetModels];
    [self hideAlbum];
}

- (void)hideAlbum{
    [UIView animateWithDuration:0.3 animations:^{
        self.albumPicker.view.frame = CGRectMake(self.collectionView.frame.origin.x, self.collectionView.frame.origin.y - (self.collectionView.frame.size.height+_bottomToolBar.frame.size.height), self.collectionView.frame.size.width, self.collectionView.frame.size.height+_bottomToolBar.frame.size.height);
    }completion:^(BOOL finished) {
        [self.albumPicker.view removeFromSuperview];
    }];
    
    [self setupNavToAlbum:NO];
}

- (void)fetchAssetModels {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (_isFirstAppear && !_model.models.count) {
        [tzImagePickerVc showProgressHUD];
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CGFloat systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        if (!tzImagePickerVc.sortAscendingByModificationDate && self->_isFirstAppear && self->_model.isCameraRoll) {
            [[TZImageManager manager] getCameraRollAlbumWithFetchAssets:YES completion:^(TZAlbumModel *model) {
                self->_model = model;
                self->_models = [NSMutableArray arrayWithArray:self->_model.models];
                [self initSubviews];
            }];
        } else if (self->_showTakePhotoBtn || self->_isFirstAppear || !self.model.models || systemVersion >= 14.0) {
            [[TZImageManager manager] getAssetsFromFetchResult:self->_model.result completion:^(NSArray<TZAssetModel *> *models) {
                self->_models = [NSMutableArray arrayWithArray:models];
                [self initSubviews];
            }];
        } else {
            self->_models = [NSMutableArray arrayWithArray:self->_model.models];
            [self initSubviews];
        }
    });
}

- (void)initSubviews {
    dispatch_async(dispatch_get_main_queue(), ^{
        TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
        [tzImagePickerVc hideProgressHUD];
        
        [self checkSelectedModels];
        [self configCollectionView];
        self->_collectionView.hidden = YES;
        [self configBottomToolBar];
        
        [self scrollCollectionViewToBottom];
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    tzImagePickerVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    TZImagePickerController *tzImagePicker = (TZImagePickerController *)self.navigationController;
    if (tzImagePicker && [tzImagePicker isKindOfClass:[TZImagePickerController class]]) {
        return tzImagePicker.statusBarStyle;
    }
    return [super preferredStatusBarStyle];
}

- (void)configCollectionView {
    if (!_collectionView) {
        _layout = [[UICollectionViewFlowLayout alloc] init];
        _collectionView = [[TZCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
        _collectionView.backgroundColor = UIColor.clearColor;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.alwaysBounceHorizontal = NO;
        _collectionView.contentInset = UIEdgeInsetsMake(itemMargin, itemMargin, itemMargin, itemMargin);
        [self.view addSubview:_collectionView];
        [_collectionView registerClass:[TZAssetCell class] forCellWithReuseIdentifier:@"TZAssetCell"];
        [_collectionView registerClass:[TZAssetCameraCell class] forCellWithReuseIdentifier:@"TZAssetCameraCell"];
    } else {
        [_collectionView reloadData];
    }

    
    if (_showTakePhotoBtn) {
        _collectionView.contentSize = CGSizeMake(self.view.tz_width, ((_model.count + self.columnNumber) / self.columnNumber) * self.view.tz_width);
    } else {
        _collectionView.contentSize = CGSizeMake(self.view.tz_width, ((_model.count + self.columnNumber - 1) / self.columnNumber) * self.view.tz_width);
        if (_models.count == 0) {
            _noDataLabel = [UILabel new];
            _noDataLabel.textAlignment = NSTextAlignmentCenter;
            _noDataLabel.text = [NSBundle tz_localizedStringForKey:@"No Photos or Videos"];
            CGFloat rgb = 153 / 256.0;
            _noDataLabel.textColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1.0];
            _noDataLabel.font = [UIFont boldSystemFontOfSize:20];
            [_collectionView addSubview:_noDataLabel];
        } else if (_noDataLabel) {
            [_noDataLabel removeFromSuperview];
            _noDataLabel = nil;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Determine the size of the thumbnails to request from the PHCachingImageManager
    CGFloat scale = 2.0;
    if ([UIScreen mainScreen].bounds.size.width > 600) {
        scale = 1.0;
    }
    CGSize cellSize = ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).itemSize;
    AssetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
    
    if (!_models) {
        [self fetchAssetModels];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.isFirstAppear = NO;
    // [self updateCachedAssets];
}

- (void)configBottomToolBar {
    if (_bottomToolBar) return;
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (!tzImagePickerVc.showSelectBtn) return;
    
    _bottomToolBar = [[UIView alloc] initWithFrame:CGRectZero];
    _bottomToolBar.backgroundColor = [UIColor tzColor_colorWithHex:@"03071a"];
    
    _previewButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_previewButton addTarget:self action:@selector(previewButtonClick) forControlEvents:UIControlEventTouchUpInside];
    _previewButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_previewButton setTitle:tzImagePickerVc.previewBtnTitleStr forState:UIControlStateNormal];
    [_previewButton setTitle:tzImagePickerVc.previewBtnTitleStr forState:UIControlStateDisabled];
    [_previewButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_previewButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    _previewButton.enabled = tzImagePickerVc.selectedModels.count;
    
    if (tzImagePickerVc.allowPickingOriginalPhoto) {
        _originalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _originalPhotoButton.imageEdgeInsets = UIEdgeInsetsMake(0, [TZCommonTools tz_isRightToLeftLayout] ? 10 : -10, 0, 0);
        [_originalPhotoButton addTarget:self action:@selector(originalPhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _originalPhotoButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_originalPhotoButton setTitle:tzImagePickerVc.fullImageBtnTitleStr forState:UIControlStateNormal];
        [_originalPhotoButton setTitle:tzImagePickerVc.fullImageBtnTitleStr forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_originalPhotoButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_originalPhotoButton setImage:tzImagePickerVc.photoOriginDefImage forState:UIControlStateNormal];
        [_originalPhotoButton setImage:tzImagePickerVc.photoOriginSelImage forState:UIControlStateSelected];
        _originalPhotoButton.imageView.clipsToBounds = YES;
        _originalPhotoButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        _originalPhotoButton.selected = _isSelectOriginalPhoto;
        _originalPhotoButton.enabled = tzImagePickerVc.selectedModels.count > 0;
        
        _originalPhotoLabel = [[UILabel alloc] init];
        _originalPhotoLabel.textAlignment = NSTextAlignmentLeft;
        _originalPhotoLabel.font = [UIFont systemFontOfSize:16];
        _originalPhotoLabel.textColor = [UIColor blackColor];
        if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
    }

    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.frame = CGRectMake(0, 0, self.view.tz_width, _bottomToolBar.frame.size.height);
    _doneButton.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
//    _doneButton.highlightedColor = [StyleUtil colorWithHex:D_CANCELBTN_HILIGHT_COLOR];
//    _doneButton.backgroundColor = [StyleUtil colorWithHex:D_CANCELBTN_BG_COLOR];
//    _doneButton.normalColor = [StyleUtil colorWithHex:D_CANCELBTN_NORMAL_COLOR];
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:17];
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_doneButton setTitle:tzImagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
    [_doneButton setTitle:tzImagePickerVc.doneBtnTitleStr forState:UIControlStateDisabled];
    [_doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
    _doneButton.enabled = tzImagePickerVc.selectedModels.count || tzImagePickerVc.alwaysEnableDoneBtn;
    
    _numberImageView = [[UIImageView alloc] initWithImage:tzImagePickerVc.photoNumberIconImage];
    _numberImageView.hidden = tzImagePickerVc.selectedModels.count <= 0;
    _numberImageView.clipsToBounds = YES;
    _numberImageView.contentMode = UIViewContentModeScaleAspectFit;
    _numberImageView.backgroundColor = [UIColor clearColor];
    
    _numberLabel = [[UILabel alloc] init];
    _numberLabel.font = [UIFont systemFontOfSize:17];
    _numberLabel.textColor = UIColor.whiteColor;
    _numberLabel.textAlignment = NSTextAlignmentCenter;
//    _numberLabel.text = [NSString stringWithFormat:@"%zd",tzImagePickerVc.selectedModels.count];
//    _numberLabel.hidden = tzImagePickerVc.selectedModels.count <= 0;
    _numberLabel.hidden = YES;
    _numberLabel.backgroundColor = [UIColor clearColor];
    _numberLabel.text = NSLocalizedString(@"Scroll to bottom", @"Scroll to bottom");
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScrollToDownLabel)];
    _numberLabel.userInteractionEnabled = YES;
    [_numberLabel addGestureRecognizer:tapGesture];
    
    _divideLine = [[UIView alloc] init];
    CGFloat rgb2 = 222 / 255.0;
    _divideLine.backgroundColor = [UIColor colorWithRed:rgb2 green:rgb2 blue:rgb2 alpha:1.0];

    _sendButton = [[LTGradientButton alloc]init];
    _sendButton.layer.masksToBounds = YES;
    _sendButton.layer.cornerRadius = 6;
    _sendButton.colorArray = @[[UIColor tzColor_colorWithHex:@"34B7FF"], [UIColor tzColor_colorWithHex:@"00D780"]];
    _sendButton.heightRatio = 1;
    _sendButton.backgroundColor = [UIColor tzColor_colorWithHex:@"00D790"];
    _sendButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    [_sendButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_sendButton setTitle:[NSBundle tz_localizedStringForKey:@"Done"] forState:UIControlStateNormal];
    [_sendButton setTitle:[NSBundle tz_localizedStringForKey:@"Done"] forState:UIControlStateDisabled];
    [_sendButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [_sendButton setTitleColor:UIColor.whiteColor forState:UIControlStateDisabled];
    _sendButton.enabled = tzImagePickerVc.selectedModels.count || tzImagePickerVc.alwaysEnableDoneBtn;
    
    _postButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _postButton.titleLabel.font = [UIFont systemFontOfSize:17];
    [_postButton addTarget:self action:@selector(postButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_postButton setTitle:NSLocalizedString(@"Post", @"") forState:UIControlStateNormal];
    [_postButton setTitle:NSLocalizedString(@"Post", @"") forState:UIControlStateDisabled];
//    [_postButton setTitleColor:[StyleUtil colorWithHex:D_TOOLBAR_TINT_COLOR] forState:UIControlStateNormal];
//    [_postButton setTitleColor:[StyleUtil colorWithHex:D_COLOR_HEX_BLACK_42] forState:UIControlStateDisabled];
    _postButton.enabled = tzImagePickerVc.selectedModels.count || tzImagePickerVc.alwaysEnableDoneBtn;

    [_bottomToolBar addSubview:_sendButton];
    
    [self.view addSubview:_bottomToolBar];

    if (tzImagePickerVc.photoPickerPageUIConfigBlock) {
        tzImagePickerVc.photoPickerPageUIConfigBlock(_collectionView, _bottomToolBar, _previewButton, _originalPhotoButton, _originalPhotoLabel, _doneButton, _numberImageView, _numberLabel, _divideLine);
    }
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    CGFloat top = 0;
    CGFloat collectionViewHeight = 0;
    CGFloat naviBarHeight = self.navigationController.navigationBar.tz_height;
    BOOL isStatusBarHidden = [UIApplication sharedApplication].isStatusBarHidden;
    BOOL isFullScreen = self.view.tz_height == [UIScreen mainScreen].bounds.size.height;
    CGFloat toolBarHeight = 50 + [TZCommonTools tz_safeAreaInsets].bottom;
    if (self.navigationController.navigationBar.isTranslucent) {
        top = naviBarHeight;
        if (!isStatusBarHidden && isFullScreen) top += [TZCommonTools tz_statusBarHeight];
        collectionViewHeight = tzImagePickerVc.showSelectBtn ? self.view.tz_height - toolBarHeight - top : self.view.tz_height - top;;
    } else {
        collectionViewHeight = tzImagePickerVc.showSelectBtn ? self.view.tz_height - toolBarHeight : self.view.tz_height;
    }
    _collectionView.frame = CGRectMake(0, top, self.view.tz_width, collectionViewHeight);
    _noDataLabel.frame = _collectionView.bounds;
    CGFloat itemWH = (self.view.tz_width - (self.columnNumber + 1) * itemMargin) / self.columnNumber;
    _layout.itemSize = CGSizeMake(itemWH, itemWH);
    _layout.minimumInteritemSpacing = itemMargin;
    _layout.minimumLineSpacing = itemMargin;
    [_collectionView setCollectionViewLayout:_layout];
    if (_offsetItemCount > 0) {
        CGFloat offsetY = _offsetItemCount * (_layout.itemSize.height + _layout.minimumLineSpacing);
        [_collectionView setContentOffset:CGPointMake(0, offsetY)];
    }
    
    CGFloat toolBarTop = 0;
    if (!self.navigationController.navigationBar.isHidden) {
        toolBarTop = self.view.tz_height - toolBarHeight;
    } else {
        CGFloat navigationHeight = naviBarHeight + [TZCommonTools tz_statusBarHeight];
        toolBarTop = self.view.tz_height - toolBarHeight - navigationHeight;
    }
    _bottomToolBar.frame = CGRectMake(0, toolBarTop, self.view.tz_width, toolBarHeight);
    _doneButton.frame = CGRectMake(0, 0, _bottomToolBar.frame.size.width, 50);
    _sendButton.frame = CGRectMake(16, 16, self.view.frame.size.width-32, 44);
    CGFloat previewWidth = [tzImagePickerVc.previewBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]} context:nil].size.width + 2;
    if (!tzImagePickerVc.allowPreview) {
        previewWidth = 0.0;
    }
    _previewButton.frame = CGRectMake(10, 3, previewWidth, 44);
    _previewButton.tz_width = !tzImagePickerVc.showSelectBtn ? 0 : previewWidth;
    if (tzImagePickerVc.allowPickingOriginalPhoto) {
        CGFloat fullImageWidth = [tzImagePickerVc.fullImageBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]} context:nil].size.width;
        _originalPhotoButton.frame = CGRectMake(CGRectGetMaxX(_previewButton.frame), 0, fullImageWidth + 56, 50);
        _originalPhotoLabel.frame = CGRectMake(fullImageWidth + 46, 0, 80, 50);
    }
//    [_doneButton sizeToFit];
//    _doneButton.frame = CGRectMake(self.view.tz_width - _doneButton.tz_width - 12, 0, MAX(44, _doneButton.tz_width), 50);
    _numberImageView.frame = CGRectMake(_doneButton.tz_left - 24 - 5, 13, 24, 24);
    _numberLabel.frame = _numberImageView.frame;
    _divideLine.frame = CGRectMake(0, 0, self.view.tz_width, 1);
    
    [_postButton sizeToFit];
    _postButton.frame = CGRectMake(16, 0, _postButton.frame.size.width, 48.0f);
    
//    [_sendButton sizeToFit];
//    _sendButton.frame = CGRectMake(self.view.tz_width - _sendButton.frame.size.width - 16 , 0, _sendButton.frame.size.width, 48.0f);
    
    [_numberLabel sizeToFit];
    _numberLabel.tz_left = self.view.tz_width/2 - _numberLabel.tz_width/2;
    _numberLabel.tz_top = 48.0f/2 - _numberLabel.tz_height/2;
    
    [TZImageManager manager].columnNumber = [TZImageManager manager].columnNumber;
    [TZImageManager manager].photoWidth = tzImagePickerVc.photoWidth;
    [self.collectionView reloadData];
    
    if (tzImagePickerVc.photoPickerPageDidLayoutSubviewsBlock) {
        tzImagePickerVc.photoPickerPageDidLayoutSubviewsBlock(_collectionView, _bottomToolBar, _previewButton, _originalPhotoButton, _originalPhotoLabel, _doneButton, _numberImageView, _numberLabel, _divideLine);
    }
}

#pragma mark - Notification

- (void)didChangeStatusBarOrientationNotification:(NSNotification *)noti {
    _offsetItemCount = _collectionView.contentOffset.y / (_layout.itemSize.height + _layout.minimumLineSpacing);
}

#pragma mark - Click Event
- (void)navLeftBarButtonClick{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)previewButtonClick {
    TZPhotoPreviewController *photoPreviewVc = [[TZPhotoPreviewController alloc] init];
    [self pushPhotoPrevireViewController:photoPreviewVc needCheckSelectedModels:YES];
}

- (void)originalPhotoButtonClick {
    _originalPhotoButton.selected = !_originalPhotoButton.isSelected;
    _isSelectOriginalPhoto = _originalPhotoButton.isSelected;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    if (_isSelectOriginalPhoto) {
        [self getSelectedPhotoBytes];
    }
}

- (void)postButtonClick{
    self.tapOnPost = YES;
    [self doneButtonClick];
}

- (void)doneButtonClick {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    // 1.6.8 判断是否满足最小必选张数的限制
    if (tzImagePickerVc.minImagesCount && tzImagePickerVc.selectedModels.count < tzImagePickerVc.minImagesCount) {
        NSString *title = [NSString stringWithFormat:[NSBundle tz_localizedStringForKey:@"Select a minimum of %zd photos"], tzImagePickerVc.minImagesCount];
        [tzImagePickerVc showAlertWithTitle:title];
        return;
    }
    
    [tzImagePickerVc showProgressHUD];
    _doneButton.enabled = NO;
    self.isFetchingMedia = YES;
    NSMutableArray *assets = [NSMutableArray array];
    NSMutableArray *photos;
    NSMutableArray *infoArr;
    if (tzImagePickerVc.onlyReturnAsset) { // not fetch image
        for (NSInteger i = 0; i < tzImagePickerVc.selectedModels.count; i++) {
            TZAssetModel *model = tzImagePickerVc.selectedModels[i];
            [assets addObject:model.asset];
        }
    } else { // fetch image
        photos = [NSMutableArray array];
        infoArr = [NSMutableArray array];
        for (NSInteger i = 0; i < tzImagePickerVc.selectedModels.count; i++) { [photos addObject:@1];[assets addObject:@1];[infoArr addObject:@1]; }
        
        __block BOOL havenotShowAlert = YES;
        [TZImageManager manager].shouldFixOrientation = YES;
        __block UIAlertController *alertView;
        for (NSInteger i = 0; i < tzImagePickerVc.selectedModels.count; i++) {
            TZAssetModel *model = tzImagePickerVc.selectedModels[i];
            TZImageRequestOperation *operation = [[TZImageRequestOperation alloc] initWithAsset:model.asset completion:^(UIImage * _Nonnull photo, NSDictionary * _Nonnull info, BOOL isDegraded) {
                if (isDegraded) return;
                if (photo) {
                    if (![TZImagePickerConfig sharedInstance].notScaleImage) {
                        photo = [[TZImageManager manager] scaleImage:photo toSize:CGSizeMake(tzImagePickerVc.photoWidth, (int)(tzImagePickerVc.photoWidth * photo.size.height / photo.size.width))];
                    }
                    [photos replaceObjectAtIndex:i withObject:photo];
                }
                if (info)  [infoArr replaceObjectAtIndex:i withObject:info];
                [assets replaceObjectAtIndex:i withObject:model.asset];
                
                for (id item in photos) { if ([item isKindOfClass:[NSNumber class]]) return; }
                
                if (havenotShowAlert && alertView) {
                    [alertView dismissViewControllerAnimated:YES completion:^{
                        alertView = nil;
                        [self didGetAllPhotos:photos assets:assets infoArr:infoArr];
                    }];
                } else {
                    [self didGetAllPhotos:photos assets:assets infoArr:infoArr];
                }
            } progressHandler:^(double progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
                // 如果图片正在从iCloud同步中,提醒用户
                if (progress < 1 && havenotShowAlert && !alertView) {
                    alertView = [tzImagePickerVc showAlertWithTitle:[NSBundle tz_localizedStringForKey:@"Synchronizing photos from iCloud"]];
                    havenotShowAlert = NO;
                    return;
                }
                if (progress >= 1) {
                    havenotShowAlert = YES;
                }
            }];
            [self.operationQueue addOperation:operation];
        }
    }
    if (tzImagePickerVc.selectedModels.count <= 0 || tzImagePickerVc.onlyReturnAsset) {
        [self didGetAllPhotos:photos assets:assets infoArr:infoArr];
    }
}

- (void)didGetAllPhotos:(NSArray *)photos assets:(NSArray *)assets infoArr:(NSArray *)infoArr {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    [tzImagePickerVc hideProgressHUD];
    _doneButton.enabled = YES;
    self.isFetchingMedia = NO;

    if (tzImagePickerVc.autoDismiss) {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            [self callDelegateMethodWithPhotos:photos assets:assets infoArr:infoArr];
        }];
    } else {
        [self callDelegateMethodWithPhotos:photos assets:assets infoArr:infoArr];
    }
}

- (void)callDelegateMethodWithPhotos:(NSArray *)photos assets:(NSArray *)assets infoArr:(NSArray *)infoArr {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (tzImagePickerVc.allowPickingVideo && tzImagePickerVc.maxImagesCount == 1) {
        if ([[TZImageManager manager] isVideo:[assets firstObject]]) {
            if ([tzImagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingVideo:sourceAssets:)]) {
                [tzImagePickerVc.pickerDelegate imagePickerController:tzImagePickerVc didFinishPickingVideo:[photos firstObject] sourceAssets:[assets firstObject]];
            }
            if (tzImagePickerVc.didFinishPickingVideoHandle) {
                tzImagePickerVc.didFinishPickingVideoHandle([photos firstObject], [assets firstObject]);
            }
            return;
        }
    }
    
    if ([tzImagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:)]) {
        [tzImagePickerVc.pickerDelegate imagePickerController:tzImagePickerVc didFinishPickingPhotos:photos sourceAssets:assets isSelectOriginalPhoto:_isSelectOriginalPhoto];
    }
    if ([tzImagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:infos:)]) {
        [tzImagePickerVc.pickerDelegate imagePickerController:tzImagePickerVc didFinishPickingPhotos:photos sourceAssets:assets isSelectOriginalPhoto:_isSelectOriginalPhoto infos:infoArr];
    }
    if (tzImagePickerVc.didFinishPickingPhotosHandle) {
        tzImagePickerVc.didFinishPickingPhotosHandle(photos,assets,_isSelectOriginalPhoto);
    }
    if (tzImagePickerVc.didFinishPickingPhotosWithInfosHandle) {
        tzImagePickerVc.didFinishPickingPhotosWithInfosHandle(photos,assets,_isSelectOriginalPhoto,infoArr);
    }
    if (tzImagePickerVc.didFinishPickingPhotosWithInfosHandleUsePostButton) {
        tzImagePickerVc.didFinishPickingPhotosWithInfosHandleUsePostButton(photos,assets,_isSelectOriginalPhoto,infoArr,self.tapOnPost);
    }
}

#pragma mark - UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_showTakePhotoBtn) {
        return _models.count + 1;
    }
    return _models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // the cell lead to take a picture / 去拍照的cell
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (((tzImagePickerVc.sortAscendingByModificationDate && indexPath.item >= _models.count) || (!tzImagePickerVc.sortAscendingByModificationDate && indexPath.item == 0)) && _showTakePhotoBtn) {
        TZAssetCameraCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZAssetCameraCell" forIndexPath:indexPath];
        cell.imageView.image = tzImagePickerVc.takePictureImage;
        if ([tzImagePickerVc.takePictureImageName isEqualToString:@"takePicture80"]) {
            cell.imageView.contentMode = UIViewContentModeCenter;
            CGFloat rgb = 223 / 255.0;
            cell.imageView.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1.0];
        } else {
            cell.imageView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.500];
        }
        return cell;
    }
    // the cell dipaly photo or video / 展示照片或视频的cell
    TZAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZAssetCell" forIndexPath:indexPath];
    cell.allowPickingMultipleVideo = tzImagePickerVc.allowPickingMultipleVideo;
    cell.photoDefImage = tzImagePickerVc.photoDefImage;
    cell.photoSelImage = tzImagePickerVc.photoSelImage;
    cell.assetCellDidSetModelBlock = tzImagePickerVc.assetCellDidSetModelBlock;
    cell.assetCellDidLayoutSubviewsBlock = tzImagePickerVc.assetCellDidLayoutSubviewsBlock;
    TZAssetModel *model;
    if (tzImagePickerVc.sortAscendingByModificationDate || !_showTakePhotoBtn) {
        model = _models[indexPath.item];
    } else {
        model = _models[indexPath.item - 1];
    }
    cell.allowPickingGif = tzImagePickerVc.allowPickingGif;
    cell.model = model;
    if (model.isSelected && tzImagePickerVc.showSelectedIndex) {
        cell.index = [tzImagePickerVc.selectedAssetIds indexOfObject:model.asset.localIdentifier] + 1;
    }
    cell.showSelectBtn = tzImagePickerVc.showSelectBtn;
    cell.allowPreview = tzImagePickerVc.allowPreview;
    
    if (tzImagePickerVc.selectedModels.count >= tzImagePickerVc.maxImagesCount && tzImagePickerVc.showPhotoCannotSelectLayer && !model.isSelected) {
        cell.cannotSelectLayerButton.backgroundColor = tzImagePickerVc.cannotSelectLayerColor;
        cell.cannotSelectLayerButton.hidden = NO;
    } else {
        cell.cannotSelectLayerButton.hidden = YES;
    }
    
    __weak typeof(cell) weakCell = cell;
    __weak typeof(self) weakSelf = self;
    __weak typeof(_numberImageView.layer) weakLayer = _numberImageView.layer;
    cell.didSelectPhotoBlock = ^(BOOL isSelected) {
        __strong typeof(weakCell) strongCell = weakCell;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        __strong typeof(weakLayer) strongLayer = weakLayer;
        TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)strongSelf.navigationController;
        // 1. cancel select / 取消选择
        if (isSelected) {
            strongCell.selectPhotoButton.selected = NO;
            model.isSelected = NO;
            NSArray *selectedModels = [NSArray arrayWithArray:tzImagePickerVc.selectedModels];
            for (TZAssetModel *model_item in selectedModels) {
                if ([model.asset.localIdentifier isEqualToString:model_item.asset.localIdentifier]) {
                    [tzImagePickerVc removeSelectedModel:model_item];
                    [strongSelf setAsset:model_item.asset isSelect:NO];
                    break;
                }
            }
            [strongSelf refreshBottomToolBarStatus];
            if (tzImagePickerVc.showSelectedIndex || tzImagePickerVc.showPhotoCannotSelectLayer) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TZ_PHOTO_PICKER_RELOAD_NOTIFICATION" object:strongSelf.navigationController];
            }
            [UIView showOscillatoryAnimationWithLayer:strongLayer type:TZOscillatoryAnimationToSmaller];
            if (strongCell.model.iCloudFailed) {
                NSString *title = [NSBundle tz_localizedStringForKey:@"iCloud sync failed"];
                [tzImagePickerVc showAlertWithTitle:title];
            }
        } else {
            // 2. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
            if (tzImagePickerVc.selectedModels.count < tzImagePickerVc.maxImagesCount) {
                if ([[TZImageManager manager] isAssetCannotBeSelected:model.asset]) {
                    return;
                }
                if (!tzImagePickerVc.allowPreview) {
                    BOOL shouldDone = tzImagePickerVc.maxImagesCount == 1;
                    if (!tzImagePickerVc.allowPickingMultipleVideo && (model.type == TZAssetModelMediaTypeVideo || model.type == TZAssetModelMediaTypePhotoGif)) {
                        shouldDone = YES;
                    }
                    if (shouldDone) {
                        model.isSelected = YES;
                        [tzImagePickerVc addSelectedModel:model];
                        [strongSelf doneButtonClick];
                        return;
                    }
                }
                strongCell.selectPhotoButton.selected = YES;
                model.isSelected = YES;
                [tzImagePickerVc addSelectedModel:model];
                if (tzImagePickerVc.showSelectedIndex || tzImagePickerVc.showPhotoCannotSelectLayer) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"TZ_PHOTO_PICKER_RELOAD_NOTIFICATION" object:strongSelf.navigationController];
                }
                [strongSelf setAsset:model.asset isSelect:YES];
                [strongSelf refreshBottomToolBarStatus];
                [UIView showOscillatoryAnimationWithLayer:strongLayer type:TZOscillatoryAnimationToSmaller];
            } else {
                NSString *title;
                if (tzImagePickerVc.maxImagesAlertString) {
                    title = tzImagePickerVc.maxImagesAlertString;
                }else{
                    title = [NSString stringWithFormat:[NSBundle tz_localizedStringForKey:@"Select a maximum of %zd photos"], tzImagePickerVc.maxImagesCount];
                }
                [tzImagePickerVc showAlertWithTitle:title];
            }
        }
    };
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // take a photo / 去拍照
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (((tzImagePickerVc.sortAscendingByModificationDate && indexPath.item >= _models.count) || (!tzImagePickerVc.sortAscendingByModificationDate && indexPath.item == 0)) && _showTakePhotoBtn)  {
        [self takePhoto]; return;
    }
    // preview phote or video / 预览照片或视频
    NSInteger index = indexPath.item;
    if (!tzImagePickerVc.sortAscendingByModificationDate && _showTakePhotoBtn) {
        index = indexPath.item - 1;
    }
    TZAssetModel *model = _models[index];
    if (model.type == TZAssetModelMediaTypeVideo && !tzImagePickerVc.allowPickingMultipleVideo) {
        if (tzImagePickerVc.selectedModels.count > 0) {
            TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
            [imagePickerVc showAlertWithTitle:NSLocalizedString(@"You cannot select a video while selecting pictures.", @"")];
        } else {
            TZVideoPlayerController *videoPlayerVc = [[TZVideoPlayerController alloc] init];
            videoPlayerVc.model = model;
            [self.navigationController pushViewController:videoPlayerVc animated:YES];
        }
    } else if (model.type == TZAssetModelMediaTypePhotoGif && tzImagePickerVc.allowPickingGif && !tzImagePickerVc.allowPickingMultipleVideo) {
        if (tzImagePickerVc.selectedModels.count > 0) {
            TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
            [imagePickerVc showAlertWithTitle:[NSBundle tz_localizedStringForKey:@"Can not choose both photo and GIF"]];
        } else {
            TZGifPhotoPreviewController *gifPreviewVc = [[TZGifPhotoPreviewController alloc] init];
            gifPreviewVc.model = model;
            [self.navigationController pushViewController:gifPreviewVc animated:YES];
        }
    } else {
        if (tzImagePickerVc.useDrawImageMode) {
//            __weak typeof(self)weakSelf = self;
//            [self goToMWPhotoImageEditViewController:model
//                                       canAddCaption:tzImagePickerVc.canAddCaption
//                                         andCallBack:^(UIImage * _Nonnull editDoneImage, NSString *msg) {
//                __strong typeof(weakSelf)strongSelf = weakSelf;
//                TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)strongSelf.navigationController;
//                [tzImagePickerVc cancelButtonClick];
//
//                if (tzImagePickerVc.didFinishPickingPhotoWithMsgHandle) {
//                    tzImagePickerVc.didFinishPickingPhotoWithMsgHandle(editDoneImage, msg);
//                }else{
//                    if (tzImagePickerVc.didFinishPickingPhotosHandle) {
//                        tzImagePickerVc.didFinishPickingPhotosHandle(@[editDoneImage], nil, false);
//                    }
//                }
//            }];
        }else{
            TZPhotoPreviewController *photoPreviewVc = [[TZPhotoPreviewController alloc] init];
            photoPreviewVc.currentIndex = index;
            photoPreviewVc.models = _models;
            [self pushPhotoPrevireViewController:photoPreviewVc];
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // [self updateCachedAssets];
    [self updateGoDownButton];
}

#pragma mark - Go Bottom
- (void)updateGoDownButton{
    BOOL hide = [self checkNowIsInBottom];
    _numberLabel.hidden = hide;
}

-(BOOL)checkNowIsInBottom{
    float bottomEdge = _collectionView.contentOffset.y + _collectionView.frame.size.height;
    bottomEdge = bottomEdge - _collectionView.contentInset.bottom;
    if (bottomEdge >= (_collectionView.contentSize.height - 44)) {
        return YES;
    }else{
        return NO;
    }
}


#pragma mark - Private Method

/// 拍照按钮点击事件
- (void)takePhoto {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if ((authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)) {
        
        // 无权限 做一个友好的提示
        NSString *appName = [TZCommonTools tz_getAppName];

        NSString *title = [NSBundle tz_localizedStringForKey:@"Can not use camera"];
        NSString *message = [NSString stringWithFormat:[NSBundle tz_localizedStringForKey:@"Please allow %@ to access your camera in \"Settings -> Privacy -> Camera\""],appName];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:[NSBundle tz_localizedStringForKey:@"Cancel"] style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAct];
        UIAlertAction *settingAct = [UIAlertAction actionWithTitle:[NSBundle tz_localizedStringForKey:@"Setting"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }];
        [alertController addAction:settingAct];
        [self.navigationController presentViewController:alertController animated:YES completion:nil];
    } else if (authStatus == AVAuthorizationStatusNotDetermined) {
        // fix issue 466, 防止用户首次拍照拒绝授权时相机页黑屏
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self pushImagePickerController];
                });
            }
        }];
    } else {
        [self pushImagePickerController];
    }
}

// 调用相机
- (void)pushImagePickerController {
    // 提前定位
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (tzImagePickerVc.allowCameraLocation) {
        __weak typeof(self) weakSelf = self;
        [[TZLocationManager manager] startLocationWithSuccessBlock:^(NSArray<CLLocation *> *locations) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.location = [locations firstObject];
        } failureBlock:^(NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.location = nil;
        }];
    }
    
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isSourceTypeAvailable: sourceType]) {
        self.imagePickerVc.sourceType = sourceType;
        NSMutableArray *mediaTypes = [NSMutableArray array];
        if (tzImagePickerVc.allowTakePicture) {
            [mediaTypes addObject:(NSString *)kUTTypeImage];
        }
        if (tzImagePickerVc.allowTakeVideo) {
            [mediaTypes addObject:(NSString *)kUTTypeMovie];
            self.imagePickerVc.videoMaximumDuration = tzImagePickerVc.videoMaximumDuration;
        }
        self.imagePickerVc.mediaTypes= mediaTypes;
        if (tzImagePickerVc.uiImagePickerControllerSettingBlock) {
            tzImagePickerVc.uiImagePickerControllerSettingBlock(_imagePickerVc);
        }
        [self presentViewController:_imagePickerVc animated:YES completion:nil];
    } else {
        NSLog(@"模拟器中无法打开照相机,请在真机中使用");
    }
}

- (void)refreshBottomToolBarStatus {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    _previewButton.enabled = tzImagePickerVc.selectedModels.count > 0;
    _doneButton.enabled = tzImagePickerVc.selectedModels.count > 0 || tzImagePickerVc.alwaysEnableDoneBtn;
    _sendButton.enabled = _doneButton.enabled;
    _postButton.enabled = _doneButton.enabled;
//    if (tzImagePickerVc.selectedModels.count > 0) {
//        _doneButton.highlightedColor = [StyleUtil colorWithHex:D_SAVEBTN_HILIGHT_COLOR];
//        _doneButton.backgroundColor = [StyleUtil colorWithHex:D_SAVEBTN_BG_COLOR];
//        _doneButton.normalColor = [StyleUtil colorWithHex:D_SAVEBTN_NORMAL_COLOR];
//
//    }else{
//        _doneButton.highlightedColor = [StyleUtil colorWithHex:D_CANCELBTN_HILIGHT_COLOR];
//        _doneButton.backgroundColor = [StyleUtil colorWithHex:D_CANCELBTN_BG_COLOR];
//        _doneButton.normalColor = [StyleUtil colorWithHex:D_CANCELBTN_NORMAL_COLOR];
//    }
    [_doneButton setTitle:[NSString stringWithFormat:@"%@ (%zd)",tzImagePickerVc.doneBtnTitleStr ,tzImagePickerVc.selectedModels.count] forState:UIControlStateNormal];
    
    _numberImageView.hidden = tzImagePickerVc.selectedModels.count <= 0;
//    _numberLabel.hidden = tzImagePickerVc.selectedModels.count <= 0;
//    _numberLabel.text = [NSString stringWithFormat:@"%zd",tzImagePickerVc.selectedModels.count];
//    _numberLabel.hidden = YES;
    
    _originalPhotoButton.enabled = tzImagePickerVc.selectedModels.count > 0;
    _originalPhotoButton.selected = (_isSelectOriginalPhoto && _originalPhotoButton.enabled);
    _originalPhotoLabel.hidden = (!_originalPhotoButton.isSelected);
    if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
    
    if (tzImagePickerVc.photoPickerPageDidRefreshStateBlock) {
        tzImagePickerVc.photoPickerPageDidRefreshStateBlock(_collectionView, _bottomToolBar, _previewButton, _originalPhotoButton, _originalPhotoLabel, _doneButton, _numberImageView, _numberLabel, _divideLine);;
    }
}

- (void)pushPhotoPrevireViewController:(TZPhotoPreviewController *)photoPreviewVc {
    [self pushPhotoPrevireViewController:photoPreviewVc needCheckSelectedModels:NO];
}

- (void)pushPhotoPrevireViewController:(TZPhotoPreviewController *)photoPreviewVc needCheckSelectedModels:(BOOL)needCheckSelectedModels {
    __weak typeof(self) weakSelf = self;
    photoPreviewVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
    [photoPreviewVc setBackButtonClickBlock:^(BOOL isSelectOriginalPhoto) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.isSelectOriginalPhoto = isSelectOriginalPhoto;
        if (needCheckSelectedModels) {
            [strongSelf checkSelectedModels];
        }
        [strongSelf.collectionView reloadData];
        [strongSelf refreshBottomToolBarStatus];
    }];
    [photoPreviewVc setDoneButtonClickBlock:^(BOOL isSelectOriginalPhoto) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.isSelectOriginalPhoto = isSelectOriginalPhoto;
        [strongSelf doneButtonClick];
    }];
    [photoPreviewVc setDoneButtonClickBlockCropMode:^(UIImage *cropedImage, id asset) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf didGetAllPhotos:@[cropedImage] assets:@[asset] infoArr:nil];
    }];
    [self.navigationController pushViewController:photoPreviewVc animated:YES];
}

- (void)getSelectedPhotoBytes {
    // 越南语 && 5屏幕时会显示不下，暂时这样处理
    if ([[TZImagePickerConfig sharedInstance].preferredLanguage isEqualToString:@"vi"] && self.view.tz_width <= 320) {
        return;
    }
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    [[TZImageManager manager] getPhotosBytesWithArray:imagePickerVc.selectedModels completion:^(NSString *totalBytes) {
        self->_originalPhotoLabel.text = [NSString stringWithFormat:@"(%@)",totalBytes];
    }];
}

- (void)tapScrollToDownLabel{
    _shouldScrollToBottom = YES;
    [self scrollCollectionViewToBottom];
    [self updateGoDownButton];
}

- (void)scrollCollectionViewToBottom {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (_shouldScrollToBottom && _models.count > 0) {
        NSInteger item = 0;
        if (tzImagePickerVc.sortAscendingByModificationDate) {
            item = _models.count - 1;
            if (_showTakePhotoBtn) {
                item += 1;
            }
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self->_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
            //多執行一次 確保滾到底
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self->_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
            });
            self->_shouldScrollToBottom = NO;
            self->_collectionView.hidden = NO;
        });
    } else {
        _collectionView.hidden = NO;
    }
}

- (void)checkSelectedModels {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    NSArray *selectedModels = tzImagePickerVc.selectedModels;
    NSMutableSet *selectedAssets = [NSMutableSet setWithCapacity:selectedModels.count];
    for (TZAssetModel *model in selectedModels) {
        [selectedAssets addObject:model.asset];
    }
    for (TZAssetModel *model in _models) {
        model.isSelected = NO;
        if ([selectedAssets containsObject:model.asset]) {
            model.isSelected = YES;
        }
    }
}

/// 选中/取消选中某张照片
- (void)setAsset:(PHAsset *)asset isSelect:(BOOL)isSelect {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (isSelect && [tzImagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didSelectAsset:photo:isSelectOriginalPhoto:)]) {
        [self callDelegate:asset isSelect:YES];
    }
    if (!isSelect && [tzImagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didDeselectAsset:photo:isSelectOriginalPhoto:)]) {
        [self callDelegate:asset isSelect:NO];
    }
}

/// 调用选中/取消选中某张照片的代理方法
- (void)callDelegate:(PHAsset *)asset isSelect:(BOOL)isSelect {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    __weak typeof(self) weakSelf = self;
    __weak typeof(tzImagePickerVc) weakImagePickerVc= tzImagePickerVc;
    [[TZImageManager manager] getPhotoWithAsset:asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        if (isDegraded) return;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        __strong typeof(weakImagePickerVc) strongImagePickerVc = weakImagePickerVc;
        if (isSelect) {
            [strongImagePickerVc.pickerDelegate imagePickerController:strongImagePickerVc didSelectAsset:asset photo:photo isSelectOriginalPhoto:strongSelf.isSelectOriginalPhoto];
        } else {
            [strongImagePickerVc.pickerDelegate imagePickerController:strongImagePickerVc didDeselectAsset:asset photo:photo isSelectOriginalPhoto:strongSelf.isSelectOriginalPhoto];
        }
    }];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
        [imagePickerVc showProgressHUD];
        UIImage *photo = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSDictionary *meta = [info objectForKey:UIImagePickerControllerMediaMetadata];
        if (photo) {
            self.isSavingMedia = YES;
            [[TZImageManager manager] savePhotoWithImage:photo meta:meta location:self.location completion:^(PHAsset *asset, NSError *error){
                self.isSavingMedia = NO;
                if (!error && asset) {
                    [self addPHAsset:asset];
                } else {
                    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
                    [tzImagePickerVc hideProgressHUD];
                }
            }];
            self.location = nil;
        }
    } else if ([type isEqualToString:@"public.movie"]) {
        TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
        [imagePickerVc showProgressHUD];
        NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
        if (videoUrl) {
            self.isSavingMedia = YES;
            [[TZImageManager manager] saveVideoWithUrl:videoUrl location:self.location completion:^(PHAsset *asset, NSError *error) {
                self.isSavingMedia = NO;
                if (!error && asset) {
                    [self addPHAsset:asset];
                } else {
                    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
                    [tzImagePickerVc hideProgressHUD];
                }
            }];
            self.location = nil;
        }
    }
}

- (void)addPHAsset:(PHAsset *)asset {
    TZAssetModel *assetModel = [[TZImageManager manager] createModelWithAsset:asset];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    [tzImagePickerVc hideProgressHUD];
    if (tzImagePickerVc.sortAscendingByModificationDate) {
        [_models addObject:assetModel];
    } else {
        [_models insertObject:assetModel atIndex:0];
    }
    
    if (tzImagePickerVc.maxImagesCount <= 1) {
        if (tzImagePickerVc.allowCrop && asset.mediaType == PHAssetMediaTypeImage) {
            TZPhotoPreviewController *photoPreviewVc = [[TZPhotoPreviewController alloc] init];
            if (tzImagePickerVc.sortAscendingByModificationDate) {
                photoPreviewVc.currentIndex = _models.count - 1;
            } else {
                photoPreviewVc.currentIndex = 0;
            }
            photoPreviewVc.models = _models;
            [self pushPhotoPrevireViewController:photoPreviewVc];
        } else if (tzImagePickerVc.selectedModels.count < 1) {
            [tzImagePickerVc addSelectedModel:assetModel];
            [self doneButtonClick];
        }
        return;
    }
    
    if (tzImagePickerVc.selectedModels.count < tzImagePickerVc.maxImagesCount) {
        if (assetModel.type == TZAssetModelMediaTypeVideo && !tzImagePickerVc.allowPickingMultipleVideo) {
            // 不能多选视频的情况下，不选中拍摄的视频
        } else {
            if ([[TZImageManager manager] isAssetCannotBeSelected:assetModel.asset]) {
                return;
            }
            assetModel.isSelected = YES;
            [tzImagePickerVc addSelectedModel:assetModel];
            [self refreshBottomToolBarStatus];
        }
    }
    _collectionView.hidden = YES;
    [_collectionView reloadData];
    
    _shouldScrollToBottom = YES;
    [self scrollCollectionViewToBottom];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // NSLog(@"%@ dealloc",NSStringFromClass(self.class));
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    if (self.isSavingMedia || self.isFetchingMedia) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.model refreshFetchResult];
        [self fetchAssetModels];
    });
}

#pragma mark - Asset Caching

- (void)resetCachedAssets {
    [[TZImageManager manager].cachingImageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets {
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect.
    CGRect preheatRect = _collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));
    
    /*
     Check if the collection view is showing an area that is significantly
     different to the last preheated area.
     */
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta > CGRectGetHeight(_collectionView.bounds) / 3.0f) {
        
        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self aapl_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        } addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self aapl_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        // Update the assets the PHCachingImageManager is caching.
        [[TZImageManager manager].cachingImageManager startCachingImagesForAssets:assetsToStartCaching
                                                                       targetSize:AssetGridThumbnailSize
                                                                      contentMode:PHImageContentModeAspectFill
                                                                          options:nil];
        [[TZImageManager manager].cachingImageManager stopCachingImagesForAssets:assetsToStopCaching
                                                                      targetSize:AssetGridThumbnailSize
                                                                     contentMode:PHImageContentModeAspectFill
                                                                         options:nil];
        
        // Store the preheat rect to compare against in the future.
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler {
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths {
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.item < _models.count) {
            TZAssetModel *model = _models[indexPath.item];
            [assets addObject:model.asset];
        }
    }
    
    return assets;
}

- (NSArray *)aapl_indexPathsForElementsInRect:(CGRect)rect {
    NSArray *allLayoutAttributes = [_collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (allLayoutAttributes.count == 0) { return nil; }
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

#pragma clang diagnostic pop

@end



@implementation TZCollectionView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    if ([view isKindOfClass:[UIControl class]]) {
        return YES;
    }
    return [super touchesShouldCancelInContentView:view];
}

@end
