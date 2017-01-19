//
//  AMapNaviViewUtilityX.h
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/1/13.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AMapNaviKit/AMapNaviKit.h>

@interface AMapNaviViewUtilityX : NSObject

+ (double)calcDistanceBetweenPoint:(AMapNaviPoint *)pointA andPoint:(AMapNaviPoint *)pointB;

+ (AMapNaviPoint *)calcPointWithStartPoint:(AMapNaviPoint *)start endPoint:(AMapNaviPoint *)end rate:(double)rate;

#pragma mark - NormailzedDegree

+ (double)normalizeDegree:(double)degree;

@end
