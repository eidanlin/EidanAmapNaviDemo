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

+ (AMapNaviPoint *)calcPointWithStartPoint:(AMapNaviPoint *)start endPoint:(AMapNaviPoint *)end rate:(double)rate {
    if (rate > 1.0 || rate < 0)
    {
        return nil;
    }
    
    MAMapPoint from = [self convertNaviPointToMapPoint:start];
    MAMapPoint to = [self convertNaviPointToMapPoint:end];
    
    double latitudeDelta = (to.y - from.y) * rate;
    double longitudeDelta = (to.x - from.x) * rate;
    
    MAMapPoint newPoint = MAMapPointMake(from.x + longitudeDelta, from.y + latitudeDelta);
    
    return [self convertMapPointToNaviPoint:newPoint];
}

+ (AMapNaviPoint *)convertMapPointToNaviPoint:(MAMapPoint)mapPoint {
    CLLocationCoordinate2D coordinate = MACoordinateForMapPoint(mapPoint);
    return [AMapNaviPoint locationWithLatitude:coordinate.latitude longitude:coordinate.longitude];
}

+ (MAMapPoint)convertNaviPointToMapPoint:(AMapNaviPoint *)point {
    return MAMapPointForCoordinate(CLLocationCoordinate2DMake(point.latitude, point.longitude));
}

@end
