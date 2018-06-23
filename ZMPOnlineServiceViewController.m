//
//  ZMPOnlineServiceViewController.m
//  ZMParentsProject
//
//  Created by James on 2017/8/29.
//  Copyright © 2017年 Sea. All rights reserved.
//

#import "ZMPOnlineServiceViewController.h"

#import "ZMPContactServiceView.h"
#import "ZMPExclusiveView.h"

#import "AlertTool.h"

#import <SobotKit/SobotKit.h>

#import "ZMPOnlineServiceDataController.h"
#import "ZMPWKWebViewViewController.h"

#import "ZMAlertView.h"
#import <IQKeyboardManager/IQKeyboardManager.h>

#import "BigAreaBtn.h"


@interface ZMPOnlineServiceViewController ()
<
    ZCUIChatDelagete
>
@property (nonatomic, assign) BOOL hasExclusiveService;

@property (nonatomic, strong) UIImageView *advertiseImageView;
@property (nonatomic, strong) ZMPContactServiceView *contactView;
@property (nonatomic, strong) ZMPExclusiveView *exclusiveServiceView;

@property (nonatomic, strong) ZMPOnlineServiceDataController *dataController;

@property (nonatomic, strong) id<UIGestureRecognizerDelegate> naviPopDelegate;

@property (nonatomic, weak) ZCUIChatController *chatVC;

@end

@implementation ZMPOnlineServiceViewController
{
    BOOL _saveIQKeyboardManagerEnable;
    BOOL _saveIQKeyboardManagerEnableAutoToolbar;
}

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self recordIQKeyboardStatus];
    [self defaultUIConfig];
    [self requestOnlineServiceInfo];

    self.naviPopDelegate = self.navigationController.interactivePopGestureRecognizer.delegate;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = self.naviPopDelegate;
    [ZMPStatisticsManager beginLogPageView:@"zaixiankefu"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ZMPStatisticsManager endLogPageView:@"zaixiankefu"];
}

#pragma mark - Private Method
- (void)recordIQKeyboardStatus {
    _saveIQKeyboardManagerEnable = [IQKeyboardManager sharedManager].enable;
    _saveIQKeyboardManagerEnableAutoToolbar = [IQKeyboardManager sharedManager].enableAutoToolbar;
}

- (void)recoverIQKeyboardStatus {
    [IQKeyboardManager sharedManager].enable = _saveIQKeyboardManagerEnable;
    [IQKeyboardManager sharedManager].enableAutoToolbar = _saveIQKeyboardManagerEnableAutoToolbar;
}

- (void)defaultUIConfig {
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.navigationItem.title = @"在线客服";
    [self setNavTitle:@""
            imageName:@"register_icon_return"
        directionType:kNavDirectionTypeLeft];
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)UILayout {
    
    CGFloat exclusiveHeight = 152.0;
    
    CGFloat adHeight = 150;
    if (IPHONE_5_5S) {
        adHeight = 128.0;
    }
    
    [self.view addSubview:self.advertiseImageView];
    [self.advertiseImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.equalTo(self.view);
        make.height.equalTo(@(adHeight));
    }];
    
    
    
    WeakSelf(w_self)
    _contactView = [[ZMPContactServiceView alloc] initWithTitle:self.dataController.contactTitle phoneBtnTitle:@"拨打客服电话" consultBtnTitle:@"在线咨询" phoneCallBlock:^{
        [w_self phone];
    } consultCallBlock:^{
        [w_self contactOnline];
    }];
    
    [self.view addSubview:self.contactView];
    [self.contactView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.advertiseImageView.mas_bottom);
        make.left.right.equalTo(self.view);
    }];
    
    
    _exclusiveServiceView = [[ZMPExclusiveView alloc] initWithTeachName:self.dataController.sellerTeacherName phoneBlock:^{
        [w_self exclusivePhone];
    }];
    _exclusiveServiceView.hidden = ![self.dataController hasExclusiveService];
    [self.view addSubview:self.exclusiveServiceView];
    [self.exclusiveServiceView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contactView.mas_bottom);
        make.left.bottom.right.equalTo(self.view);
        make.height.equalTo(@(exclusiveHeight));
    }];
    
    
}

