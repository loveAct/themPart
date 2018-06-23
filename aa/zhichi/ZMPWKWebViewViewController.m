//
//  ZMPWKWebViewViewController.m
//  ZMParentsProject
//
//  Created by Sea on 2017/9/22.
//  Copyright © 2017年 Sea. All rights reserved.
//

#import "ZMPWKWebViewViewController.h"

#import <WebKit/WebKit.h>

#import "GloabNotificationName.h"
#import "ZMPBaseNavigationViewController.h"

#import "ZMPRouterManage.h"

#define kZMPJSInteractiveMethodBackHome      @"backHome"
#define kZMPJSInteractiveMethodConfig        @"onCall"
#define kZMPJSInteractiveMethodGotoLogin     @"goLogin"
#define kZMPJSInteractiveMethodShowGifHud    @"showGifHud"
#define kZMPJSInteractiveMethodHideGifHud    @"hideGifHud"
#define kZMPJSInteractiveMethodGoNative      @"goNative"
#define kZMPJSInteractiveMethodGetMobile     @"getMobile"
#define kZMPJSInteractiveMethodSharePosters  @"sharePosters"

#define kZMPBackGray      @"register_icon_return"
#define kZMPShareGray     @"register_icon_reprint"

#define kZMPBackWihte     @"back_white"
#define kZMPShareWhite    @"icon_share_white"

typedef NS_ENUM(NSInteger, kJSInteractiveOperationType) {
    kJSInteractiveOperationTypeDefault,
    kJSInteractiveOperationTypeUpdateSession,
    kJSInteractiveOperationTypeSetMobile,
};


@implementation ZMPJSShareObject

@end

@implementation ZMPJSInteractObject
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
             @"shareObject" : @"share",
             };
}

@end

@interface ZMPWKWebViewViewController ()
<
    ZYJRequestTipViewDelegate
>
@property (nonatomic, strong) ZMPJSInteractObject *inteactObject;
@property (nonatomic, assign) kJSInteractiveOperationType callJSType;
@property (nonatomic, assign) BOOL needLoginWhenBack;

@property (nonatomic, assign) BOOL backHome;
@end

@implementation ZMPWKWebViewViewController
{
    BOOL _daZhuanPanExecuted;
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [self registerNoti];
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //avoid js interactive is done before the ui draw finished
    [self refreshNaviBarUI];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [((ZMPBaseNavigationViewController *)self.navigationController) recoverOriginalDefaultConfig];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if ([self.webDelegate respondsToSelector:@selector(webViewWillDismissed:)]) {
        [self.webDelegate webViewWillDismissed:self];
    }
}

#pragma mark - System Method
- (UIStatusBarStyle)preferredStatusBarStyle {
    
    if (self.inteactObject.isBlack) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
    
}

#pragma mark - Private Method

- (void)registerNoti {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLogin:) name:kNSNotification_LoginIn_Name object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelLogin:) name:kNSNotification_Cancel_Name object:nil];
}


#pragma mark Method called by JS
- (void)executJSConfig:(id)data {
    self.inteactObject = [ZMPJSInteractObject yy_modelWithJSON:data];
    [self refreshNaviBarUI];
}

- (void)goNative:(id)jsData {
    
    if(![UserWrapper shareInstance].userModel.hasChild) {
        [[iToast makeText:@"暂无孩子，请绑定"] show];
        return;
    }
    
    [[ZMPRouterManage sharedManager] handleURL:[jsData objectForKey:@"routerUrl"]];
}

- (void)getMobile {
    self.callJSType = kJSInteractiveOperationTypeSetMobile;
    if ([UserWrapper shareInstance].isLogin) {
        [self setMobile];
    }
    else {
        self.needLoginWhenBack = YES;
        [self jumpLoginViewController];
    }
}

