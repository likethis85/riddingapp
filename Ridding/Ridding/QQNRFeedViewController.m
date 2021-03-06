//
//  QQNRFeedViewController.m
//  Ridding
//
//  Created by zys on 12-9-27.
//
//

#import "QQNRFeedViewController.h"
#import "UserSettingViewController.h"
#import "TutorialViewController.h"
#import "SVProgressHUD.h"
#import "Utilities.h"
#import "RiddingPictureDao.h"
#import "QQNRServerTaskQueue.h"
#import "PublicDetailViewController.h"
#import "QiNiuUtils.h"
#import "UIImageView+WebCache.h"
#import "RiddingMapPointDao.h"
#import "RiddingMapPoint.h"
#import "MapUtil.h"
#import "MapCreateDescVCTL.h"
#import "Gps.h"
#define chaBtn @"chaBtn"
#define dataLimit 10

@interface QQNRFeedViewController ()

@end

@implementation QQNRFeedViewController
@synthesize isMyFeedHome = _isMyFeedHome;

- (id)initWithUser:(User *)toUser isFromLeft:(BOOL)isFromLeft {

  self = [super init];
  if (self) {
    _toUser = toUser;
    if ([RiddingAppDelegate isMyFeedHome:_toUser]) {
      self.isMyFeedHome = TRUE;
    }
    _isFromLeft = isFromLeft;
  }
  return self;
}

- (void)viewDidLoad {

    [super viewDidLoad];
  self.canMoveLeft=YES;
  self.view.backgroundColor = [UIColor colorWithPatternImage:UIIMAGE_FROMPNG(@"qqnr_bg")];
  self.tv.backgroundColor = [UIColor clearColor];
  
  if (_isFromLeft) {
    [self.barView.leftButton setImage:UIIMAGE_FROMPNG(@"qqnr_list") forState:UIControlStateNormal];
    [self.barView.leftButton setImage:UIIMAGE_FROMPNG(@"qqnr_list_hl") forState:UIControlStateHighlighted];
    self.hasLeftView = TRUE;
  }else{
    [self.barView.leftButton setImage:UIIMAGE_FROMPNG(@"qqnr_back") forState:UIControlStateNormal];
    [self.barView.leftButton setImage:UIIMAGE_FROMPNG(@"qqnr_back") forState:UIControlStateHighlighted];
    self.hasLeftView = FALSE;
  }
  [self.barView.leftButton setHidden:NO];
  [self.barView.rightButton setImage:UIIMAGE_FROMPNG(@"qqnr_main_refresh") forState:UIControlStateNormal];
  [self.barView.rightButton setImage:UIIMAGE_FROMPNG(@"qqnr_main_refresh_hl") forState:UIControlStateHighlighted];
  [self.barView.rightButton setHidden:NO];
  
  [self.barView.titleLabel removeFromSuperview];
  
  UIImageView *imageView=[[UIImageView alloc]initWithFrame:CGRectMake(120, 8, 80, 28)];
  imageView.image=UIIMAGE_FROMPNG(@"qqnr_toolbar_logo");
  [self.barView addSubview:imageView];

  _backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, SCREEN_STATUS_BAR, SCREEN_WIDTH, QQNRFeedHeaderView_Default_Height)];
  NSURL *url = [QiNiuUtils getUrlByWidthToUrl:_backgroundImageView.frame.size.width url:_toUser.backGroundUrl type:QINIUMODE_DEDEFAULT];
  
  [_backgroundImageView setImageWithURL:url placeholderImage:UIIMAGE_FROMFILE(@"qqnr_main_pic", @"jpg")];
  _backgroundImageView.contentMode = UIViewContentModeCenter;
  _backgroundImageView.clipsToBounds = YES;
  [self.view addSubview:_backgroundImageView];


  [self addTableHeader];
  [self addTableFooter];

  [self.view bringSubviewToFront:self.tv];

  _endCreateTime = -1;
  _isTheEnd = FALSE;
  _isLoadOld = FALSE;
  _dataSource = [[NSMutableArray alloc] init];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(succAddRidding:)
                                               name:kSuccAddRiddingNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(succUpdateBackground:)
                                               name:kSuccUploadBackgroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(succAddFriends:)
                                               name:kSuccAddFriendsNotification object:nil];

}

