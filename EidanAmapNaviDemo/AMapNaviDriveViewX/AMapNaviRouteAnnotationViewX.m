//
//  AMapNaviRouteAnnotationViewX.m
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/1/17.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import "AMapNaviRouteAnnotationViewX.h"
#import <AMapNaviKit/AMapNaviKit.h>

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
    }
    return self;
}

- (void)setImage:(UIImage *)image {
    if (image == nil){
        self.bounds = CGRectMake(0, 0, kAMapNaviCameraAnnotationViewWidth, kAMapNaviCameraAnnotationViewWidth);
        self.image = [UIImage imageNamed:kAMapNaviCameraAnnotationViewImageName];
    } else {
        [super setImage:image];
    }
}


@end

@implementation AMapNaviCameraTypeAnnotationViewX

#pragma mark - Life Cycle

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier cameraInfo:(AMapNaviCameraInfo *)info andIndex:(int)index{
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        self.bounds = CGRectMake(0, 0, 44, 56);
        
        NSString *imageName = @"default_navi_layer_camera_";
        if (info.cameraType == AMapNaviCameraTypeSpeed) {  //测速
            imageName = @"default_navi_layer_speed_";
        } else if (info.cameraType == AMapNaviCameraTypeTrafficLight) {  //闯红灯拍照
            imageName = @"default_navi_layer_light_";
        } else if (info.cameraType == AMapNaviCameraTypeBusway) {  //公交专用
            imageName = @"default_navi_layer_bus_";
        } else if (info.cameraType == AMapNaviCameraTypeEmergencyLane) {  //应急车道
            imageName = @"default_navi_layer_emergency_";
        }
        
        int flag = index % 2;
        NSString *leftOrRight = @"left";
        float xPoint = -22;
        if (flag == 1) {
            leftOrRight = @"right";
            xPoint = 22;
        }
        
        imageName = [NSString stringWithFormat:@"%@%@",imageName,leftOrRight];
        self.image = [UIImage imageNamed:imageName];
        
        self.imageView.frame = CGRectMake(xPoint, -20, self.bounds.size.width, self.bounds.size.height);
        
        //理论上要考虑重用，把label隐藏掉，但我们这里都是移除，重新生成，不会有重用的情况
        if (info.cameraType == AMapNaviCameraTypeSpeed) {  //测速
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(xPoint, -13, self.bounds.size.width, 30)];
            label.text = [NSString stringWithFormat:@"%ld",(long)info.cameraSpeed];
            label.font = [UIFont boldSystemFontOfSize:18];
            label.textAlignment = NSTextAlignmentCenter;
            [self addSubview:label];
        }
        
    }
    return self;
}


@end

@implementation AMapNaviStartPointAnnotationViewX

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (void)setImage:(UIImage *)image {
    if (image == nil) {
        [super setImage:[UIImage imageNamed:kAMapNaviStartPointAnnotationViewImageName]];
        self.bounds = CGRectMake(0, 0, kAMapNaviRoutePointAnnotationWidth, kAMapNaviRoutePointAnnotationHeight);
        self.centerOffset = kAMapNaviRoutePointAnnotaitonCenterOffset;
    } else {
        [super setImage:image];
        self.centerOffset = CGPointZero;
    }
}

@end

@implementation AMapNaviWayPointAnnotationViewX

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
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
