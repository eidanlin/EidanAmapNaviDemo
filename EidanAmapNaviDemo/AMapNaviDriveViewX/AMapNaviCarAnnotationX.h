//
//  AMapNaviCarAnnotationX.h
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/1/13.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import <MAMapKit/MAAnnotation.h>

//typedef void (^AMapNaviCarAnnotationXStepCallback)(CGFloat timeDelta);

@interface AMapNaviCarAnnotationX : NSObject <MAAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

//@property (nonatomic, copy) AMapNaviCarAnnotationXStepCallback stepCallback;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@end


#pragma -mark AMapNaviTimerTargetX

@interface AMapNaviTimerTargetX : NSObject

@property (nonatomic, weak) id realTarget;

- (void)moveCarLocationSmooth:(NSTimer *)timer;

@end
