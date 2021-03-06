//
//  SourceLoginViewController.m
//  Ridding
//
//  Created by zys on 12-6-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "QQNRFeedViewController.h"
#import "SinaApiRequestUtil.h"
#import "UIColor+XMin.h"
#import "SVProgressHUD.h"


@interface QQNRSourceLoginViewController ()

@end

@implementation QQNRSourceLoginViewController
@synthesize web = _web;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
  }
  return self;
}

- (void)viewDidLoad {

  [super viewDidLoad];
  self.barView.titleLabel.text = @"登录";
  
  [self.barView.leftButton setImage:UIIMAGE_FROMPNG(@"qqnr_back") forState:UIControlStateNormal];
  [self.barView.leftButton setImage:UIIMAGE_FROMPNG(@"qqnr_back_hl") forState:UIControlStateHighlighted];
  [self.barView.leftButton setHidden:NO];
  
  NSString *OAuthUrl = [NSString stringWithFormat:@"%@/bind/mobilesinabind/", QIQUNARHOME];
  NSString *url = [[NSString alloc] initWithString:OAuthUrl];
  NSURLRequest *loginRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
  [self.web loadRequest:loginRequest];
  _sendWeiBo = FALSE;
  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  if (![prefs boolForKey:[[StaticInfo getSinglton] kRecomAppKey] ]) {
    [self setFollowView];
  }


}