- (void)recommendShare:(id)data {
    
    NSDictionary *sourceDic;
    if ([data isKindOfClass:[NSDictionary class]]) {
        sourceDic = data;
    }
    
    NSInteger shareType = 0;
    
    NSMutableDictionary *realShareDic  = [NSMutableDictionary dictionary];
    realShareDic[kZMPShareThumbnail]   = sourceDic[@"imgUrl"];
    realShareDic[@"recommendFriend"]   = @(YES);
    if ([sourceDic objectForKey:@"shareType"]) {
        shareType = [[sourceDic objectForKey:@"shareType"] integerValue];
    }
    
    ZMPSharePlatformType  sharePlatformType;
    switch (shareType) {
        case 0:
            sharePlatformType = ZMPSharePlatformTypeWeiXin;
            break;
        case 1:
            sharePlatformType = ZMPSharePlatformTypeWeiXinFriend;
            break;
        case 2:
            sharePlatformType = ZMPSharePlatformTypeSina;
            break;
        case 3:
            sharePlatformType = ZMPSharePlatformTypeQQ;
            break;
            
        default:
            sharePlatformType = ZMPSharePlatformTypeWeiXin;
            break;
    }
    
    
    [[ZMPShareManager sharedManager] shareWithPlatformType:sharePlatformType data:realShareDic];
}


#pragma mark  Local Call JS
- (void)updateHtmlSession {
    
    if (self.callJSType == kJSInteractiveOperationTypeUpdateSession) {
        
        NSString *jsStr = [NSString stringWithFormat:@"updateSession(\"%@\")", [UserWrapper shareInstance].sectionID];
        
        [self evaluateJavaScript:jsStr completionHandler:^(id  _Nullable result, NSError * _Nullable error) {
            if (error) {
                NSLog(@"更新htmlSesssion失败");
            }
        }];
        
        self.callJSType = kJSInteractiveOperationTypeDefault;
    }
    
}

- (void)setMobile {
    
    if (self.callJSType == kJSInteractiveOperationTypeSetMobile) {

        NSString *jsStr = [NSString stringWithFormat:@"setMobile(\"%@\")", [UserWrapper shareInstance].userModel.mobile];

        [self evaluateJavaScript:jsStr completionHandler:^(id  _Nullable result, NSError * _Nullable error) {
            if (error) {
                NSLog(@"设置mobile失败");
            }
        }];

        self.callJSType = kJSInteractiveOperationTypeDefault;
    }
    
}

#pragma mark UI
- (void)refreshNaviBarUI {
    
    if (!self.inteactObject) {
        return;
    }
    
    self.navigationItem.title = self.inteactObject.setTitle;
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHexString:self.inteactObject.setColor]]
                                                  forBarMetrics:UIBarMetricsDefault];
    
    if (self.inteactObject.hasShare) {
        [self setNavTitle:@""
                imageName:@"register_icon_reprint"
            directionType:kNavDirectionTypeRight];
        
        if (self.inteactObject.isBlack) {
            [self setNavTitle:@""
                    imageName:kZMPShareWhite
                directionType:kNavDirectionTypeRight];
        }
        else {
            [self setNavTitle:@""
                    imageName:kZMPShareGray
                directionType:kNavDirectionTypeRight];
        }
        
    }
    else {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    if (self.inteactObject.isBlack) {
        [(ZMPBaseNavigationViewController *)self.navigationController updateNaviBarBottomBlackStyle];
        [self setNavTitle:@""
                imageName:kZMPBackWihte
            directionType:kNavDirectionTypeLeft];
        
        
    }
    else {
        [(ZMPBaseNavigationViewController *)self.navigationController recoverOriginalDefaultConfig];
        [self setNavTitle:@""
                imageName:kZMPBackGray
            directionType:kNavDirectionTypeLeft];
        
    }
    
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark Noti
- (void)userLogin:(NSNotification *)noti {
    [self updateHtmlSession];
    [self setMobile];
}

- (void)cancelLogin:(NSNotification *)noti {
    [self judgeLoginStatus];
}

#pragma mark Event Statistics
- (void)shareModuleStatistics {
    if ([self.inteactObject.shareObject.shareType isEqualToString:@"parent_share_grow_report"]) {//成长报告
        [ZMPStatisticsManager event:kZMPEvent_study_chengzhang_fengxiang];
    }
    else if ([self.inteactObject.shareObject.shareType isEqualToString:@"parent_share_score_report"]) {//成绩分析
        [ZMPStatisticsManager event:kZMPEvent_study_chengjifengxi_fengxiang];
    }
    else if ([self.inteactObject.shareObject.shareType isEqualToString:@"parent_share_homework_report"]) {//作业分析
        [ZMPStatisticsManager event:kZMPEvent_study_zuoyefengxi_fengxiang];
    }
    
}

- (void)judgeLoginStatus {
    if (self.needLoginWhenBack && ![UserWrapper shareInstance].isLogin) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        self.needLoginWhenBack = NO;
    }
}

