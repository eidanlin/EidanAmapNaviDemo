//
//  AMapNaviRoutePolylineX.h
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/1/18.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>

#define AMapNaviRoutePolylineImageUnknow        @"custtexture_no"
#define AMapNaviRoutePolylineImageSmooth        @"custtexture_green"
#define AMapNaviRoutePolylineImageSlow          @"custtexture_slow"
#define AMapNaviRoutePolylineImageJam           @"custtexture_bad"
#define AMapNaviRoutePolylineImageSeriousJam    @"custtexture_serious"
#define AMapNaviRoutePolylineImageDefault       @"custtexture"

#pragma mark - AMapNaviRouteTurnArrowPolyline

@interface AMapNaviRouteTurnArrowPolylineX : MAPolyline

@end

#pragma mark - AMapNaviRoutePolyline

@interface AMapNaviRoutePolylineX : MAMultiPolyline

@property (nonatomic, assign) CGFloat polylineWidth;

@property (nonatomic, copy) NSArray<UIImage *> *polylineTextureImages;

@property (nonatomic, copy) NSArray<UIColor *> *polylineStrokeColors;

@end


#pragma mark - AMapNaviGuidePolyline

@interface AMapNaviGuidePolylineX : MAPolyline

@end