- (void)leftBtnClicked:(id)sender {

  [RiddingAppDelegate moveMidNavgation];
  [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  // Return YES for supported orientations
  return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}


- (void)viewDidUnload {

  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {

  self.navigationController.navigationBarHidden = YES;
  [super viewWillAppear:animated];

}

- (void)viewWillDisappear:(BOOL)animated {

  self.web.delegate = nil;
  [super viewWillDisappear:animated];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {

  [SVProgressHUD showWithStatus:@"加载中..."];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {

  [SVProgressHUD dismiss];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

  NSString *queryStr = [[request URL] query];
  NSDictionary *dic = [[self explodeString:queryStr ToDictionaryInnerGlue:@"=" outterGlue:@"&"] copy];
  if ([dic objectForKey:kStaticInfo_userId] != nil) {
    StaticInfo *staticInfo = [StaticInfo getSinglton];
    staticInfo.user.userId = [[dic objectForKey:kStaticInfo_userId] longLongValue];
    staticInfo.user.authToken = [dic objectForKey:kStaticInfo_authToken];
    staticInfo.user.sourceType = SOURCE_SINA;//新浪微博

    NSDictionary *profileDic = [self.requestUtil getUserProfile:staticInfo.user.userId sourceType:staticInfo.user.sourceType needCheckRegister:NO];
    
  
    User *user = [[User alloc] initWithJSONDic:[profileDic objectForKey:keyUser]];
    user.userId = staticInfo.user.userId;
    user.authToken = staticInfo.user.authToken;
    user.sourceType = staticInfo.user.sourceType;
    staticInfo.user = user;

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:LONGLONG2NUM(staticInfo.user.userId) forKey:kStaticInfo_userId];
    [prefs setObject:staticInfo.user.name forKey:kStaticInfo_nickname];
    [prefs setObject:staticInfo.user.authToken forKey:kStaticInfo_authToken];
    [prefs setInteger:staticInfo.user.sourceType forKey:kStaticInfo_sourceType];
    [prefs setObject:staticInfo.user.accessToken forKey:kStaticInfo_accessToken];
    [prefs setObject:staticInfo.user.savatorUrl forKey:kStaticInfo_savatorUrl];
    [prefs setObject:staticInfo.user.bavatorUrl forKey:kStaticInfo_bavatorUrl];
    [prefs setObject:staticInfo.user.backGroundUrl forKey:kStaticInfo_backgroundUrl];
    [prefs setObject:LONGLONG2NUM(staticInfo.user.sourceUserId) forKey:kStaticInfo_accessUserId];
    [prefs setInteger:staticInfo.user.nowRiddingCount forKey:kStaticInfo_riddingCount];
    [prefs setObject:INT2NUM(staticInfo.user.totalDistance) forKey:kStaticInfo_totalDistance];
    [prefs setObject:staticInfo.user.taobaoCode forKey:kStaticInfo_taobaoCode];
//    [prefs setBool:YES forKey:kStaticInfo_logined];
    [prefs synchronize];

    staticInfo.logined = true;
    [[SinaApiRequestUtil getSinglton] friendShip:riddingappsinaname accessUserId:riddingappuid];

    [self.requestUtil sendApns];

    if (_sendWeiBo) {
      [MobClick event:@"2013022505"];
      [[SinaApiRequestUtil getSinglton] sendLoginRidding:[NSString stringWithFormat:@"我刚刚下载了#骑行者#,在这里推荐给热爱骑行的好友们。@%@ 下载地址:%@",riddingappsinaname, downLoadPath]];

    } 
    [prefs setBool:TRUE forKey:[staticInfo kRecomAppKey]];

    [SVProgressHUD dismiss];

    if (self.delegate) {
      [self.delegate didFinishLogined:self];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kSuccLoginNotification object:nil];
  }
  return YES;
}

- (void)setFollowView {

  CGRect frame = self.view.frame;

  CGRect toolbarFrame = CGRectMake(0, SCREEN_HEIGHT - 44, frame.size.width, 44);
  UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:toolbarFrame];
  NSMutableArray *items = [[NSMutableArray alloc] init];

  UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [items addObject:space];

  UIBarButtonItem *lb = [[UIBarButtonItem alloc] initWithTitle:@"发微博推荐给好友" style:UIBarButtonItemStylePlain target:nil action:nil];
  [items addObject:lb];

  space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [items addObject:space];


  _redSC = [[SVSegmentedControl alloc] initWithSectionTitles:[NSArray arrayWithObjects:@"不推荐?", @"推荐!", nil]];
  [_redSC addTarget:self action:@selector(segmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
  _redSC.crossFadeLabelsOnDrag = YES;
  _redSC.thumb.tintColor = [UIColor getColor:ColorBlue];
  _redSC.selectedIndex = 0;
  [self.view addSubview:_redSC];
  _redSC.center = CGPointMake(240, 355);
  _sendWeiBo = TRUE;

  UIBarButtonItem *sb = [[UIBarButtonItem alloc] initWithCustomView:_redSC];
  [items addObject:sb];

  [toolBar setItems:items];

  toolBar.barStyle = UIBarStyleBlackOpaque;
  [self.view addSubview:toolBar];

}

- (NSMutableDictionary *)explodeString:(NSString *)src ToDictionaryInnerGlue:(NSString *)innerGlue outterGlue:(NSString *)outterGlue {
  // Explode based on outter glue
  NSArray *firstExplode = [src componentsSeparatedByString:outterGlue];
  NSArray *secondExplode;

  // Explode based on inner glue
  NSInteger count = [firstExplode count];
  NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithCapacity:count];
  for (NSInteger i = 0; i < count; i++) {
    secondExplode = [(NSString *) [firstExplode objectAtIndex:i] componentsSeparatedByString:innerGlue];
    if ([secondExplode count] == 2) {
      [returnDictionary setObject:[secondExplode objectAtIndex:1] forKey:[secondExplode objectAtIndex:0]];
    }
  }

  return returnDictionary;
}

#pragma mark -
#pragma mark SPSegmentedControl
- (void)segmentedControlChangedValue:(SVSegmentedControl *)segmentedControl {

  if (segmentedControl.selectedIndex == 0) {
    _sendWeiBo = FALSE;
  } else if (segmentedControl.selectedIndex == 1) {
    _sendWeiBo = TRUE;
  }
}

- (void)dealloc {

  self.delegate = nil;
}


@end