- (void)showAd{
  
#ifdef isProVersion
#else
  if(!_bannerView){
    _bannerView = [[GADSearchBannerView alloc] initWithAdSize:GADAdSizeFromCGSize(GAD_SIZE_320x50) origin:CGPointMake(0, SCREEN_HEIGHT- 50)];
    _bannerView.adUnitID = MY_BANNER_UNIT_ID;
    _bannerView.rootViewController = self;
    [self.view addSubview:_bannerView];
    GADSearchRequest *adRequest = [[GADSearchRequest alloc] init];
    [adRequest setQuery:@"sport"];
    [_bannerView loadRequest:[adRequest request]];
  }
#endif


}

- (void)viewDidAppear:(BOOL)animated {

  [super viewDidAppear:animated];
  if (!self.didAppearOnce) {
    self.didAppearOnce = TRUE;
    self.tv.scrollEnabled=NO;
    [self download];
    if ([[ResponseCodeCheck getSinglton] isWifi]) {
      NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
      
      if (_isMyFeedHome &&[StaticInfo getSinglton].user.nowRiddingCount >= 2 && ![prefs boolForKey:@"recomComment"]&&![prefs boolForKey:chaBtn]) {
        
        if ([StaticInfo getSinglton].user.nowRiddingCount >= 5) {
          
          [_evaluateBtn setImage:UIIMAGE_FROMPNG(@"qqnr_evaluate_view1") forState:UIControlStateNormal];
          [_evaluateBtn setImage:UIIMAGE_FROMPNG(@"qqnr_evaluate_view1") forState:UIControlStateHighlighted];
          
        } else {
          
          [_evaluateBtn setImage:UIIMAGE_FROMPNG(@"qqnr_evaluate_view2") forState:UIControlStateNormal];
          [_evaluateBtn setImage:UIIMAGE_FROMPNG(@"qqnr_evaluate_view2") forState:UIControlStateHighlighted];
          
        }
        _evaluateView.alpha=0.0;
        _evaluateView.hidden=NO;
        [UIView animateWithDuration:1.0 animations:^{
          _evaluateView.alpha=1.0;
        }];
        [self.view bringSubviewToFront:_evaluateView];
        [prefs setBool:YES forKey:@"recomComment"];
        [prefs synchronize];
      }else{
        [self checkUploadPhoto];
      }
    }
    if([StaticInfo getSinglton].user.nowRiddingCount==0){
      [self.lineView removeFromSuperview];
    }
    
  }
}


- (void)checkUploadPhoto{
  int count=[RiddingPictureDao getRiddingPictureCount];
  if(count>0){
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"图片上传"
                                       message:[NSString stringWithFormat:@"您还有%d张相片没有上传",count]
                                      delegate:self cancelButtonTitle:@"暂时不上传"
                             otherButtonTitles:@"现在上传", nil];
    [alert show];
  }
}

- (void)rightBtnClicked:(id)sender {
  _isLoadOld = FALSE;
  [self download];
}

- (void)didReceiveMemoryWarning {

  [super didReceiveMemoryWarning];
}


