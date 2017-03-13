//
//  AMapNaviRouteAnnotationViewX.h
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/1/17.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import <MAMapKit/MAAnnotationView.h>
@class AMapNaviCameraInfo;

@interface AMapNaviCameraAnnotationViewX : MAAnnotationView

@end

@interface AMapNaviCameraTypeAnnotationViewX : MAAnnotationView

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier cameraInfo:(AMapNaviCameraInfo *)info andIndex:(int)index;

@end

@interface AMapNaviStartPointAnnotationViewX : MAAnnotationView

@end

@interface AMapNaviWayPointAnnotationViewX : MAAnnotationView

@end

@interface AMapNaviEndPointAnnotationViewX : MAAnnotationView

@end