#pragma mark - Public Method
- (void)clickLeftNavAction:(UIButton *)leftButton {
    
    if (self.backHome) {
        [self dismiss];
        return;
    }
    
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }
    else {
        [self dismiss];
    }
    
}

- (void)clickRightNavAction:(UIButton *)rightButton {
    
    ZMPLocalShareView *shareView = [[ZMPLocalShareView alloc] init];
    [shareView showWithSharwTitle:self.inteactObject.shareObject.title shareDes:self.inteactObject.shareObject.desc thumbnail:self.inteactObject.shareObject.imgUrl shareURL:self.inteactObject.shareObject.linkUrl shareModuleType:self.inteactObject.shareObject.shareType];
    
    [self shareModuleStatistics];
}

- (void)registerJSCallLocalMethodBeforeLoadRequest {
    
    WeakSelf(w_self);
    
    [self registerJSCallLocalMethod:kZMPJSInteractiveMethodBackHome completionHandler:^(NSString * _Nonnull methodName, id  _Nullable body) {
        w_self.backHome = [[body objectForKey:@"backHome"] boolValue];
    }];
    
    [self registerJSCallLocalMethod:kZMPJSInteractiveMethodConfig completionHandler:^(NSString * _Nonnull methodName, id  _Nullable body) {
        [w_self executJSConfig:body];
    }];
    
    [self registerJSCallLocalMethod:kZMPJSInteractiveMethodGotoLogin completionHandler:^(NSString * _Nonnull methodName, id  _Nullable body) {
        w_self.callJSType = kJSInteractiveOperationTypeUpdateSession;
        [w_self jumpLoginViewController];
    }];
    
    [self registerJSCallLocalMethod:kZMPJSInteractiveMethodShowGifHud completionHandler:^(NSString * _Nonnull methodName, id  _Nullable body) {
        [w_self showHUDWithShadow];
    }];
    
    [self registerJSCallLocalMethod:kZMPJSInteractiveMethodHideGifHud completionHandler:^(NSString * _Nonnull methodName, id  _Nullable body) {
        [w_self hideHUD];
    }];
    
    [self registerJSCallLocalMethod:kZMPJSInteractiveMethodGoNative completionHandler:^(NSString * _Nonnull methodName, id  _Nullable body) {
        [w_self goNative:body];
    }];
    
    [self registerJSCallLocalMethod:kZMPJSInteractiveMethodGetMobile completionHandler:^(NSString * _Nonnull methodName, id  _Nullable body) {
        [w_self getMobile];
    }];
    
    [self registerJSCallLocalMethod:kZMPJSInteractiveMethodSharePosters completionHandler:^(NSString * _Nonnull methodName, id  _Nullable body) {
        [w_self recommendShare:body];
    }];
    
}



#pragma mark - Delegate

#pragma mark - Getter And Setter

#pragma mark - Delloc
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNotification_LoginIn_Name object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNSNotification_Cancel_Name object:nil];
}
@end
