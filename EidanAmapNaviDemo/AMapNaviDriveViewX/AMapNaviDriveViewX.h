//
//  AMapNaviDriveViewX.h
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/1/13.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AMapNaviKit/AMapNaviKit.h>

@protocol AMapNaviDriveViewXDelegate;

@interface AMapNaviDriveViewX : UIView <AMapNaviDriveDataRepresentable>

@property (nonatomic, weak) id<AMapNaviDriveViewXDelegate> delegate;

///规划路径overlay的宽度
@property (nonatomic, assign) CGFloat lineWidth;

///锁车状态下地图cameraDegree, 默认30.0, 范围[0,60]
@property (nonatomic, assign) CGFloat cameraDegree;

///是否显示实时交通图层,默认YES
@property (nonatomic, assign) BOOL showTrafficLayer;

///导航界面显示模式,默认AMapNaviDriveViewShowModeCarPositionLocked
@property (nonatomic, assign) AMapNaviDriveViewShowMode showMode;  //不管什么模式，车一直都是在运动的，区分的只有地图的状态

//跟随模式：地图朝北，车头朝北,默认AMapNaviViewTrackingModeMapNorth
@property (nonatomic, assign) AMapNaviViewTrackingMode trackingMode;  //其实更改跟随模式，只在lockCarPosition为YES，即锁车显示模式才有效果，此时地图的状态是跟着变的，而如果showMode为其他显示模式，地图不跟着动，就无所谓怎么跟随了


@end


@protocol AMapNaviDriveViewXDelegate <NSObject>

@optional

/**
 * @brief 导航界面关闭按钮点击时的回调函数
 */
- (void)driveViewXCloseButtonClicked:(AMapNaviDriveViewX *)driveView;

@end
