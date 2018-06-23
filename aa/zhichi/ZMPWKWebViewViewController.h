//
//  ZMPWKWebViewViewController.h
//  ZMParentsProject
//
//  Created by Sea on 2017/9/22.
//  Copyright © 2017年 Sea. All rights reserved.
//H5交互页面

#import "ZMPWKBaseViewController.h"

#import "ZMPLocalShareView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZMPJSShareObject : NSObject
@property (nonatomic, copy)   NSString  *desc;
@property (nonatomic, copy)   NSString  *imgUrl;
@property (nonatomic, copy)   NSString  *linkUrl;
@property (nonatomic, copy)   NSString  *title;
@property (nonatomic, copy)   NSString  *shareType;
@end

@interface ZMPJSInteractObject : NSObject
@property (nonatomic, copy)   NSString  *setColor;
@property (nonatomic, copy)   NSString  *setTitle;
@property (nonatomic, assign) BOOL      hasShare;
@property (nonatomic, assign) BOOL      isBlack;
@property (nonatomic, strong) ZMPJSShareObject      *shareObject;
@end


@class ZMPWKWebViewViewController;

@protocol ZMPWKWebViewViewDelegate <NSObject>

- (void)webViewWillDismissed:(ZMPWKWebViewViewController *_Nonnull)webView;

@end


@interface ZMPWKWebViewViewController : ZMPWKBaseViewController

@property (nonatomic, weak) id<ZMPWKWebViewViewDelegate> webDelegate;

@end

NS_ASSUME_NONNULL_END
