//
//  AMapNaviViewUtilityX.m
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/1/13.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import "AMapNaviViewUtilityX.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapNaviKit/AMapNaviKit.h>

@implementation AMapNaviViewUtilityX

#pragma mark - NormailzedDegree

+ (double)normalizeDegree:(double)degree {
    CGFloat normalizationDegree = fmod(degree, 360.f);
    return (normalizationDegree < 0) ? normalizationDegree += 360.f : normalizationDegree;
}

+ (double)calcDistanceBetweenPoint:(AMapNaviPoint *)pointA andPoint:(AMapNaviPoint *)pointB {
    MAMapPoint mapPointA = MAMapPointForCoordinate(CLLocationCoordinate2DMake(pointA.latitude, pointA.longitude));
    MAMapPoint mapPointB = MAMapPointForCoordinate(CLLocationCoordinate2DMake(pointB.latitude, pointB.longitude));
    
    return MAMetersBetweenMapPoints(mapPointA, mapPointB);
}

@end
