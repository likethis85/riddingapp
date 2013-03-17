//
//  RiddingPicture.m
//  Ridding
//
//  Created by zys on 12-9-19.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RiddingPictureDao.h"
#import "QQNRServerTask.h"
#import "QQNRServerTaskQueue.h"
@implementation RiddingPicture

- (id)init {

  self = [super init];
  if (self) {
    self.user = [[User alloc] init];
  }
  return self;
}


- (id)initWithJSONDic:(NSDictionary *)jsonDic {

  self = [super init];
  if (self) {
    self.dbId = [[jsonDic objectForKey:@"dbid"] longLongValue];
    self.latitude = [[jsonDic objectForKey:@"latitude"] doubleValue];
    self.longtitude = [[jsonDic objectForKey:@"longtitude"] doubleValue];
    self.riddingId = [[jsonDic objectForKey:@"riddingid"] longLongValue];
    self.dbId = [[jsonDic objectForKey:@"dbid"] longLongValue];
    self.photoUrl = [jsonDic objectForKey:@"photourl"];
    self.height = [[jsonDic objectForKey:@"height"] intValue];
    self.width = [[jsonDic objectForKey:@"width"] intValue];
    self.takePicDateL = [[jsonDic objectForKey:@"takepicdatel"] longLongValue];
    self.takePicDateStr = [jsonDic objectForKey:@"takepicdatestr"];
    self.pictureDescription = [jsonDic objectForKey:@"description"];
    self.location = [jsonDic objectForKey:@"location"];
    self.user = [[User alloc] initWithJSONDic:[jsonDic objectForKey:keyUser]];
    self.createTime = [[jsonDic objectForKey:@"createtime"] longLongValue];
    self.liked = [[jsonDic objectForKey:@"liked"] boolValue];
    self.likeCount = [[jsonDic objectForKey:@"likecount"] intValue];
  }
  return self;
}

- (RiddingPicture *)initWithRidding:(int)width height:(int)height ridding:(Ridding *)ridding {

  self = [super init];
  if (self) {
    _riddingId = ridding.riddingId;
    _user = [StaticInfo getSinglton].user;
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    _takePicDateL = (long long) [date timeIntervalSince1970] * 1000;
    self.width = width;
    self.height = height;
  }
  return self;
}


+ (void)uploadRiddingPictureFromLocal{
  
  NSArray *array=[RiddingPictureDao getRiddingPictures];
  if(array!=nil&&[array count]>0){
    for(RiddingPicture *riddingPicture in array){
      QQNRServerTask *task = [[QQNRServerTask alloc] init];
      task.step = STEP_UPLOADPHOTO;
      NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithObjectsAndKeys:riddingPicture, kFileClientServerUpload_RiddingPicture, nil];
      task.paramDic = dic;
      QQNRServerTaskQueue *queue = [QQNRServerTaskQueue sharedQueue];
      [queue addTask:task withDependency:NO];
    }
  }
}
@end
