//
//  PublicDetailHeaderView.m
//  Ridding
//
//  Created by zys on 12-11-11.
//
//

#import "PublicDetailHeaderView.h"
#import "UIImageView+WebCache.h"
#import "UIColor+XMin.h"
#import "MapUtil.h"
#import "Utilities.h"
#import "RiddingMapPoint.h"
#import "RiddingMapPointDao.h"
#import "UIButton+WebCache.h"

#define frameSize @"28"

@implementation PublicDetailHeaderView

- (id)initWithFrame:(CGRect)frame ridding:(Ridding *)ridding isMyHome:(BOOL)isMyHome toUser:(User*)toUser{

  self = [super initWithFrame:frame];
  if (self) {
    
    CGFloat height=0;
    _ridding = ridding;
    _toUser=toUser;
    _isMyHome = isMyHome;
    self.backgroundColor = [UIColor clearColor];

    UIButton *avatorBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    avatorBtn.frame=CGRectMake(15, 15, 55, 55);
    NSURL *url = [NSURL URLWithString:_ridding.leaderUser.savatorUrl];
    [avatorBtn setImageWithURL:url placeholderImage:UIIMAGE_DEFAULT_USER_AVATOR];
    avatorBtn.showsTouchWhenHighlighted = YES;
    [avatorBtn addTarget:self action:@selector(avatorClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:avatorBtn];
    
    UIImageView *avatorBgView=[[UIImageView alloc]initWithFrame:CGRectMake(11, 13, 61, 61)];
    avatorBgView.image=UIIMAGE_FROMPNG(@"qqnr_photo_bg");
    [self addSubview:avatorBgView];

    UILabel *riddingNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 10, 250, 30)];
    riddingNameLabel.textColor = [UIColor whiteColor];
    riddingNameLabel.textAlignment = UITextAlignmentLeft;
    riddingNameLabel.text = _ridding.riddingName;
    riddingNameLabel.backgroundColor = [UIColor clearColor];
    riddingNameLabel.font = [UIFont systemFontOfSize:20];
    [self addSubview:riddingNameLabel];

    UILabel *createLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 50, 75, 15)];
    createLabel.textColor = [UIColor whiteColor];
    createLabel.textAlignment = UITextAlignmentLeft;
    createLabel.text = _ridding.createTimeStr;
    createLabel.backgroundColor = [UIColor clearColor];
    createLabel.font = [UIFont systemFontOfSize:12];
    [self addSubview:createLabel];


    NSString *dictance = [_ridding.map totalDistanceToKm];
    CGSize linesSz = [dictance sizeWithFont:[UIFont boldSystemFontOfSize:12] constrainedToSize:CGSizeMake(70, 25) lineBreakMode:(NSLineBreakMode) UILineBreakModeCharacterWrap];

    UILabel *distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(225, 50, linesSz.width, linesSz.height + 2)];
    distanceLabel.textColor = [UIColor whiteColor];
    distanceLabel.textAlignment = UITextAlignmentLeft;
    distanceLabel.text = dictance;
    distanceLabel.backgroundColor = [UIColor clearColor];
    distanceLabel.font = [UIFont systemFontOfSize:12];


    UIImageView *iconImage = [[UIImageView alloc] initWithFrame:CGRectMake(distanceLabel.frame.origin.x - 18, distanceLabel.frame.origin.y, 12, 14)];
    iconImage.image = UIIMAGE_FROMPNG(@"qqnr_pd_distancepic");

    UIImageView *distanceViewBG = [[UIImageView alloc] initWithFrame:CGRectMake(distanceLabel.frame.origin.x - 20, distanceLabel.frame.origin.y, distanceLabel.frame.size.width + 25, distanceLabel.frame.size.height)];
    distanceViewBG.image = [UIIMAGE_FROMPNG(@"qqnr_pd_distancebg") stretchableImageWithLeftCapWidth:4 topCapHeight:10];

    [self addSubview:distanceViewBG];
    [self addSubview:iconImage];
    [self addSubview:distanceLabel];

    _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(20, 85, 280, 140)];
    _route_view = [[UIImageView alloc] initWithFrame:CGRectMake(15, 80, 290, 150)];
    _route_view.layer.borderColor = [[UIColor whiteColor] CGColor];
    _route_view.layer.borderWidth = 5.0;
    _route_view.userInteractionEnabled=YES;
    UITapGestureRecognizer *gesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(mapViewTap:)];
    [_route_view addGestureRecognizer:gesture];
    
    _goBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    [_goBtn setImage:UIIMAGE_FROMPNG(@"qqnr_pd_showMap") forState:UIControlStateNormal];
    _goBtn.frame=CGRectMake(132, 127, 56, 56);
    [_goBtn addTarget:self action:@selector(mapViewTap:) forControlEvents:UIControlEventTouchUpInside];
    
    [_mapView setShowsUserLocation:NO];
    _mapView.delegate = self;
    
    [_mapView setZoomEnabled:NO];
    [_mapView setScrollEnabled:NO];

    [self addSubview:_mapView];
    [self addSubview:_route_view];
    [self addSubview:_goBtn];
    _routes = [[NSMutableArray alloc] init];
    [self drawRoutes];
    
    UIImageView *mapBottomView=[[UIImageView alloc]initWithFrame:CGRectMake(_route_view.frame.origin.x, _route_view.frame.origin.y+_route_view.frame.size.height, 290, 10)];
    mapBottomView.image=UIIMAGE_FROMPNG(@"qqnr_pd_map_bg");
    [self addSubview:mapBottomView];

    height = mapBottomView.frame.origin.y+mapBottomView.frame.size.height;
    
    if(_ridding.aPublic.adContentType==2){
      _adImageView=[[UIImageView alloc]initWithFrame:CGRectMake(_route_view.frame.origin.x, mapBottomView.frame.origin.y+mapBottomView.frame.size.height+10, 290, 50)];
      NSURL *url=[NSURL URLWithString:_ridding.aPublic.linkImageUrl];
      [_adImageView setImageWithURL:url placeholderImage:nil];
      [self addSubview:_adImageView];
      _adImageView.userInteractionEnabled=YES;
      UITapGestureRecognizer *gesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(linkTap:)];
      [_adImageView addGestureRecognizer:gesture];
      
      height = _adImageView.frame.origin.y+_adImageView.frame.size.height;
    }
    
    if(_ridding.aPublic.adContentType==1){
      UIImageView *imageView=[[UIImageView alloc]initWithFrame:CGRectMake(_route_view.frame.origin.x, mapBottomView.frame.origin.y+mapBottomView.frame.size.height+10+3, 290, 36)];
      imageView.image=UIIMAGE_FROMPNG(@"qqnr_pd_ad");
      [self addSubview:imageView];
      
      _adLabel =[[UILabel alloc]initWithFrame:CGRectMake(_route_view.frame.origin.x+40, mapBottomView.frame.origin.y+mapBottomView.frame.size.height+10, 250, 30)];
      _adLabel.backgroundColor=[UIColor clearColor];
      _adLabel.textColor=[UIColor whiteColor];
      _adLabel.text=_ridding.aPublic.linkText;
      _adLabel.font=[UIFont systemFontOfSize:14];
      _adLabel.userInteractionEnabled=YES;
      UITapGestureRecognizer *gesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(linkTap:)];
      [_adLabel addGestureRecognizer:gesture];
      [self addSubview:_adLabel];
      
      height = _adLabel.frame.origin.y+_adLabel.frame.size.height;
    }
    
    
  }
  return self;
}

