//
//  AMapNaviCarAnnotationViewX.h
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/1/13.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>

@interface AMapNaviCarAnnotationViewX : MAAnnotationView

@property (nonatomic, assign) BOOL showCompass;

@property (nonatomic, assign) double carDirection;  //车头方向
@property (nonatomic, assign) double compassDirection; //罗盘正北指的方向

- (void)setCarImage:(nullable UIImage *)carImage;
- (void)setCompassImage:(nullable UIImage *)compassImage;

@end
