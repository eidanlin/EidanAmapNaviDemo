//
//  AMapNaviRouteAnnotationX.h
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/1/17.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import <MAMapKit/MAAnnotation.h>
#import <AMapNaviKit/AMapNaviKit.h>

@interface AMapNaviCameraAnnotationX : NSObject <MAAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@end

@interface AMapNaviCameraTypeAnnotationX : NSObject <MAAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@property (nonatomic, strong) AMapNaviCameraInfo *cameraInfo;

@property (nonatomic, assign) int index;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@end

@interface AMapNaviStartPointAnnotationX : NSObject <MAAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@end

@interface AMapNaviWayPointAnnotationX : NSObject <MAAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@end

@interface AMapNaviEndPointAnnotationX : NSObject <MAAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@end





