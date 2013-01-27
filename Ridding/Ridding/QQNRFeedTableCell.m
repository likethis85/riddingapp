//
//  QQNRFeedTableCell.m
//  Ridding
//
//  Created by zys on 12-9-27.
//
//
#import "QQNRFeedTableCell.h"
#import "SDImageCache.h"
#import "UIImageView+WebCache.h"
#import "UIColor+XMin.h"
#import "QiNiuUtils.h"
#import "UIButton+WebCache.h"
#import "MapUtil.h"

@implementation QQNRFeedTableCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

  [super setSelected:selected animated:animated];
}


- (void)awakeFromNib {

  [super awakeFromNib];
  self.avatorBtn.layer.cornerRadius = 5;
  self.avatorBtn.layer.masksToBounds = YES;

  self.nameLabel.textColor = [UIColor whiteColor];
  self.distanceLabel.textColor = [UIColor whiteColor];
  self.teamCountLabel.textColor = [UIColor whiteColor];

}

- (void)initContentView:(Ridding *)ridding {

  [self.avatorBtn setImage:UIIMAGE_DEFAULT_USER_AVATOR forState:UIControlStateNormal];

  NSURL *url = [QiNiuUtils getUrlBySizeToUrl:self.avatorBtn.frame.size url:ridding.leaderUser.savatorUrl type:QINIUMODE_DESHORT];
  [self.avatorBtn setImageWithURL:url placeholderImage:UIIMAGE_DEFAULT_USER_AVATOR];

  NSString *distance = [NSString stringWithFormat:@"%0.2fKM", ridding.map.distance * 1.0 / 1000];
  self.distanceLabel.text = [NSString stringWithFormat:@"%@", distance];
  self.teamCountLabel.text = [NSString stringWithFormat:@"共%d人 ", ridding.userCount];
  self.nameLabel.text = ridding.riddingName;
}

- (void)drawRoutes:(NSArray *)routes {

  [[MapUtil getSinglton] center_map:_mapView routes:routes];
  [[MapUtil getSinglton] update_route_view:_mapView to:_mapLineView line_color:[UIColor getColor:lineColor] routes:routes];
}

- (IBAction)leaderViewTap:(id)selector {

  if ([self.delegate respondsToSelector:@selector(leaderTap:)]) {
    [self.delegate leaderTap:self];
  }
}


- (void)statusTap:(id)selector {

  if (self.delegate) {
    [self.delegate statusTap:self];
  }
}


@end
