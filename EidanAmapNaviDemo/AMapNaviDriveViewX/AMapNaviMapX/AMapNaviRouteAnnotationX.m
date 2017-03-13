//
//  AMapNaviRouteAnnotationX.m
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/1/17.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import "AMapNaviRouteAnnotationX.h"

@implementation AMapNaviCameraAnnotationX

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    if (self = [super init]) {
        self.coordinate = coordinate;
    }
    return self;
}

@end

@implementation AMapNaviCameraTypeAnnotationX

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    if (self = [super init]) {
        self.coordinate = coordinate;
    }
    return self;
}

@end

@implementation AMapNaviStartPointAnnotationX

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    if (self = [super init]) {
        self.coordinate = coordinate;
    }
    return self;
}

@end

@implementation AMapNaviWayPointAnnotationX

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    if (self = [super init]) {
        self.coordinate = coordinate;
    }
    return self;
}

@end

@implementation AMapNaviEndPointAnnotationX

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    if (self = [super init]) {
        self.coordinate = coordinate;
    }
    return self;
}

@end