- (NSString *)leaveMsgURLStr {
    
    NSString *parentIdQuery = @"";
    if ([UserWrapper shareInstance].isLogin && [UserWrapper shareInstance].userModel.mobile.length) {
        parentIdQuery = [NSString stringWithFormat:@"%@:%@",[UserWrapper shareInstance].userModel.userId, [[UserWrapper shareInstance].userModel.mobile substringFromIndex:7]];
    }
    
    NSString *studentIdQuery = @"";
    if (self.dataController.studentID.length) {
        studentIdQuery = self.dataController.studentID;
    }
    
    NSString *result = [NSString stringWithFormat:@"%@?clientType=parent&userId=%@&studentUserId=%@", kZMPSobotLeaveMsgURL, parentIdQuery, studentIdQuery];
    
    NSLog(@"leavemsgUrl:%@", result);
    
    return result;
}

- (void)requestOnlineServiceInfo {
    
    WeakSelf(w_self);
    [self preProcessBeforeRequest];
    [self.dataController requestOnlineServiceInfoWithSuccessBlock:^(id _Nullable responseData, NSInteger responseCode, NSString  * _Nullable message) {
        [w_self preProcessWhenSuccess];
        [w_self UILayout];
    } businessFailBlock:^(id  _Nullable responseData, NSInteger responseCode, NSString * _Nullable message) {
        [[iToast makeText:message] show];
        [w_self preProcessWhenFail];
    } netFailBlock:^(NSError * _Nullable error, NSInteger netStatusCode) {
        [w_self preProcessWhenFail];
        [w_self showRequestFailTip];
    }];
}

#pragma mark preprocess
- (void)preProcessBeforeRequest {
    [self showHUD];
}

- (void)preProcessWhenSuccess {
    [self hideHUD];
    [self hideAllTip];
}

- (void)preProcessWhenFail {
    [self hideHUD];
}

#pragma mark operation

- (void)phone {
    
    if (self.dataController.servicePhone.length) {
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",self.dataController.servicePhone]]];
        
    }
    
}

- (void)exclusivePhone {
    [ZMPStatisticsManager event:kZMPEvent_home_kefu_zhuangshu];
    
    if (self.dataController.sellerTeacherMobile.length) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", self.dataController.sellerTeacherMobile]]];
    }
    
}

