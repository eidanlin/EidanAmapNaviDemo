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

#pragma mark - Options

///导航界面跟随模式,默认AMapNaviViewTrackingModeCarNorth（车头朝北）
@property (nonatomic, assign) AMapNaviViewTrackingMode trackingMode;

///导航界面显示模式,默认AMapNaviDriveViewShowModeCarPositionLocked
@property (nonatomic, assign) AMapNaviDriveViewShowMode showMode;

///是否显示界面元素,默认YES
@property (nonatomic, assign) BOOL showUIElements;

///是否显示摄像头,默认YES
@property (nonatomic, assign) BOOL showCamera;

///是否显示路口放大图,默认YES
@property (nonatomic, assign) BOOL showCrossImage;

///是否黑夜模式,默认NO. 对应的地图样式为:白天模式MAMapTypeNavi,黑夜模式MAMapTypeStandardNight.
@property (nonatomic, assign) BOOL showStandardNightType;

///是否显示全览按钮,默认YES
@property (nonatomic, assign) BOOL showBrowseRouteButton;

#warning 目前还没有完全实现，需要UI配合
///是否显示更多按钮,默认YES
@property (nonatomic, assign) BOOL showMoreButton;

///是否显示路况光柱,默认YES
@property (nonatomic, assign) BOOL showTrafficBar;

///是否显示实时交通按钮,默认YES
@property (nonatomic, assign) BOOL showTrafficButton;

///是否显示实时交通图层,默认YES
@property (nonatomic, assign) BOOL showTrafficLayer;

///是否显示转向箭头,默认YES
@property (nonatomic, assign) BOOL showTurnArrow;




///规划路径overlay的宽度
@property (nonatomic, assign) CGFloat lineWidth;

///锁车状态下地图cameraDegree, 默认30.0, 范围[0,60]
@property (nonatomic, assign) CGFloat cameraDegree;





///当前地图是否开启自定义样式, 默认NO. 设置为YES，将忽略showStandardNightType的设置，并将mapType切换为MAMapTypeStandard. 设置为NO，将根据showStandardNightType恢复mapType. since 5.1.0
@property (nonatomic, assign) BOOL customMapStyleEnabled;



@end


@protocol AMapNaviDriveViewXDelegate <NSObject>

@optional

/**
 * @brief 导航界面关闭按钮点击时的回调函数
 */
- (void)driveViewXCloseButtonClicked:(AMapNaviDriveViewX *)driveView;

@end