- (void)download {

  if (_isLoading) {
    return;
  }
  _isLoading = TRUE;
  [SVProgressHUD showWithStatus:@"请稍候"];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSArray *array;
    if (_isLoadOld) {
      array = [self.requestUtil getUserMaps:dataLimit createTime:_endCreateTime userId:_toUser.userId isLarger:0];
    } else {
      array = [self.requestUtil getUserMaps:dataLimit createTime:-1 userId:_toUser.userId isLarger:0];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      if (!_isLoadOld) {
        [_dataSource removeAllObjects];
        _isTheEnd = FALSE;
      } else{
        [self doneLoadingTableViewData];
      }
      [self doUpdate:array];
      if (_isTheEnd) {
        [_ego setHidden:YES];
      } else {
        [_ego setHidden:NO];
      }
      if ([_dataSource count] == 0&&_isMyFeedHome) {
        [self.nothingView setHidden:NO];
        [self.lineView setHidden:YES];
        [_ego setHidden:YES];
        [self.view bringSubviewToFront:self.nothingView];
        [_bannerView removeFromSuperview];
      }else{
        [self.nothingView setHidden:YES];
        [self.lineView setHidden:NO];
        [self showAd];
      }
      [self.tv reloadData];
      [self downLoadMapRoutes];
      self.tv.scrollEnabled=YES;
      [SVProgressHUD dismiss];
      _isLoading = FALSE;
    });
  });
}



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

  if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"嗯!"]) {
   
  } else if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"现在上传"]){
    [RiddingPicture uploadRiddingPictureFromLocal];
  }
}


- (void)doUpdate:(NSArray *)array {

  if (array && [array count] > 0) {
    for (NSDictionary *dic in array) {
      Ridding *ridding = [[Ridding alloc] initWithJSONDic:[dic objectForKey:keyRidding]];

      [_dataSource addObject:ridding];
    }
    if ([array count] < dataLimit) {
      _isTheEnd = TRUE;
    }
    Ridding *ridding = (Ridding *) [_dataSource lastObject];
    _endCreateTime = ridding.createTime;
  }
}

#pragma mark - QQNRFeedHeaderViewDelegate
- (void)addTableHeader {

  _FHV = [[QQNRFeedHeaderView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, QQNRFeedHeaderView_Default_Height) user:_toUser];
  _FHV.backgroundColor = [UIColor clearColor];
  _FHV.delegate = self;
  [self.tv setTableHeaderView:_FHV];
}

