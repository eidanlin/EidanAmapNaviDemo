//
//  AMapNaviRouteAnnotationViewX.m
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/1/17.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import "AMapNaviRouteAnnotationViewX.h"

#define kAMapNaviCameraAnnotationViewWidth          22.f
#define kAMapNaviRoutePointAnnotationWidth          35.f
#define kAMapNaviRoutePointAnnotationHeight         46.f
#define kAMapNaviRoutePointAnnotaitonCenterOffset   CGPointMake(0, -18)

#define kAMapNaviCameraAnnotationViewImageName      @"default_navi_route_camera"
#define kAMapNaviStartPointAnnotationViewImageName  @"default_navi_route_startpoint"
#define kAMapNaviWayPointAnnotationViewImageName    @"default_navi_route_waypoint"
#define kAMapNaviEndPointAnnotationViewImageName    @"default_navi_route_endpoint"

@implementation AMapNaviCameraAnnotationViewX

#pragma mark - Life Cycle

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        self.bounds = CGRectMake(0, 0, kAMapNaviCameraAnnotationViewWidth, kAMapNaviCameraAnnotationViewWidth);
        self.image = [UIImage imageNamed:kAMapNaviCameraAnnotationViewImageName];
    }
    return self;
}


@end

@implementation AMapNaviStartPointAnnotationViewX

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        self.bounds = CGRectMake(0, 0, kAMapNaviRoutePointAnnotationWidth, kAMapNaviRoutePointAnnotationHeight);
        self.image = [UIImage imageNamed:kAMapNaviStartPointAnnotationViewImageName];
    }
    
    return self;
}

@end

@implementation AMapNaviWayPointAnnotationViewX

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        self.image = nil;
    }
    
    return self;
}

- (void)setImage:(UIImage *)image {
    if (image == nil) {
        [super setImage:[UIImage imageNamed:kAMapNaviWayPointAnnotationViewImageName]];
        self.bounds = CGRectMake(0, 0, kAMapNaviRoutePointAnnotationWidth, kAMapNaviRoutePointAnnotationHeight);
        self.centerOffset = kAMapNaviRoutePointAnnotaitonCenterOffset;
    } else {
        [super setImage:image];
        self.centerOffset = CGPointZero;
    }
}

@end

@implementation AMapNaviEndPointAnnotationViewX

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        self.image = nil;
    }
    
    return self;
}

- (void)setImage:(UIImage *)image {
    if (image == nil) {
        [super setImage:[UIImage imageNamed:kAMapNaviEndPointAnnotationViewImageName]];
        self.bounds = CGRectMake(0, 0, kAMapNaviRoutePointAnnotationWidth, kAMapNaviRoutePointAnnotationHeight);
        self.centerOffset = kAMapNaviRoutePointAnnotaitonCenterOffset;
    } else {
        [super setImage:image];
        self.centerOffset = CGPointZero;
    }
}

@end
