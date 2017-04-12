//
//  AMapNaviTrafficBarViewX.h
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/2/9.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AMapNaviKit/AMapNaviKit.h>

@interface AMapNaviTrafficBarViewX : UIView

- (void)updateCarPositionWithRouteRemainPercent:(double)remainPercent;

- (void)updateBarWithTrafficStatuses:(NSArray <AMapNaviTrafficStatus *> *)trafficStatuses;

@end