- (void)addTableFooter {

  _ego = [[UP_EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 10, SCREEN_WIDTH, 45) withBackgroundColor:[UIColor colorWithPatternImage:UIIMAGE_FROMPNG(@"feed_cbg")]];
  _ego.delegate = self;
  _ego.backgroundColor = [UIColor clearColor];
  [self.tv setTableFooterView:_ego];


}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

  return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

  return 230;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

  return [_dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  UITableViewCell *uiTableViewCell=[Utilities cellByClassName:@"QQNRFeedTableCell" inNib:@"QQNRFeedTableCell" forTableView:self.tv];
  if(uiTableViewCell){
    QQNRFeedTableCell *cell = (QQNRFeedTableCell *)uiTableViewCell;
    cell.backgroundColor = [UIColor clearColor];
    cell.delegate = self;
    cell.userInteractionEnabled = YES;
    cell.index = indexPath.row;
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnCell:)];
    [cell addGestureRecognizer:longPressRecognizer];
    
    Ridding *ridding = [_dataSource objectAtIndex:indexPath.row];
    [cell initContentView:ridding];
    return cell;
  }
  
  return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  Ridding *ridding = [_dataSource objectAtIndex:indexPath.row];
  PublicDetailViewController *pdVCTL = [[PublicDetailViewController alloc] initWithNibName:@"PublicDetailViewController" bundle:nil ridding:ridding isMyHome:_isMyFeedHome toUser:_toUser];
  [self.navigationController pushViewController:pdVCTL animated:YES];
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

  CGRect frame = _backgroundImageView.frame;
  if (scrollView.contentOffset.y < 0) {
    frame.size.height = QQNRFeedHeaderView_Default_Height - scrollView.contentOffset.y;
  } else if (scrollView.contentOffset.y > 0 && scrollView.contentOffset.y < QQNRFeedHeaderView_Default_Height) {
    frame.size.height = QQNRFeedHeaderView_Default_Height - scrollView.contentOffset.y;
  } else if (scrollView.contentOffset.y > QQNRFeedHeaderView_Default_Height) {
    frame.size.height = 0;
  }
  [_backgroundImageView setFrame:frame];
  if (!_isTheEnd) {
    [_ego egoRefreshScrollViewDidScroll:scrollView];
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

  [self downLoadMapRoutes];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {

}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {

  if (!decelerate) {
    [self downLoadMapRoutes];
  }
  if (!_isTheEnd) {
    [_ego egoRefreshScrollViewDidEndDragging:scrollView];
  }
}


- (void)downLoadMapRoutes {
  
  NSArray *cellArray = [self.tv visibleCells];
  if (cellArray) {
    for (int i=0;i<[cellArray count];i++) {
      NSMutableArray *routes = [[NSMutableArray alloc] init];
      QQNRFeedTableCell *cell=(QQNRFeedTableCell*)[cellArray objectAtIndex:i];
      if(cell==nil){
        return;
      }
      dispatch_queue_t q;
      q = dispatch_queue_create("drawRoutes", NULL);
      dispatch_async(q, ^{
        Ridding *ridding = [_dataSource objectAtIndex:cell.index];
        NSArray *tempRoutes=(NSArray*)[[StaticInfo getSinglton].routesDic objectForKey:[StaticInfo routeDicKey:ridding.riddingId userId:_toUser.userId]];
        [routes addObjectsFromArray:tempRoutes];
        if(!routes||[routes count]==0){
          RiddingMapPoint *riddingMapPoint=[RiddingMapPointDao getRiddingMapPoint:ridding.riddingId userId:_toUser.userId];
          if (riddingMapPoint) {
            NSLog(@"%@",riddingMapPoint.mappoint);
            [routes addObjectsFromArray:[[MapUtil getSinglton] decodePolyLineArray:[riddingMapPoint.mappoint JSONValue]]];
          } else {
            //如果数据库中存在，那么取数据库中的地图路径，如果不存在，http去请求服务器。
            //数据库中取出是mapTaps或者points
            NSMutableDictionary *map_dic = [self.requestUtil getMapMessage:ridding.riddingId userId:_toUser.userId];
            Map *map = [[Map alloc] initWithJSONDic:[map_dic objectForKey:keyMap]];
            [routes addObjectsFromArray:[[MapUtil getSinglton] decodePolyLineArray:map.mapPoint]];
            [RiddingMapPointDao addRiddingMapPointToDB:[map.mapPoint JSONRepresentation] riddingId:ridding.riddingId userId:_toUser.userId];
          }
          [[StaticInfo getSinglton].routesDic setObject:routes forKey:[StaticInfo routeDicKey:ridding.riddingId userId:_toUser.userId]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
          if(cell){
            [cell drawRoutes:routes riddingId:ridding.riddingId userId:_toUser.userId];
          }
        });
      });

    }
  }
}

#pragma mark (ActionSheet)
- (void)longPressOnCell:(UILongPressGestureRecognizer *)gestureRecognize {

  if (gestureRecognize.state == UIGestureRecognizerStateBegan){
    if ([gestureRecognize.view isKindOfClass:[QQNRFeedTableCell class]]) {
      [MobClick event:@"2012111909"];
      QQNRFeedTableCell *cell = (QQNRFeedTableCell *) gestureRecognize.view;
      [self showActionSheet:cell];
      
    }
  }
  if (gestureRecognize.state == UIGestureRecognizerStateEnded) {
    return;
  }

}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

  NSString *str = [actionSheet buttonTitleAtIndex:buttonIndex];
  Ridding *ridding = [_dataSource objectAtIndex:_selectedCell.index];
  if ([str isEqualToString:@"本次骑行已经完成"]) {
    [MobClick event:@"2012070206"];
    [SVProgressHUD show];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [self.requestUtil finishActivity:ridding.riddingId];
      [ridding setEnd];
      [StaticInfo getSinglton].user.totalDistance += ridding.map.distance;
      dispatch_async(dispatch_get_main_queue(), ^{
        [_FHV finishRidding];
        [self.tv reloadData];
        [SVProgressHUD dismiss];
      });
    });
  } else if ([str isEqualToString:@"删除活动"]||[str isEqualToString:@"退出活动"]) {
    [MobClick event:@"2012070207"];
    [SVProgressHUD show];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      int returnCode = [self.requestUtil quitActivity:ridding.riddingId];
      dispatch_async(dispatch_get_main_queue(), ^{
        if (returnCode == kServerSuccessCode) {
          [_dataSource removeObject:ridding];
          [self.tv reloadData];
          if([Ridding isLeader:ridding.riddingUser.userRole]){
            [SVProgressHUD showSuccessWithStatus:@"删除成功" duration:1.0];
          }else{
            [SVProgressHUD showSuccessWithStatus:@"退出成功" duration:1.0];
          }
        }
      });
    });
  } else if ([str isEqualToString:@"拍摄新照片"]) {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    [imagePicker setDelegate:self];
    imagePicker.videoQuality = UIImagePickerControllerQualityTypeLow;
    [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
    [self presentModalViewController:imagePicker animated:YES];
  } else if ([str isEqualToString:@"从照片库选择"]) {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    [imagePicker setDelegate:self];
    [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [self presentModalViewController:imagePicker animated:YES];
  }
  
  return;
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {

  [actionSheet setHidden:YES];
  [actionSheet removeFromSuperview];
}

- (void)showActionSheet:(QQNRFeedTableCell *)cell {

  if (self.isMyFeedHome && cell) {
    _selectedCell = cell;
    UIActionSheet *showSheet = nil;
    Ridding *ridding = [_dataSource objectAtIndex:cell.index];
    NSString *title=[NSString stringWithFormat:@"需要对骑行活动:\"%@\"做操作吗?",ridding.riddingName];
    if(![ridding isEnd]){
      if ([Ridding isLeader:ridding.riddingUser.userRole]){
        
          showSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"本次骑行已经完成" otherButtonTitles:@"删除活动", nil];
      }else{
        
         showSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"退出活动" otherButtonTitles:nil];
      }
    }else{
      
      if ([Ridding isLeader:ridding.riddingUser.userRole]){
        
        showSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"删除活动" otherButtonTitles:nil];
      }else{
        
        showSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"退出活动" otherButtonTitles:nil];
      }
    }
    showSheet.delegate = self;
    [showSheet showInView:self.view];
  }
}

