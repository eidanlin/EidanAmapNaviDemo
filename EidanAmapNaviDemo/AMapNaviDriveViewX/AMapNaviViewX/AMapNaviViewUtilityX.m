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

#pragma mark - NormailzedString

+ (NSString *)normalizedRemainDistance:(NSInteger)remainDistance {
    if (remainDistance < 0) {
        return nil;
    }
    
    if (remainDistance >= 1000) {
        CGFloat kiloMeter = remainDistance / 1000.0;
        
        if (remainDistance % 1000 >= 100) {
            kiloMeter -= 0.05f;
            return [NSString stringWithFormat:@"%.1f公里", kiloMeter];
        } else {
            return [NSString stringWithFormat:@"%.0f公里", kiloMeter];
        }
    } else {
        return [NSString stringWithFormat:@"%ld米", (long)remainDistance];
    }
}

+ (NSString *)normalizedRemainTime:(NSInteger)remainTime {
    if (remainTime < 0) {
        return nil;
    }
    
    if (remainTime < 60) {
        return [NSString stringWithFormat:@"< 1分钟"];
    } else if (remainTime >= 60 && remainTime < 60*60) {
        return [NSString stringWithFormat:@"%ld分钟", (long)remainTime/60];
    } else {
        NSInteger hours = remainTime / 60 / 60;
        NSInteger minute = remainTime / 60 % 60;
        if (minute == 0) {
            return [NSString stringWithFormat:@"%ld小时", (long)hours];
        } else {
            return [NSString stringWithFormat:@"%ld小时%ld分钟", (long)hours, (long)minute];
        }
    }
}


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