- (void)drawRoutes {

  dispatch_queue_t q;
  q = dispatch_queue_create("drawRoutes", NULL);
  dispatch_async(q, ^{
    NSArray *tempRoutes=(NSArray*)[[StaticInfo getSinglton].routesDic objectForKey:[StaticInfo routeDicKey:_ridding.riddingId userId:_toUser.userId]];
    [_routes addObjectsFromArray:tempRoutes];
    if(!_routes||[_routes count]==0){
      RiddingMapPoint *riddingMapPoint=[RiddingMapPointDao getRiddingMapPoint:_ridding.riddingId userId:_toUser.userId];
      if (riddingMapPoint) {
        [_routes addObjectsFromArray:[[MapUtil getSinglton] decodePolyLineArray:[riddingMapPoint.mappoint JSONValue]]];
      } else {
        //如果数据库中存在，那么取数据库中的地图路径，如果不存在，http去请求服务器。
        //数据库中取出是mapTaps或者points
        RequestUtil *requestUtil = [[RequestUtil alloc] init];
        NSMutableDictionary *map_dic = [requestUtil getMapMessage:_ridding.riddingId userId:[StaticInfo getSinglton].user.userId];
        Map *map = [[Map alloc] initWithJSONDic:[map_dic objectForKey:keyMap]];
        _routes = [[MapUtil getSinglton] decodePolyLineArray:map.mapPoint];
        [RiddingMapPointDao addRiddingMapPointToDB:[map.mapPoint JSONRepresentation] riddingId:_ridding.riddingId userId:_toUser.userId];
      }
       [[StaticInfo getSinglton].routesDic setObject:_routes forKey:[StaticInfo routeDicKey:_ridding.riddingId userId:_toUser.userId]];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [[MapUtil getSinglton] center_map:_mapView routes:_routes];
      UIImage *image=[self imageFromLocal:_ridding.riddingId userId:_toUser.userId];
      if(image){
        _route_view.image=image;
      }else{
        [[MapUtil getSinglton] update_route_view:_mapView to:_route_view line_color:[UIColor getColor:lineColor] routes:_routes width:3.0];
        [self saveToLocal:_ridding.riddingId userId:_toUser.userId];
      }
    });
  });
}

- (void)saveToLocal:(long long)riddingId userId:(long long)userId{
  
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
  //set image
  NSString *savePath= [[paths objectAtIndex:0] stringByAppendingPathComponent:
                       [NSString stringWithFormat:@"b_%lld_%lld.png",riddingId,userId]];
  NSFileManager *manager = [NSFileManager defaultManager];
  if (savePath&&![manager fileExistsAtPath:savePath]) {
    //save pic
    [UIImagePNGRepresentation(_route_view.image) writeToFile:savePath atomically:YES];
  }
}

- (UIImage*)imageFromLocal:(long long)riddingId userId:(long long)userId{
  
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
  //set image
  NSString *picPath=[[paths objectAtIndex:0] stringByAppendingPathComponent:
                     [NSString stringWithFormat:@"b_%lld_%lld.png",riddingId,userId]];
  NSFileManager *manager = [NSFileManager defaultManager];
  if (![manager fileExistsAtPath:picPath]) {
    return nil;
  }
  NSData *data=[NSData dataWithContentsOfFile:picPath];
  
  return [UIImage imageWithData:data];
}



- (void)mapViewTap:(UIGestureRecognizer *)gesture {

  if (self.delegate) {
    [self.delegate mapViewTap:self];
  }
}

- (void)avatorClick:(id)selector {

  if (self.delegate) {
    [self.delegate avatorClick:self];
  }
}


- (void)linkTap:(UIGestureRecognizer*)gesture{
  if(self.delegate){
    [self.delegate linkTap:self];
  }
}


@end