#pragma mark -
#pragma mark (QQNRFeedTableCellDelegate)
- (void)leaderTap:(QQNRFeedTableCell *)cell {

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    Ridding *ridding = [_dataSource objectAtIndex:cell.index];
    NSDictionary *dic = [self.requestUtil getUserProfile:ridding.leaderUser.userId sourceType:SOURCE_SINA needCheckRegister:NO];
    User *_user = [[User alloc] initWithJSONDic:[dic objectForKey:keyUser]];
    dispatch_async(dispatch_get_main_queue(), ^{
        QQNRFeedViewController *QQNRFVC = [[QQNRFeedViewController alloc] initWithUser:_user isFromLeft:FALSE];
        [self.navigationController pushViewController:QQNRFVC animated:YES];
    });
  });
}

- (void)statusTap:(QQNRFeedTableCell *)cell {

  [MobClick event:@"2012111908"];
  [self showActionSheet:cell];
}

#pragma mark - EGO

- (void)reloadTableViewDataSource {

  if (!_isTheEnd) {
    _isLoadOld = TRUE;
    [self download];
  }
}

- (void)doneLoadingTableViewData {
  //  model should call this when its done loading
  if (!_isTheEnd) {
    [_ego egoRefreshScrollViewDataSourceDidFinishedLoading:self.tv];
  }
}

