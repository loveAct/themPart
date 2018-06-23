//
//  ZMPWKBaseViewController.m
//  ZMParentsProject
//
//  Created by James on 2017/11/30.
//  Copyright © 2017年 Sea. All rights reserved.
//

#import "ZMPWKBaseViewController.h"
#import "ZMPRequest.h"



@interface WeakScriptMessageDelegate : NSObject<WKScriptMessageHandler>

@property (nonatomic, weak) id scriptDelegate;

- (instancetype)initWithDelegate:(id)scriptDelegate;

@end

@implementation WeakScriptMessageDelegate

- (instancetype)initWithDelegate:(id)scriptDelegate
{
    self = [super init];
    if (self) {
        _scriptDelegate = scriptDelegate;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    [self.scriptDelegate userContentController:userContentController didReceiveScriptMessage:message];
}

- (void)dealloc {
    NSLog(@"%@ release", self);
}

@end

@interface ZMPWKBaseViewController ()
<
WKUIDelegate,
WKNavigationDelegate
>

@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) WKWebViewConfiguration *config;
@property (nonatomic, strong) WKUserContentController *userVC;
@property (nonatomic, strong) NSMutableDictionary *JSCallLocalBlockMehtodDic;
@end

@implementation ZMPWKBaseViewController
@synthesize webView = _webView;

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerJSCallLocalMethodBeforeLoadRequest];
    [self vcDefaultConfig];
    [self loadRequestInternally:self.addressURLStr];
}

- (void)viewWillLayoutSubviews {
    self.webView.frame = self.view.bounds;
}

#pragma mark - Observer
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context {
    
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        
        self.progressView.progress = self.webView.estimatedProgress;
        
        if (self.progressView.progress >= 1) {
            /*
             *添加一个简单的动画
             *动画时长0.25s，延时0.3s后开始动画
             *动画结束后将progressView隐藏
             */
            __weak typeof (self)weakSelf = self;
            
            [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                weakSelf.progressView.hidden = YES;
            } completion:nil];
            
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Private Method

#pragma mark UI
- (void)vcDefaultConfig {
    
    self.failTip.desLB.text = @"加载失败,点击刷新";
    
    //UI Config
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setNavTitle:@""
            imageName:@"register_icon_return"
        directionType:kNavDirectionTypeLeft];
    
    [self.webView addObserver:self
                   forKeyPath:@"estimatedProgress"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    
    [self.view addSubview:self.webView];
    [self.view addSubview:self.progressView];
}

- (void)loadRequestInternally:(NSString *)URLStr {
    if (!URLStr.length) {
        [[iToast makeText:@"请输入合法的URL路径"] show];
        return;
    }
    
    NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:URLStr]];
    mutableRequest.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    [ZMPRequest configCommonHeaderFieldForRequest:mutableRequest];
    
    [self showHUDWithOutShadow];
    [self.webView loadRequest:mutableRequest];
}

#pragma mark - Public Method

- (void)loadRequest:(NSString *)URLStr {
    _addressURLStr = URLStr;
}

- (void)setNaviTitle:(NSString *)title {
    self.navigationItem.title = title;
}

- (void)requestAgain {
    if (self.webView.URL.absoluteString.length) {
        [self.webView reload];
        return;
    }
    [self loadRequestInternally:_addressURLStr];
    [self.view bringSubviewToFront:self.progressView];
}

#pragma mark register/remove jsInteractiveMethod
- (void)registerJSCallLocalMethodBeforeLoadRequest {
    
}

- (void)registerJSCallLocalMethod:(NSString *)methodName completionHandler:(JSCallLocalCompletionHandler _Nonnull)completionHandler{
    
    NSAssert(completionHandler, @"block cant be nil");
    
    [self removeJSCallLocalMethod:methodName];
    
    [self.JSCallLocalBlockMehtodDic setValue:[completionHandler copy] forKey:methodName];
    [self.userVC addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:methodName];
}

- (void)removeJSCallLocalMethod:(NSString *)methodName {
    if (self.JSCallLocalBlockMehtodDic[methodName]) {
        [self.userVC removeScriptMessageHandlerForName:methodName];
    }
    [self.JSCallLocalBlockMehtodDic removeObjectForKey:methodName];
}

- (void)clearAllRegisteredJSCallLocalMethod {
    for (NSString *methodName in self.JSCallLocalBlockMehtodDic.allKeys) {
        [self removeJSCallLocalMethod:methodName];
    }
}


- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(LocalCallJSCompletionHandler)completionHandler {
    
    [self.webView evaluateJavaScript:javaScriptString completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(result, error);
        }
    }];
}

- (void)dismiss {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Delegate

#pragma mark WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

#pragma mark WKWebViewDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"开始加载网页");
    
    //开始加载网页时展示出progressView
    self.progressView.hidden = NO;
    //防止progressView被网页挡住
    [self.view bringSubviewToFront:self.progressView];
}
// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    
}
// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"加载完成");
    //加载完成后隐藏progressView
    self.progressView.hidden = YES;
    [self hideHUD];
    [self hideAllTip];
}

// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"加载失败:%@", error);
    
    //加载失败同样需要隐藏progressView
    self.progressView.hidden = YES;
    [self hideHUD];
    [self showRequestFailTip];
    
}

#pragma mark WeakScriptMessageDelegate
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if (self.JSCallLocalBlockMehtodDic[message.name]) {
        ((JSCallLocalCompletionHandler)self.JSCallLocalBlockMehtodDic[message.name])(message.name, message.body);
    }
}

#pragma mark - Getter And Setter
- (WKWebView *)webView {
    
    if (!_webView) {
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height) configuration:self.config];
        _webView.UIDelegate         = self;
        _webView.navigationDelegate = self;
        [_webView addSubview:self.progressView];
    }
    
    return _webView;
}

- (WKWebViewConfiguration *)config {
    
    if (!_config) {
        _config = [[WKWebViewConfiguration alloc] init];
    }
    
    return _config;
}

- (WKUserContentController *)userVC {
    
    if (!_userVC) {
        _userVC = self.config.userContentController;
    }
    
    return _userVC;
}

- (UIProgressView *)progressView {
    
    if (!_progressView) {
        
        //进度条初始化
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0,
                                                                         [[UIScreen mainScreen] bounds].size.width, 2)];
        _progressView.backgroundColor = [UIColor blueColor];
        
    }
    
    return _progressView;
}


- (NSMutableDictionary *)JSCallLocalBlockMehtodDic {
    if (!_JSCallLocalBlockMehtodDic) {
        _JSCallLocalBlockMehtodDic = [[NSMutableDictionary alloc] init];
    }
    return _JSCallLocalBlockMehtodDic;
}


#pragma mark - Delloc
- (void)dealloc {
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@""]]];
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self clearAllRegisteredJSCallLocalMethod];
}

@end

