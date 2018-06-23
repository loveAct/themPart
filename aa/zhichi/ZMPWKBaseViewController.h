//
//  ZMPWKBaseViewController.h
//  ZMParentsProject
//
//  Created by James on 2017/11/30.
//  Copyright © 2017年 Sea. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "ZMPBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^JSCallLocalCompletionHandler)(NSString * _Nonnull methodName, id _Nullable body);

typedef void(^LocalCallJSCompletionHandler)(id _Nullable result, NSError * _Nullable error);

@interface ZMPWKBaseViewController : ZMPBaseViewController

@property (nonatomic, copy, readonly) NSString    *addressURLStr;
@property (nonatomic, strong, readonly) WKWebView *webView;

- (void)setNaviTitle:(NSString * _Nullable)title;

- (void)loadRequest:(NSString *)URLStr;



/**
 subclass override this method to register js interactive method
 */
- (void)registerJSCallLocalMethodBeforeLoadRequest;


- (void)registerJSCallLocalMethod:(NSString *)methodName completionHandler:(JSCallLocalCompletionHandler _Nonnull)completionHandler;

- (void)removeJSCallLocalMethod:(NSString *)methodName;

- (void)clearAllRegisteredJSCallLocalMethod;


- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(LocalCallJSCompletionHandler)completionHandler;

- (void)dismiss;
@end

NS_ASSUME_NONNULL_END
