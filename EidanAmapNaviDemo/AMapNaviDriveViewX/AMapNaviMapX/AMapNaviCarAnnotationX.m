//
//  AMapNaviCarAnnotationX.m
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/1/13.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import "AMapNaviCarAnnotationX.h"

@implementation AMapNaviCarAnnotationX

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    if (self = [super init]) {
        self.coordinate = coordinate;
    }
    return self;
}

@end


#pragma -mark AMapNaviTimerTarget

@implementation AMapNaviTimerTargetX

- (void)moveCarLocationSmooth:(NSTimer *)timer {
    if (self.realTarget && [self.realTarget respondsToSelector:@selector(moveCarLocationSmooth:)]) {
        [self.realTarget performSelector:@selector(moveCarLocationSmooth:) withObject:timer];
    }
}

@end