#pragma mark contact
- (void)contactOnline {
    
    WeakSelf(w_self);
    [IQKeyboardManager sharedManager].enable = NO;
    [IQKeyboardManager sharedManager].enableAutoToolbar = NO;
    
    //联系客服
    ZCKitInfo    *kitInfo = [[ZCKitInfo alloc] init];
    kitInfo.isShowTansfer = YES;
    kitInfo.isCloseAfterEvaluation = YES;//评价完人工是否关闭会话（人工满意度评价后释放会话
    kitInfo.isOpenRecord = YES;//开启语音功能
    kitInfo.titleFont = kZMPFont(16);//导航字体
    kitInfo.listTitleFont = kZMPFont(16);
    kitInfo.chatFont = kZMPFont(14);//聊天字体
    kitInfo.listTimeFont = kZMPFont(12);//时间字体
    kitInfo.backgroundColor = [UIColor colorWithHexString:@"#F0F2F7"];//聊天背景色
    kitInfo.customBannerColor  = [UIColor whiteColor];//导航颜色
    kitInfo.leftChatColor = [UIColor whiteColor];//
    kitInfo.rightChatColor = kZMPMiddleBlack;//
    kitInfo.topViewTextColor  =  [UIColor blackColor];//
    kitInfo.timeTextColor = [UIColor colorWithHexString:@"#333333"];//
    kitInfo.backgroundBottomColor = [UIColor whiteColor];//
    kitInfo.leftChatTextColor = [UIColor colorWithHexString:@"#333333"];//
    kitInfo.rightChatTextColor = [UIColor whiteColor];//
    kitInfo.chatLeftLinkColor = [UIColor colorWithHexString:@"#2385EE"];//聊天里超链接的颜色
    kitInfo.BgTipAirBubblesColor = [UIColor clearColor];//
    kitInfo.socketStatusButtonBgColor  = [UIColor whiteColor];//socket链接状态按钮背景色
    kitInfo.socketStatusButtonTitleColor = [UIColor blackColor];//
    kitInfo.notificationTopViewLabelFont = kZMPFont(16);//
    kitInfo.notificationTopViewLabelColor = [UIColor colorWithHexString:@"#333333"];//
    kitInfo.notificationTopViewBgColor = [UIColor whiteColor];//
    kitInfo.tipLayerTextColor = [UIColor colorWithHexString:@"#333333"];
    kitInfo.commentCommitButtonColor = kZMPMiddleBlack;
    kitInfo.satisfactionSelectedBgColor = kZMPMiddleBlack;
    kitInfo.submitEvaluationColor = [UIColor whiteColor];
    kitInfo.commentOtherButtonBgColor = kZMPMiddleBlack;
    kitInfo.imagePickerTitleColor = kZMPMiddleBlack;
    
    ZCLibInitInfo *initInfo = [ZCLibInitInfo new];
    initInfo.appKey = SobotAppKey;
    
    //test
    if ([UserWrapper shareInstance].isLogin && [UserWrapper shareInstance].userModel.mobile.length) {
        initInfo.userId = [NSString stringWithFormat:@"%@:%@",[UserWrapper shareInstance].userModel.userId, [[UserWrapper shareInstance].userModel.mobile substringFromIndex:7]];
    }
    
    initInfo.phone = [UserWrapper shareInstance].userModel.mobile.length ? [UserWrapper shareInstance].userModel.mobile : @"暂无电话";
    initInfo.skillSetId = SobotServiceGroupID;
    initInfo.skillSetName = SobotServiceGroupName;
    
    
    initInfo.nickName = self.dataController.studentName.length > 0 ? [NSString stringWithFormat:@"%@家长", self.dataController.studentName] : @"掌门家长";
    
    initInfo.userRemark = @"家长端app";
    
    if(self.dataController.studentID.length) {
        initInfo.realName = self.dataController.studentID;
    }
    
    //设置启动参数
    [[ZCLibClient getZCLibClient] setLibInitInfo:initInfo];
    
    [ZCSobot startZCChatView:kitInfo with:self target:self pageBlock:^(ZCUIChatController *object, ZCPageBlockType type) {
        if (type == ZCPageBlockLoadFinish) {

            w_self.chatVC = object;
            
            object.navigationItem.hidesBackButton = YES;
            [object.backButton removeFromSuperview];
            object.backButton = nil;

            //layoutBackBtnInView
            UIView *backContentView = [UIView new];
            [object.topView addSubview:backContentView];
            [backContentView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(object.topView);
                make.left.equalTo(object.topView);
                make.height.equalTo(@(kNavigationBarHeight - kStatusBarHeight));
            }];

            BigAreaBtn *backBtn = [[BigAreaBtn alloc] init];
            [backBtn setImage:[UIImage imageNamed:@"register_icon_return"] forState:UIControlStateNormal];
            [backBtn addTarget:w_self action:@selector(exitContact) forControlEvents:UIControlEventTouchUpInside];


            [backContentView addSubview:backBtn];
            [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(backContentView).with.offset(15);
                make.right.equalTo(backContentView).with.offset(-15);
                make.centerY.equalTo(backContentView);
            }];

        }
    } messageLinkClick:^(NSString *link) {

    }];

}

- (void)exitContact {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Public Method
- (void)requestAgain {
    [self requestOnlineServiceInfo];
}

#pragma mark - Delegate
#pragma ZCUIChatDelagete
- (void)openLeaveMsgClick:(NSString *)tipMsg {
    ZMPWKWebViewViewController *nextVC =  [[ZMPWKWebViewViewController alloc] init];
    [nextVC setNaviTitle:@"留言"];
    [nextVC loadRequest:self.leaveMsgURLStr];
    [self.chatVC.navigationController pushViewController:nextVC animated:YES];
}

#pragma mark - Getter And Setter
- (UIImageView *)advertiseImageView {
    if (!_advertiseImageView) {
        _advertiseImageView = [[UIImageView alloc] init];
        _advertiseImageView.contentMode = UIViewContentModeScaleAspectFill;
        _advertiseImageView.clipsToBounds = YES;
        if (IPHONE_5_5S) {
            _advertiseImageView.image = kImageName(@"service_topposterfor5s");
//            _advertiseImageView.contentMode = UIViewContentModeScaleAspectFit;
        }
        _advertiseImageView.image = kImageName(@"service_icon_entertain");
    }
    return _advertiseImageView;
}


- (ZMPOnlineServiceDataController *)dataController {
    if (!_dataController) {
        _dataController = [[ZMPOnlineServiceDataController alloc] init];
        _dataController.associatedVC = self;
    }
    return _dataController;
}

#pragma mark - Delloc
- (void)dealloc {
    [self recoverIQKeyboardStatus];
}
@end
