//
//  RiddingLocation.h
//  Ridding
//
//  Created by zys on 12-4-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RiddingMapPoint : NSObject {
}
@property (nonatomic) long long dbId;
@property (nonatomic) long long riddingId;
@property (nonatomic) double latitude;
@property (nonatomic) double longtitude;
@property (nonatomic,copy) NSString *mappoint;
@property (nonatomic) long long userId;

@end