- (void)egoRefreshTableHeaderDidTriggerRefresh:(UP_EGORefreshTableHeaderView *)view {

  [self reloadTableViewDataSource];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(UP_EGORefreshTableHeaderView *)view {

  return _isLoading; // should return if data source model is reloading
}

- (IBAction)initBtnPress:(id)sender {

  TutorialViewController *tutorialViewController = [[TutorialViewController alloc] initWithNibName:@"TutorialViewController" bundle:nil];
  [self presentModalViewController:tutorialViewController animated:YES];
}

- (IBAction)createRidding:(id)sender {
  
  MapCreateVCTL *mapCreate = [[MapCreateVCTL alloc] init];
  [self.navigationController popToRootViewControllerAnimated:NO];
  RiddingAppDelegate *delegate = [RiddingAppDelegate shareDelegate];
  [delegate.navController pushViewController:mapCreate animated:YES];
}

- (IBAction)evaluateBtnClick:(id)sender
{
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:linkAppStore]];
  [MobClick event:@"2013022506"];
}

- (IBAction)chaBtnClick:(id)sender
{
  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  [prefs setBool:YES forKey:chaBtn];
  [_evaluateView removeFromSuperview];

}

#pragma mark - MapCreateVCTL delegate
- (void)finishCreate:(MapCreateVCTL *)controller ridding:(Ridding *)ridding {

  [controller dismissModalViewControllerAnimated:NO];
  MapCreateDescVCTL *descVCTL = [[MapCreateDescVCTL alloc] initWithNibName:@"MapCreateDescVCTL" bundle:nil ridding:ridding];

  [self presentModalViewController:descVCTL animated:YES];
}

#pragma mark - MapCreateDescVCTL delegate
- (void)succAddRidding:(NSNotification *)note {

  _isLoadOld = FALSE;
  [self download];
}

#pragma mark - QQNRFeedHeaderView delegate
- (void)backGroupViewClick:(QQNRFeedHeaderView *)view {
  if(!_isMyFeedHome){
    return;
  }
  [MobClick event:@"2013022507"];
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"您希望如何设置您的封面?" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"拍摄新照片" otherButtonTitles:@"从照片库选择", nil];
  actionSheet.delegate = self;
  [actionSheet showInView:self.view];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

  UIImage *newImage = [info objectForKey:UIImagePickerControllerOriginalImage];
  CGFloat width;
  CGFloat height;
  if (newImage.imageOrientation == UIImageOrientationLeft || newImage.imageOrientation == UIImageOrientationRight) {
    width = CGImageGetHeight([newImage CGImage]);
    height = CGImageGetWidth([newImage CGImage]);
  } else {
    width = CGImageGetWidth([newImage CGImage]);
    height = CGImageGetHeight([newImage CGImage]);
  }
  QQNRServerTask *task = [[QQNRServerTask alloc] init];
  task.step = STEP_UPLOADBACKGROUNDPHOTO;
  File *file = [[File alloc] init];
  file.fileImage = newImage;
  file.width = width;
  file.height = height;
  NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
  SET_DICTIONARY_A_OBJ_B_FOR_KEY_C_ONLYIF_B_IS_NOT_NIL(dic, file, kFileClientServerUpload_File);
  task.paramDic = dic;

  QQNRServerTaskQueue *queue = [QQNRServerTaskQueue sharedQueue];
  [queue addTask:task withDependency:NO];
  [MobClick event:@"2013022508"];
  [picker dismissModalViewControllerAnimated:YES];
  
}

- (void)succUpdateBackground:(NSNotification *)noti {

  NSString *urlStr = [StaticInfo getSinglton].user.backGroundUrl;

  NSURL *url = [QiNiuUtils getUrlBySizeToUrl:_backgroundImageView.frame.size url:urlStr type:QINIUMODE_DEDEFAULT];
  [_backgroundImageView setImageWithURL:url];
}

- (void)succAddFriends:(NSNotification *)notif {

  self.didAppearOnce = FALSE;
}




@end
