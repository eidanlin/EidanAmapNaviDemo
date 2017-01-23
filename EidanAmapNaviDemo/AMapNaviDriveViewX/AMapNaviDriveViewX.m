//
//  AMapNaviDriveViewX.m
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/1/13.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import "AMapNaviDriveViewX.h"
#import <MAMapKit/MAMapKit.h>

#import "AMapNaviCarAnnotationX.h"
#import "AMapNaviCarAnnotationViewX.h"

#import "AMapNaviViewUtilityX.h"
#import "AMapNaviRouteAnnotationX.h"
#import "AMapNaviRouteAnnotationViewX.h"
#import "AMapNaviRoutePolylineX.h"

#define kAMapNaviMoveCarSplitCount              14  //值越大，车的运动越平滑
#define kAMapNaviMoveCarTimeInterval            (1.0/kAMapNaviMoveCarSplitCount)
#define kAMapNaviInternalAnimationDuration      0.2f

#define kAMapNaviLockStateZoomLevel             18.0f
#define kAMapNaviLockStateCameraDegree          30.0f

#define kAMapNaviTurnArrowDistance              40.0f
#define kAMapNaviShowTurnArrowMinZoomLevel      16.0f

#define kAMapNaviMoveDirectlyMaxDistance        300.0f
#define kAMapNaviMoveDirectlyMinDistance        1.0f

#define kAMapNaviRoutePolylineDefaultWidth      15.0f  //显示规划的路径的默认宽度

//views
#define KAMapNaviInfoViewTurnIconImage          @"default_navi_action_%ld"
#define kAMapNaviInfoViewBackgroundColor        [UIColor colorWithRed:40/255.0 green:44/255.0 blue:55/255.0 alpha:0.85]

@interface AMapNaviDriveViewX ()<MAMapViewDelegate>

//interface

///规划路径overlay的宽度
@property (nonatomic, assign) CGFloat lineWidth;

///是否显示实时交通图层,默认YES
@property (nonatomic, assign) BOOL showTrafficLayer;

///锁车状态下地图cameraDegree, 默认30.0, 范围[0,60]
@property (nonatomic, assign) CGFloat cameraDegree;

///导航界面显示模式,默认AMapNaviDriveViewShowModeCarPositionLocked
@property (nonatomic, assign) AMapNaviDriveViewShowMode showMode;  //不管什么模式，车一直都是在运动的，区分的只有地图的状态

//跟随模式：地图朝北，车头朝北
@property (nonatomic, assign) AMapNaviViewTrackingMode trackingMode;  //其实更改跟随模式，只在lockCarPosition为YES，即锁车显示模式才有效果，此时地图的状态是跟着变的，而如果showMode为其他显示模式，地图不跟着动，就无所谓怎么跟随了

//private
@property (nonatomic, assign) BOOL lockCarPosition;  //车相对屏幕的位置是否不改变，YES代表不改变，车永远在屏幕中间，那么就需要移动地图中心点，NO代表改变，不需要改变地图中心点.

//car
@property (nonatomic, strong) NSTimer *moveCarTimer;
@property (nonatomic, strong) AMapNaviCarAnnotationX *carAnnotation;
@property (nonatomic, strong) AMapNaviCarAnnotationViewX *carAnnotationView;

//car and map move
@property (nonatomic, assign) BOOL needMoving;  //车的位置和方向是否需要改变，规则是：每更新一次导航信息，被设置为YES，车被顺滑的移动14次后，又被设置为NO，不再移动，等待下一次的导航信息更新
@property (nonatomic, assign) BOOL moveDirectly;  //一开始导航的时候，车是否应该被一步到位的设置到指定的起点位置和指定方向，一步到位就是没有动画，直接跳过去。

@property (nonatomic, assign) NSInteger splitCount;
@property (nonatomic, assign) NSInteger stepCount;

@property (nonatomic, strong) AMapNaviPoint *priorPoint;
@property (nonatomic, assign) double priorCarDirection;
@property (nonatomic, assign) double priorZoomLevel;

@property (nonatomic, assign) double directionOffset;
@property (nonatomic, assign) double zoomLevelOffset;
@property (nonatomic, assign) double latOffset;
@property (nonatomic, assign) double lonOffset;

//Data Representable
@property (nonatomic, assign) AMapNaviMode currentNaviMode;
@property (nonatomic, copy) AMapNaviLocation *currentCarLocation;
@property (nonatomic, copy) AMapNaviInfo *currentNaviInfo;      //当前正在导航的这一个时间点的导航具体信息，会快速的变化
@property (nonatomic, copy) AMapNaviRoute *currentNaviRoute;  //当前需要导航的的一整条路径的信息，开始导航后，就不再改变
@property (nonatomic, copy) NSArray <AMapNaviTrafficStatus *> *trafficStatus;  //前方交通路况信息(长度和拥堵情况)

#pragma -mark xib views
@property (nonatomic, strong) IBOutlet UIView *customView;

//mapView
@property (nonatomic, weak) IBOutlet MAMapView *internalMapView;

//路口放大图相关
@property (nonatomic, weak) IBOutlet UIImageView *crossImageView;

//车道信息图
@property (nonatomic, weak) IBOutlet UIImageView *laneInfoView;

//topInfoView
@property (nonatomic, weak) IBOutlet UIView *topInfoView;
@property (nonatomic, weak) IBOutlet UIImageView *topTurnImageView;
@property (nonatomic, weak) IBOutlet UIImageView *topTurnSmallImageView;
@property (nonatomic, weak) IBOutlet UILabel *topTurnRemainLabel;
@property (nonatomic, weak) IBOutlet UILabel *topRoadLabel;

//bottomInfoView
@property (nonatomic, weak) IBOutlet UIView *bottomInfoView;
@property (nonatomic, weak) IBOutlet UIView *bottomRemainBgView;
@property (nonatomic, weak) IBOutlet UILabel *bottomRemainTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *bottomRemainDistanceLabel;
@property (nonatomic, weak) IBOutlet UIView *bottomContinueNaviBgView;


//leftTipsView
@property (nonatomic, weak) IBOutlet UIView *leftCameraInfoView;
@property (nonatomic, weak) IBOutlet UIImageView *leftCameraInfoImageView;
@property (nonatomic, weak) IBOutlet UIView *leftSpeedInfoView;
@property (nonatomic, weak) IBOutlet UILabel *leftSpeedInfoLabel;


//Constraint
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topInfoViewHeight;


@end

@implementation AMapNaviDriveViewX


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setUp];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)setUp {
    
    //public
    [[NSBundle mainBundle] loadNibNamed:@"AMapNaviDriveViewX" owner:self options:nil];
    [self addSubview:self.customView];
    self.customView.frame = self.bounds;
    
    //layoutConstraint
    [self configureTheConstraint];
    
    //property
    [self initProperties];
    
    //corssImageView
    [self configureCrossImageView];
    
    //laneInfoView
    [self configureLaneInfoView];
    
    //topInfoView
    [self configureTopInfoView];
    
    //bottomInfoView
    [self configureBottomInfoView];
    
    //leftInfoView
    [self configureLeftCameraAndSpeedView];
    
    //mapView
    [self configureMapView];
    
    //timer
    [self startMoveCarTimer];
    
}

//layoutConstraint
- (void)configureTheConstraint{
    
    //竖屏下，根据机型，改变topInfoView的高度
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {  //pad
        self.topInfoViewHeight.constant = 220;
    } else {
        float height = [UIScreen mainScreen].bounds.size.height;
        if (height == 667) {  //iphone7
            self.topInfoViewHeight.constant = 162.5;
        } else if (height == 736) {
            self.topInfoViewHeight.constant = 182;
        }
    }
    
}

- (void)initProperties {
    
    //public
    self.lineWidth = kAMapNaviRoutePolylineDefaultWidth;
    self.showTrafficLayer = YES;
    self.trackingMode = AMapNaviViewTrackingModeMapNorth;
    self.showMode = AMapNaviRideViewShowModeCarPositionLocked; //默认锁车模式，此时lockCarPosition为YES
    
    //car and map move
    self.splitCount = kAMapNaviMoveCarSplitCount;
    self.cameraDegree = kAMapNaviLockStateCameraDegree;
    self.needMoving = NO;
    self.moveDirectly = YES;
    
    //private
    self.lockCarPosition = YES;
    
}

- (void)layoutSubviews {
    self.customView.frame = self.bounds;
}

#pragma -mark 显示模式改变

//点击地图范围内，切换成普通模式
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (self.currentNaviRoute == nil) {   //没有路径信息，就证明还没开始导航
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    CGRect frame = self.internalMapView.frame;
    if (CGRectContainsRect(self.internalMapView.frame, self.bottomInfoView.frame)) { //地图有包含底部，证明是竖屏，要扣掉，横屏的话，没人遮挡地图，就不用处理
        frame = UIEdgeInsetsInsetRect(self.internalMapView.frame, UIEdgeInsetsMake(0, 0, self.bottomInfoView.bounds.size.height, 0));  //要扣掉底部view
    }
    
    //最后要实现的效果就是，判断这次的点击，是否在地图范围内，没有被其他视图遮挡
    if (CGRectContainsPoint(frame, point)) {
        self.showMode = AMapNaviRideViewShowModeNormal;
    }
    
}

- (void)setShowMode:(AMapNaviDriveViewShowMode)showMode {
    
    if (_showMode == showMode) {
        return;
    }
    
    _showMode = showMode;
    
    if (showMode == AMapNaviRideViewShowModeNormal) {
        [self handleShowModeToNormal];
    } else if (showMode == AMapNaviRideViewShowModeCarPositionLocked) {
        [self handleShowModeToLockedCarPosition];
    }
}

- (void)handleShowModeToNormal {
    self.lockCarPosition = NO;
    self.bottomRemainBgView.hidden = YES;
    self.bottomContinueNaviBgView.hidden = NO;
}

- (void)handleShowModeToLockedCarPosition {
    self.lockCarPosition = YES;
    [self updateBottomInfoView];
    self.bottomContinueNaviBgView.hidden = YES;
    
    //恢复锁车模式，设置地图为正确状态
    if (self.carAnnotation) {
        [self changeToNaviModeAtPoint:[AMapNaviPoint locationWithLatitude:self.carAnnotation.coordinate.latitude longitude:self.carAnnotation.coordinate.longitude]];
    }
}


#pragma -mark car timer

- (void)startMoveCarTimer {
    [self stopMoveCarTimer];
    
    //先不管循环引用
    self.moveCarTimer = [NSTimer scheduledTimerWithTimeInterval:kAMapNaviMoveCarTimeInterval target:self selector:@selector(moveCarLocationSmooth:) userInfo:nil repeats:YES];
}

- (void)stopMoveCarTimer {
    [self.moveCarTimer invalidate];
    self.moveCarTimer = nil;
}

#pragma -mark 车、角度和地图中心点的的移动

- (void)moveCarLocationSmooth:(NSTimer *)timer {
    
    if (self.needMoving == NO) {
        return;
    }
    
    if (self.moveDirectly) {  //moveDirectly只有初始化的时候被设置为YES，然后车被一步到位的移动到指定位置后，就设置为No，所以这个分支最多只会执行一次
        double desLat = self.priorPoint.latitude + self.latOffset * self.splitCount;
        double desLon = self.priorPoint.longitude + self.lonOffset * self.splitCount;
        double desDirection = self.priorCarDirection + self.directionOffset * self.splitCount;
        
        double mapViewRotationDegree = 0;
        if (self.trackingMode == AMapNaviViewTrackingModeMapNorth) { //地图方向不变，一直朝北，车头方向改变
            mapViewRotationDegree = 0;
        } else if (self.trackingMode == AMapNaviViewTrackingModeCarNorth ) {  //车头方向不变，一直朝北，地图方向改变
            mapViewRotationDegree = desDirection;
        }
        
        if (self.lockCarPosition) {
            [self.internalMapView setRotationDegree:mapViewRotationDegree animated:YES duration:kAMapNaviInternalAnimationDuration];  //一次性执行，animated:可设置为YES。
            [self.internalMapView setCenterCoordinate:CLLocationCoordinate2DMake(desLat, desLon) animated:YES];
        }
        
        [self.carAnnotation setCoordinate:CLLocationCoordinate2DMake(desLat, desLon)];
        [self.carAnnotationView setCarDirection:desDirection];
        [self.carAnnotationView setCompassDirection:0];
        
        
        self.stepCount = 0;
        self.needMoving = NO;
        self.moveDirectly = NO;
        
        return;
    }

    //定时器1秒14次，14次设置车的位置和方向，然后self.needMoving为NO，这边就不再走了，等到下一次“导航信息被更新了”，self.needMoving又被设置为YES了，然后这边又开始设置车的位置和方向
    if (self.stepCount++ < self.splitCount) {
        double stepLat = self.priorPoint.latitude + self.latOffset * self.stepCount;
        double stepLon = self.priorPoint.longitude + self.lonOffset * self.stepCount;
        double stepDirection = self.priorCarDirection + self.directionOffset * self.stepCount;
        
        double mapViewRotationDegree = 0;
        if (self.trackingMode == AMapNaviViewTrackingModeMapNorth) { //地图方向不变，一直朝北，车头方向改变
            mapViewRotationDegree = 0;
        } else if (self.trackingMode == AMapNaviViewTrackingModeCarNorth ) {  //车头相对屏幕的方向不变，一直朝北，地图方向改变
            mapViewRotationDegree = stepDirection;
        }
        
        if (self.lockCarPosition) {
            [self.internalMapView setRotationDegree:mapViewRotationDegree animated:NO duration:kAMapNaviInternalAnimationDuration]; //旋转角度animated:必须为NO，否则卡顿
            [self.internalMapView setCenterCoordinate:CLLocationCoordinate2DMake(stepLat, stepLon) animated:NO]; //这边地图中心点的移动animated:必须为NO，否则会有卡顿的感觉
        }
    
        [self.carAnnotation setCoordinate:CLLocationCoordinate2DMake(stepLat, stepLon)];
        [self.carAnnotationView setCarDirection:stepDirection];  //无论哪种跟随模式，车在地图上的方向都要改变，来适应一直车头对着道路前进的方向
        [self.carAnnotationView setCompassDirection:0];  //无论哪种跟随模式，车的罗盘的方向的北一直和地图上指南针的北指向同一个方向，因为setCarDirection已经做了改变，让carAnnotationView整体改变，所以这边一直保持为0
        
    } else {
        self.stepCount = 0;
        self.needMoving = NO;
    }
    
}

//路径信息更新后的设置
- (void)changeToNaviModeAtPoint:(AMapNaviPoint *)point {
    
    if (point == nil) return;
    
    [self.internalMapView setCameraDegree:self.cameraDegree animated:YES duration:kAMapNaviInternalAnimationDuration];
    [self.internalMapView setCenterCoordinate:CLLocationCoordinate2DMake(point.latitude, point.longitude) animated:YES];
    [self.internalMapView setZoomLevel:kAMapNaviLockStateZoomLevel animated:NO]; //为NO，为YES的话，第一个转弯路口没有箭头overlay，因为zoomLevel不对，被return回来了
}

//上一次导航信息更新后的一些信息记录为prior，通过这一次导航信息和上一次信息的差值除于14，表示每一次设置的单位量，timer中就会每一次增加一个单位量，来平滑的做动画.
- (void)moveCarToCoordinate:(AMapNaviPoint *)coordinate direction:(double)direction zoomLevel:(double)zoomLevle {
    
    if (coordinate == nil || coordinate.latitude == 0 || coordinate.longitude == 0) {
        return;
    }
    
    self.priorPoint = [AMapNaviPoint locationWithLatitude:self.carAnnotation.coordinate.latitude longitude:self.carAnnotation.coordinate.longitude];
    self.priorCarDirection = self.carAnnotationView.carDirection;
    self.priorZoomLevel = self.internalMapView.zoomLevel;
    
    //每一次导航信息更新的位置等信息被拆分为14份，让1秒内的14次timer调用，每次执行加1份，动画才能顺
    self.stepCount = 0;
    self.latOffset = (coordinate.latitude - self.priorPoint.latitude) / self.splitCount;  //1个单位的delta
    self.lonOffset = (coordinate.longitude - self.priorPoint.longitude) / self.splitCount;
    self.directionOffset = [self normalizeOffsetDegree:(direction - self.priorCarDirection)] / self.splitCount;
    self.zoomLevelOffset = (zoomLevle - self.priorZoomLevel) / self.splitCount;
    
    self.needMoving = YES;
    
}

#pragma -mark AMapNaviDriveDataRepresentable

//导航模式更新，停止导航，开始GPS导航，开始模拟导航，的时候才会调用一次
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateNaviMode:(AMapNaviMode)naviMode {
    NSLog(@"导航模式更新");
    self.currentNaviMode = naviMode;
    self.moveDirectly = YES;
}

//路径信息更新：每次换路后，开始导航的时候才会调用一次(或者两次)，可用来设置这次导航路线的起点，让地图的初始位置正确，电子眼的初始化
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateNaviRoute:(AMapNaviRoute *)naviRoute {
    
    NSLog(@"路径信息更新");
    
    self.currentNaviRoute = naviRoute;
    
    //画出规划的路径，一般在这里画的路径都是不带路况信息，因为路况信息的回调还没调用。
    [self updateRoutePolyline];
    
    //起点，终点，沿途的点的绘制
    [self updateRoutePointAnnotation];
    
    //更新电子眼信息
    [self updateRouteCameraAnnotationWithStartIndex:0];
    
    //地图的中心点，缩放级别，摄像机角度
    [self changeToNaviModeAtPoint:self.currentNaviRoute.routeStartPoint];
    
    //更新转向箭头，这里的显示与否有取决于zoomLevel,所以必须在changeToNaviModeAtPoint先把zoomLebel设定对了，再执行这个函数，第一个路口才会有箭头，而且changeToNaviModeAtPoint里面setZoomLevel不能有动画
    [self updateRouteTurnArrowPolylineWithSegmentIndex:0];

}

//导航实时信息更新，如果是模拟导航，自车位置开始一段时间后，就不再更新，但是导航实时信息一直在更新，所以模拟导航以这个回调为准
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateNaviInfo:(AMapNaviInfo *)naviInfo {
    NSLog(@"导航信息更新");
    
    //第一次没有self.currentNaviInfo需要，上一次导航信息的摄像头索引和这次的不一样也需要。
    BOOL isNeedUpdateCamera = self.currentNaviInfo ? (self.currentNaviInfo.cameraIndex != naviInfo.cameraIndex) : YES;
    BOOL isNeedUpdateTurnArrow = self.currentNaviInfo ? (self.currentNaviInfo.currentSegmentIndex != naviInfo.currentSegmentIndex) : YES;
    
    self.currentNaviInfo = naviInfo;
    
    //InfoView
    [self updateTopInfoView];
    [self updateBottomInfoView];
    [self updateLeftCameraAndSpeedView];
    
    //每路过一个电子眼后，“导航信息更新”这个回调就会被触发调用一次，cameraIndex也会不一样，就需要更新电子眼信息。
    if (isNeedUpdateCamera) {
        [self updateRouteCameraAnnotationWithStartIndex:self.currentNaviInfo.cameraIndex];
    }
    
    //每路过一个转弯，“导航信息更新”这个回调就会被触发调用一次，currentSegmentIndex也会不一样，就需要更新转弯信息，每一个Segment就是一个个转弯分割的
    //currentSegmentIndex表示当前车所在的分段的索引，其对应的转弯路口，就是该分段到下一分段的转弯
    if (isNeedUpdateTurnArrow) {
        [self updateRouteTurnArrowPolylineWithSegmentIndex:self.currentNaviInfo.currentSegmentIndex];
    }
    
    //保持carAnnotationView在最上层显示，不然可能被新添加的箭头，电子眼图标等覆盖
    if (self.carAnnotation == nil) {
        return;
    } else {
        [self.carAnnotationView.superview bringSubviewToFront:self.carAnnotationView];
    }
    
    //更新地图显示
    if (self.currentNaviMode == AMapNaviModeEmulator) {
        
        //因为初始化的时候self.moveDirectly设置为YES，timer中会直接一步到位的把车的位置和方向设置对了，比如你在楼里，导航开始的点离你比较远，会一直跳跃感。
        //这边需要算一下用户目前的位置和实际开始导航的起点的位置的距离，如果在300米以内，就将moveDirectly设置为NO，表示，timer中不需要移动地图上车的位置（300米这个误差，在地图上显示的感知比较小），如果大于300米，timer中会移动车的位置到指定地点，移动到后也会设置为NO，再也不会设置YES了，这个分支只会走一次。
        if (self.moveDirectly) {
            double distance = [AMapNaviViewUtilityX calcDistanceBetweenPoint:self.currentNaviInfo.carCoordinate andPoint:[AMapNaviPoint locationWithLatitude:self.carAnnotation.coordinate.latitude longitude:self.carAnnotation.coordinate.longitude]];
            if (distance <= kAMapNaviMoveDirectlyMaxDistance && distance > kAMapNaviMoveDirectlyMinDistance) {
                self.moveDirectly = NO;
            }
        }
        
        //每一次导航信息更新后，都算一下，车应该以什么样的角度显示在地图的哪个地方，needMoving 设置为YES。
        [self moveCarToCoordinate:self.currentNaviInfo.carCoordinate direction:self.currentNaviInfo.carDirection zoomLevel:kAMapNaviLockStateZoomLevel];
        
    }
}

//自车位置更新。模拟导航自车位置不会一直更新，GPS导航自车位置才能一直更新
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateNaviLocation:(AMapNaviLocation *)naviLocation {
//    NSLog(@"自车位置更新");
    
    self.currentCarLocation = naviLocation;
    
    if (self.carAnnotation == nil) {
        return;
    }
}

//路况信息更新
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateTrafficStatus:(NSArray<AMapNaviTrafficStatus *> *)trafficStatus {
//    NSLog(@"路况信息更新");
    
    self.trafficStatus = trafficStatus;
    
    if (self.showTrafficLayer) { //需要显示带路况
        [self updateRoutePolyline]; //如果路况信息更新了，带拥堵情况路径也要重新画，有了路况信息，才能画带路况的。
    }
}

//需要显示路口放大图了
- (void)driveManager:(AMapNaviDriveManager *)driveManager showCrossImage:(UIImage *)crossImage {
    
    if (crossImage) {
        self.crossImageView.image = crossImage;
        self.crossImageView.hidden = NO;
    }
    
}

//需要把路口放大图了隐藏了
- (void)driveManagerHideCrossImage:(AMapNaviDriveManager *)driveManager {
    
    self.crossImageView.image = nil;
    self.crossImageView.hidden = YES;
    
}

//需要显示车道信息了
- (void)driveManager:(AMapNaviDriveManager *)driveManager showLaneBackInfo:(NSString *)laneBackInfo laneSelectInfo:(NSString *)laneSelectInfo {
    
    UIImage *image = CreateLaneInfoImageWithLaneInfo(laneBackInfo, laneSelectInfo);
    if (image) {
        self.laneInfoView.image = image;
        self.laneInfoView.hidden = NO;
    }
}

//需要隐藏车道信息
- (void)driveManagerHideLaneInfo:(AMapNaviDriveManager *)driveManager {
    
    self.laneInfoView.image = nil;
    self.laneInfoView.hidden = YES;
}


#pragma -mark Private: Component

//初始化 车标注，指定初始位置，添加到地图
- (AMapNaviCarAnnotationX *)carAnnotation {
    if (_carAnnotation == nil) {
        AMapNaviPoint *coordinate = nil;
        
        if (self.currentNaviMode == AMapNaviModeEmulator) {
            if (self.currentNaviInfo) {
                coordinate = self.currentNaviInfo.carCoordinate;
            } else if (self.currentCarLocation) {
                coordinate = self.currentCarLocation.coordinate;
            }
        } else {
            
        }
        
        if (coordinate == nil) {
            return nil;
        }
        
        _carAnnotation = [AMapNaviCarAnnotationX new];
        [_carAnnotation setCoordinate:CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude)];
        
        [self.internalMapView addAnnotation:_carAnnotation];
        [self.internalMapView selectAnnotation:_carAnnotation animated:NO];
        
    }
    return _carAnnotation;
}

- (double)normalizeOffsetDegree:(double)degree {
    return degree + ((degree > 180.f) ? -360.f : (degree < -180.f) ? 360.f : 0);
}

#pragma -mark MapView

- (void)configureMapView {
    
    self.internalMapView.showsScale = NO;
    self.internalMapView.showsIndoorMap = NO;
    self.internalMapView.showsBuildings = NO;
    self.internalMapView.maxRenderFrame = 30;
    self.internalMapView.isAllowDecreaseFrame = NO;  //不允许降帧，否则地图一段时间不动的情况下，会被降帧，车的移动就会出现卡顿
    self.internalMapView.delegate = self;
    self.internalMapView.zoomLevel = 11.1;
    self.internalMapView.centerCoordinate = CLLocationCoordinate2DMake(39.906207, 116.397582);
    self.internalMapView.showTraffic = self.showTrafficLayer;
    
    [self.internalMapView removeOverlays:self.internalMapView.overlays];
    [self.internalMapView removeAnnotations:self.internalMapView.annotations];
}

#pragma -mark 路口放大图 

- (void)configureCrossImageView {
    self.crossImageView.hidden = YES;
}

#pragma -mark 车道信息图 

- (void)configureLaneInfoView {
    self.laneInfoView.hidden = YES;
}

#pragma -mark topInfoView

- (void)configureTopInfoView {
    self.topInfoView.superview.backgroundColor = kAMapNaviInfoViewBackgroundColor;
    self.topInfoView.hidden = YES;
}

- (void)updateTopInfoView {
    if (self.currentNaviInfo) {
        
        self.topTurnRemainLabel.text = [NSString stringWithFormat:@"%@后",[AMapNaviViewUtilityX normalizedRemainDistance:self.currentNaviInfo.segmentRemainDistance]];
        self.topRoadLabel.text = self.currentNaviInfo.nextRoadName;
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:KAMapNaviInfoViewTurnIconImage,self.currentNaviInfo.iconType]];
        if (image == nil) {
            image = [UIImage imageNamed:[NSString stringWithFormat:KAMapNaviInfoViewTurnIconImage,AMapNaviIconTypeStraight]];
        }
        self.topTurnImageView.image = image;
        self.topTurnSmallImageView.image = image;
        
        if (self.topInfoView.hidden == YES) {
            self.topInfoView.hidden = NO;
        }
    } else {
        if (self.topInfoView.hidden == NO) {
            self.topInfoView.hidden = YES;
        }
    }
}

#pragma -mark bottomInfoView

- (void)configureBottomInfoView {
    self.bottomInfoView.backgroundColor = kAMapNaviInfoViewBackgroundColor;
    self.bottomRemainBgView.hidden = YES;
    self.bottomContinueNaviBgView.hidden = YES;
}

- (void)updateBottomInfoView {
    if (self.currentNaviInfo && self.showMode == AMapNaviRideViewShowModeCarPositionLocked) {  //如果不是锁车状态，bottomRemainBgView不应该显示
        
        self.bottomRemainTimeLabel.text = [AMapNaviViewUtilityX normalizedRemainTime:self.currentNaviInfo.routeRemainTime];
        self.bottomRemainDistanceLabel.text = [AMapNaviViewUtilityX normalizedRemainDistance:self.currentNaviInfo.routeRemainDistance];
        
        if (self.bottomRemainBgView.hidden == YES) {
            self.bottomRemainBgView.hidden = NO;
        }
    } else {
        
        if (self.bottomRemainBgView.hidden == NO) {
            self.bottomRemainBgView.hidden = YES;
        }
        
    }
}

#pragma -mark LeftCameraAndSpeedView

- (void)configureLeftCameraAndSpeedView {
    self.leftSpeedInfoView.hidden = self.leftCameraInfoView.hidden = YES;
}


- (void)updateLeftCameraAndSpeedView {
    
    //限速也是电子眼信息中的
    if (self.currentNaviInfo.cameraDistance > 0) {
        
        if (self.currentNaviInfo.cameraType == 0 && self.currentNaviInfo.cameraLimitSpeed > 0) {  //cameraType 0为测速摄像头，且有限速
            self.leftSpeedInfoLabel.text = [NSString stringWithFormat:@"%ld",(long)self.currentNaviInfo.cameraLimitSpeed];
            self.leftSpeedInfoView.hidden = NO;
            self.leftCameraInfoView.hidden = YES;
        } else if (self.currentNaviInfo.cameraType >= 1) {  //监控摄像头
            NSString *imageName = self.currentNaviInfo.cameraType == 1 ? @"default_navi_camera" : @"default_navi_camera_content_normal";
            self.leftCameraInfoImageView.image = [UIImage imageNamed:imageName];
            self.leftSpeedInfoView.hidden = YES;
            self.leftCameraInfoView.hidden = NO;
        }
        
    } else {  //电子眼距离(<=0 为没有电子眼或距离很远)
        self.leftCameraInfoView.hidden = self.leftSpeedInfoView.hidden = YES;
    }
}

#pragma -mark xib btns click

- (IBAction)moreBtnClick:(id)sender {

    //更改跟随模式
    if (self.trackingMode == AMapNaviViewTrackingModeMapNorth) {
        self.trackingMode = AMapNaviViewTrackingModeCarNorth;
    } else if (self.trackingMode == AMapNaviViewTrackingModeCarNorth) {
        self.trackingMode = AMapNaviViewTrackingModeMapNorth;
    }
}

- (IBAction)continueNaviBtnClick:(id)sender {
    self.showMode = AMapNaviRideViewShowModeCarPositionLocked;
}


- (IBAction)goBack:(id)sender {
    
}

#pragma mark - 路径信息更新后，才会更新的起点，终点，途径点

- (void)updateRoutePointAnnotation {
    
    if (self.currentNaviRoute == nil) {  //没有路径，就无从显示
        return;
    }
    
    [self removeNaviRoutePointAnnotation];
    
    //StartPoint
    AMapNaviPoint *startPoint = self.currentNaviRoute.routeStartPoint;
    CLLocationCoordinate2D start = CLLocationCoordinate2DMake(startPoint.latitude, startPoint.longitude);
    AMapNaviStartPointAnnotationX *startAnnotation = [[AMapNaviStartPointAnnotationX alloc] initWithCoordinate:start];
    [self.internalMapView addAnnotation:startAnnotation];
    
    //EndPoint
    AMapNaviPoint *endPoint = self.currentNaviRoute.routeEndPoint;
    CLLocationCoordinate2D end = CLLocationCoordinate2DMake(endPoint.latitude, endPoint.longitude);
    AMapNaviEndPointAnnotationX *endAnnotation = [[AMapNaviEndPointAnnotationX alloc] initWithCoordinate:end];
    [self.internalMapView addAnnotation:endAnnotation];
    
    //WayPoints
    if (self.currentNaviRoute.wayPoints != nil) {
        [self.currentNaviRoute.wayPoints enumerateObjectsUsingBlock:^(AMapNaviPoint *aCoordinate, NSUInteger idx, BOOL *stop) {
            CLLocationCoordinate2D way = CLLocationCoordinate2DMake(aCoordinate.latitude, aCoordinate.longitude);
            AMapNaviWayPointAnnotationX *wayAnnotation = [[AMapNaviWayPointAnnotationX alloc] initWithCoordinate:way];
            [self.internalMapView addAnnotation:wayAnnotation];
        }];
    }
    
}

- (void)removeNaviRoutePointAnnotation {
    [self.internalMapView.annotations enumerateObjectsUsingBlock:^(id<MAAnnotation> obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[AMapNaviStartPointAnnotationX class]] || [obj isKindOfClass:[AMapNaviWayPointAnnotationX class]] || [obj isKindOfClass:[AMapNaviEndPointAnnotationX class]]) {
            [self.internalMapView removeAnnotation:obj];
        }
    }];
}

#pragma mark - 更新电子眼信息

- (void)updateRouteCameraAnnotationWithStartIndex:(NSInteger)startIndex {
    
    [self removeRouteCameraAnnotation];  //每次更新前，先全部移除所有电子眼
    
    int index = (int)startIndex;
    
    while (index < self.currentNaviRoute.routeCameras.count && index < startIndex + 2) {  //只更新当前的电子眼信息，和当前的下一个，每次更新，只更新最近的这两个
        AMapNaviCameraInfo *aCamera = [self.currentNaviRoute.routeCameras objectAtIndex:index];
        
        AMapNaviCameraAnnotationX *anno = [AMapNaviCameraAnnotationX new];
        [anno setCoordinate:CLLocationCoordinate2DMake(aCamera.coordinate.latitude, aCamera.coordinate.longitude)];
        [self.internalMapView addAnnotation:anno];
        
        index++;
    }
}

- (void)removeRouteCameraAnnotation {
    [self.internalMapView.annotations enumerateObjectsUsingBlock:^(id<MAAnnotation> obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[AMapNaviCameraAnnotationX class]]) {
            [self.internalMapView removeAnnotation:obj];
        }
    }];
}

#pragma mark - 更新转弯的箭头信息，每一个分段AMapNaviSegment，就是由一个个拐弯分割的

- (void)updateRouteTurnArrowPolylineWithSegmentIndex:(NSInteger)segmentIndex {
    
    [self removeRouteTurnArrowPolyline];
    
    if (self.currentNaviRoute == nil) {
        return;
    }
    
    if (segmentIndex < 0 || segmentIndex >= self.currentNaviRoute.routeSegmentCount - 1) {  //最后一个分段也不用更新
        return;
    }
    
    //如果用户把地图缩放得很小，箭头的宽度还是那么大，覆盖了地图的区域就很大了，不精确了，就没有指导意义了
    if (self.internalMapView.zoomLevel < kAMapNaviShowTurnArrowMinZoomLevel) {
        return;
    }
    
    //获得要绘制的箭头的经纬度点的集合
    NSArray <AMapNaviPoint *> *coordinateArray = [self getRouteTurnArrowPolylineWithSegmentIndex:segmentIndex];
    
    if (coordinateArray.count == 0) {
        return;
    }
    
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)malloc(coordinateArray.count * sizeof(CLLocationCoordinate2D));
    for (int i = 0; i < coordinateArray.count; i++) {
        AMapNaviPoint *aCoordinate = [coordinateArray objectAtIndex:i];
        coordinates[i] = CLLocationCoordinate2DMake(aCoordinate.latitude, aCoordinate.longitude);
    }
    
    AMapNaviRouteTurnArrowPolylineX *turnArrowPolyline = [AMapNaviRouteTurnArrowPolylineX polylineWithCoordinates:coordinates count:coordinateArray.count];
    
    free(coordinates);
    
    [self.internalMapView addOverlay:turnArrowPolyline level:MAOverlayLevelAboveRoads];
    
}

//每一个转弯都是由这个路段的尾部一些坐标点和下一个路段的头部一些坐标点构成，转弯前40米，转弯后40米，一共80米构成。
- (NSArray<AMapNaviPoint *> *)getRouteTurnArrowPolylineWithSegmentIndex:(NSInteger)segmentIndex {
    
    NSArray<AMapNaviPoint *> *curSegCoor = self.currentNaviRoute.routeSegments[segmentIndex].coordinates;
    NSArray<AMapNaviPoint *> *nextSegCoor = self.currentNaviRoute.routeSegments[segmentIndex + 1].coordinates;
    
    if (curSegCoor.count == 0 || nextSegCoor.count == 0) {
        return nil;
    }
    
    NSMutableArray <AMapNaviPoint *> *resultArray = [NSMutableArray new];
    
    //当前路段：转弯前
    double curSegmentLength = 0;
    [resultArray addObject:curSegCoor.lastObject];  //当前路段的最后一个点
    
    for (NSInteger i = curSegCoor.count - 1; i > 0; i --) {  //离路口越来越远的点
        
        double dis = [AMapNaviViewUtilityX calcDistanceBetweenPoint:curSegCoor[i] andPoint:curSegCoor[i - 1]];
        
        if (curSegmentLength + dis > kAMapNaviTurnArrowDistance) {  //如果curSegmentLength已经为30米，这次的dis为15米，那么就为45米，那我们找到40米的那个经纬度添加进数组后，就可以break
            
            double remainDis = kAMapNaviTurnArrowDistance - curSegmentLength; //剩下的10米
            double remainRate = remainDis / dis; //剩下的百分比
            
            AMapNaviPoint *point = [AMapNaviViewUtilityX calcPointWithStartPoint:curSegCoor[i] endPoint:curSegCoor[i - 1] rate:remainRate]; //根据两点和百分比，算出点的坐标，百分比是相对起点而言
            
            [resultArray insertObject:point atIndex:0];  //当前路段中 ，离路口越远的，在数组中越靠前，这才符合车的行进中遇到的点的先后顺序
            
            break;
        }
        
        curSegmentLength += dis; //能走到这里，证明 curSegmentLength + dis小于40，先把这个点插入进去
        [resultArray insertObject:curSegCoor[i - 1] atIndex:0];
        
    }
    
    //下一路段：转弯后
    double nextSegmentLength = 0;
    [resultArray addObject:nextSegCoor.firstObject];  //转弯后的路段的第一个点
    
    for (NSInteger i = 0; i < nextSegCoor.count - 1; i ++) {
        
        double dis = [AMapNaviViewUtilityX calcDistanceBetweenPoint:nextSegCoor[i] andPoint:nextSegCoor[i + 1]];
        
        if (nextSegmentLength + dis > kAMapNaviTurnArrowDistance) {
            
            double remainDis = kAMapNaviTurnArrowDistance - nextSegmentLength;
            double remainRate = remainDis / dis;
            
            AMapNaviPoint *point = [AMapNaviViewUtilityX calcPointWithStartPoint:nextSegCoor[i] endPoint:nextSegCoor[i + 1] rate:remainRate];
            
            [resultArray addObject:point];  //当前路段中 ，离路口越远的，在数组中越靠后，这才符合车的行进中遇到的点的先后顺序
            
            break;
        }
        
        nextSegmentLength += dis;
        [resultArray addObject:nextSegCoor[i + 1]];
        
    }
    
    return resultArray;
    
}

- (void)removeRouteTurnArrowPolyline {
    [self.internalMapView.overlays enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[AMapNaviRouteTurnArrowPolylineX class]]) {
            [self.internalMapView removeOverlay:obj];
        }
    }];
}

#pragma mark - 路径信息更新后，画出规划的路径

- (void)updateRoutePolyline {
    
    if (self.currentNaviRoute == nil || self.currentNaviRoute.routeCoordinates.count < 1) {  //路径的点至少要有一个
        return;
    }
    
    [self removeRoutePolyline];
    
    if (self.showTrafficLayer && self.trafficStatus.count) {  //有路况信息，才能显示带路况的路径
        [self addRoutePolylineWithTrafficStatus];
    } else {
        [self addRoutePolylineWithoutTrafficStatus];
    }
    
    if (self.currentNaviInfo) {  //为了让转弯箭头在路径上层，不被遮挡，每次更新路径，都要让转弯箭头重新画
        [self updateRouteTurnArrowPolylineWithSegmentIndex:self.currentNaviInfo.currentSegmentIndex];
    }
}

- (void)removeRoutePolyline {
    [self.internalMapView.overlays enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[AMapNaviRoutePolylineX class]]) {
            [self.internalMapView removeOverlay:obj];
        }
    }];
}

//假设规划的路径一共有7个坐标点ABCDEFG，但是路况是A到E`之间是顺畅的，E`到G`是拥堵的，那么想画出路况的polyline，必须重新生成坐标点E`（D和E之间）,G`（F和G之间）并插入
//构成了A B C D E` E F G` G，BCDEF也不能舍弃，因为BCD之间可能有转弯，他们代表了原来的道路信息，如果删除了，A直接到 E`可能就不是沿着道路了，而是直接拉了一根直线
//drawStyleIndexes就比较简单了，只要知道E`的索引位置4，G`的索引位置因为她才是改变路况的点，即@[@4,@7]
- (void)addRoutePolylineWithTrafficStatus {
    
    NSArray *oriCoordinateArray = [self.currentNaviRoute.routeCoordinates copy];
    
    NSMutableArray *resultCoordinateArray = [NSMutableArray new];
    
    NSMutableArray *resultDrawStyleIndexArray = [NSMutableArray new];
    
    NSMutableArray *resultTextureImagesArray = [NSMutableArray new];
    
    [resultCoordinateArray addObject:oriCoordinateArray.firstObject];  //起点A
    
    NSInteger i = 1;
    NSInteger sumLength = 0;
    NSInteger statusesIndex = 0;  //交通状态数组的索引
    NSInteger currentTrafficLength = self.trafficStatus.firstObject.length; //A到E`的长度
    
    for (; i < oriCoordinateArray.count ; i ++) {
        
        double segmenLength = [AMapNaviViewUtilityX calcDistanceBetweenPoint:oriCoordinateArray[i - 1] andPoint:oriCoordinateArray[i]]; //A到B的长度，B到C，C到D，D到E,第二个循环：E到F,F到G
        
        if (sumLength + segmenLength >= currentTrafficLength) { //A到E的长度大于A到E`的长度，即E`在E前面，那么先算出E`，插入进去，再插入E。第二个循环E`G的长度大于E`G`的长度，先算出G`
            
            if (sumLength + segmenLength == currentTrafficLength) { //E`和E重合
                [resultCoordinateArray addObject:oriCoordinateArray[i]];
                [resultDrawStyleIndexArray addObject:@(resultCoordinateArray.count - 1)];  //因为E(E`)刚被加进去，为数组的最后一个，它的索引就是数组的长度减1
            } else {
               
                double rate = 0;
                if (segmenLength != 0) {
                    //想知道E` 的位置，必须知道 DE` / DE的比例，D(oriCoordinateArray[i - 1])，E(oriCoordinateArray[i])的位置。而DE' = AE｀－AD 即，currentTrafficLength - sumLength
                    rate = (currentTrafficLength - sumLength) / segmenLength;
                }
                
                AMapNaviPoint *trafficKeyPoint = [AMapNaviViewUtilityX calcPointWithStartPoint:oriCoordinateArray[i - 1] endPoint:oriCoordinateArray[i] rate:rate];  //算出E`,G`
                
                if (trafficKeyPoint) {  //E`存在
                    [resultCoordinateArray addObject:trafficKeyPoint];  //插入E`,G`
                    [resultDrawStyleIndexArray addObject:@(resultCoordinateArray.count - 1)];  //因为E`刚被加进去，为数组的最后一个，它的索引就是数组的长度减1
                    [resultCoordinateArray addObject:oriCoordinateArray[i]];  //插入E,G
                } else { //E`不存在，直接插入E
                    [resultCoordinateArray addObject:oriCoordinateArray[i]];  //插入E
                    [resultDrawStyleIndexArray addObject:@(resultCoordinateArray.count - 1)];
                }
                
            }
            
            //现在开始插入AE`的路况信息，第二个循环插入 E`G`的路况信息
            UIImage *image = [self defaultTextureImageForRouteStatus:self.trafficStatus[statusesIndex].status]; //AE`的纹理
            [resultTextureImagesArray addObject:image];
            
            //到此，就当AE`不存在了，E` E F G` G又是下一个循环
            sumLength = sumLength + segmenLength - currentTrafficLength; //E`E的长度，这样才能开始新的循环，计算E`E+EF和E`G`的长度关系
            
            statusesIndex++;
            
            if (statusesIndex >= self.trafficStatus.count) {
                break;  // 所有交通状态都取完了，终止for的所有循环
            }
            
            currentTrafficLength = self.trafficStatus[statusesIndex].length; //E`G`的长度，第二个交通状态的长度.
            
        } else { //A到B的长度，A到C的长度，A到D的长度，都小于A到E`的长度，即E`在D后面，那么B，C，D，都先加入进去。第二个循环的时候，E`到F的长度小于E`到G`长度，那么F先加入进去
            [resultCoordinateArray addObject:oriCoordinateArray[i]];
            sumLength += segmenLength;  //sumLength此时为A到D长度,第二个循环的时候，sumLength为E`到F的长度，因为F也可以直接加进去
        }
        
    }
    
    NSLog(@"addFF : %ld,%lu,%lu,%lu",(long)i,(unsigned long)oriCoordinateArray.count,(unsigned long)self.trafficStatus.count,(unsigned long)resultDrawStyleIndexArray.count);
    
    //以下这部分终点的处理，目前没测出效果
    //经过上面的循环可能存在一些末尾的点没有添加的情况，总之要将最后一个点对齐到路径终点
    if (i < oriCoordinateArray.count) {
        
        while (i < oriCoordinateArray.count) { //如果末尾的点没有加进来，那么加进来
            [resultCoordinateArray addObject:[oriCoordinateArray objectAtIndex:i]];
            i++;
        }
        
        [resultDrawStyleIndexArray removeLastObject];
        [resultDrawStyleIndexArray addObject:@(resultCoordinateArray.count - 1)];
        
    } else {
        while (resultDrawStyleIndexArray.count - 1 >= self.trafficStatus.count) {
            [resultDrawStyleIndexArray removeLastObject];
            [resultTextureImagesArray removeLastObject];
        }
        
        [resultDrawStyleIndexArray addObject:@(resultCoordinateArray.count - 1)];
        [resultTextureImagesArray addObject:[self defaultTextureImageForRouteStatus:self.trafficStatus.lastObject.status]];
    }
    
    //画路径线
    NSInteger coordCount = [resultCoordinateArray count];
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)malloc(coordCount * sizeof(CLLocationCoordinate2D));
    for (int k = 0; k < coordCount; k++) {
        AMapNaviPoint *aCoordinate = [resultCoordinateArray objectAtIndex:k];
        coordinates[k] = CLLocationCoordinate2DMake(aCoordinate.latitude, aCoordinate.longitude);
    }
    
    AMapNaviRoutePolylineX *polyline = [AMapNaviRoutePolylineX polylineWithCoordinates:coordinates count:coordCount drawStyleIndexes:resultDrawStyleIndexArray];
    polyline.polylineWidth = self.lineWidth;
    polyline.polylineTextureImages = resultTextureImagesArray;
    
    if (coordinates != NULL) {
        free(coordinates);
    }
    
    [self.internalMapView addOverlay:polyline level:MAOverlayLevelAboveRoads];
    
}

//没有交通状态的画路径
- (void)addRoutePolylineWithoutTrafficStatus {
    
    NSInteger coordianteCount = [self.currentNaviRoute.routeCoordinates count];
    
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)malloc(coordianteCount * sizeof(CLLocationCoordinate2D));
    for (int i = 0; i < coordianteCount; i++) {
        AMapNaviPoint *aCoordinate = [self.currentNaviRoute.routeCoordinates objectAtIndex:i];
        coordinates[i] = CLLocationCoordinate2DMake(aCoordinate.latitude, aCoordinate.longitude);
    }
    
    //因为只有一种纹理，全部用它，drawStyleIndexes随便写都可以
    //如果polylineTextureImages有三种纹理，drawStyleIndexes为@[@2,@10,@20],表示[0-3]用第一种纹理，[4,10]用第二种，[11,结束]最后一种纹理，颜色和纹理的规则是一样的。
    AMapNaviRoutePolylineX *polyline = [AMapNaviRoutePolylineX polylineWithCoordinates:coordinates count:coordianteCount drawStyleIndexes:@[@1]];
    
    polyline.polylineWidth = self.lineWidth;
    
    //polyline.polylineStrokeColors = @[[UIColor blueColor],[UIColor purpleColor],[UIColor orangeColor],[UIColor yellowColor]];
    polyline.polylineTextureImages = @[[self textureImageWithoutTrafficPolyline]];
    
    if (coordinates != NULL){
        free(coordinates);
    }
    
    [self.internalMapView addOverlay:polyline level:MAOverlayLevelAboveRoads];
}

//没有交通状态的纹理图片
- (UIImage *)textureImageWithoutTrafficPolyline {
    
    UIImage *textureImage = [UIImage imageNamed:AMapNaviRoutePolylineImageDefault];
    
    return textureImage;
}

//根据交通状态获得纹理图片
- (UIImage *)defaultTextureImageForRouteStatus:(AMapNaviRouteStatus)routeStatus {
    
    NSString *imageName = nil;
    
    if (routeStatus == AMapNaviRouteStatusSmooth) {
        imageName = AMapNaviRoutePolylineImageSmooth;
    } else if (routeStatus == AMapNaviRouteStatusSlow) {
        imageName = AMapNaviRoutePolylineImageSlow;
    } else if (routeStatus == AMapNaviRouteStatusJam) {
        imageName = AMapNaviRoutePolylineImageJam;
    } else if (routeStatus == AMapNaviRouteStatusSeriousJam) {
        imageName = AMapNaviRoutePolylineImageSeriousJam;
    } else {
        imageName = AMapNaviRoutePolylineImageUnknow;
    }
    
    return [UIImage imageNamed:imageName];
}


#pragma mark - MAMapViewDelegate

//地图区域改变完成后会调用此接口
- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
//    NSLog(@"===============");
}

//覆盖物的属性设置
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay {
    
    if ([overlay isKindOfClass:[AMapNaviRouteTurnArrowPolylineX class]]) {  //转弯箭头
        
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        
        polylineRenderer.strokeColor = [UIColor colorWithRed:87.0/255.0 green:235.0/255.0 blue:204.0/255.0 alpha:1.0];
        polylineRenderer.lineWidth = 10.0f;
        polylineRenderer.lineCapType = kMALineCapArrow;
        
        return polylineRenderer;
    } else if ([overlay isKindOfClass:[AMapNaviRoutePolylineX class]]) {  //规划的路径
        
        AMapNaviRoutePolylineX *routeOverlay = (AMapNaviRoutePolylineX *)overlay;
        
        if (routeOverlay.polylineTextureImages.count) {  //有纹理图片的，显示纹理图片，优先级最高
            
            MAMultiTexturePolylineRenderer *polylineRenderer = [[MAMultiTexturePolylineRenderer alloc] initWithMultiPolyline:routeOverlay];
            
            polylineRenderer.lineWidth = routeOverlay.polylineWidth;
            polylineRenderer.lineJoinType = kMALineJoinRound;
            [polylineRenderer loadStrokeTextureImages:routeOverlay.polylineTextureImages];
            
            return polylineRenderer;
            
        } else if (routeOverlay.polylineStrokeColors.count > 0) {  //有分段颜色的话，按分段颜色显示
            
            MAMultiColoredPolylineRenderer *polylineRenderer = [[MAMultiColoredPolylineRenderer alloc] initWithMultiPolyline:routeOverlay];
            
            polylineRenderer.lineWidth = routeOverlay.polylineWidth;
            polylineRenderer.lineJoinType = kMALineJoinRound;
            polylineRenderer.strokeColors = routeOverlay.polylineStrokeColors;
            polylineRenderer.gradient = NO;
            
            return polylineRenderer;
        } else { //默认情况下返回一个单色的polyline
            
            MAMultiColoredPolylineRenderer *polylineRenderer = [[MAMultiColoredPolylineRenderer alloc] initWithMultiPolyline:routeOverlay];
            
            polylineRenderer.lineWidth = routeOverlay.polylineWidth;
            polylineRenderer.lineJoinType = kMALineJoinRound;
            polylineRenderer.strokeColors = @[[UIColor colorWithRed:26.0/255.0 green:166.0/255.0 blue:239.0/255.0 alpha:1.0]];
            polylineRenderer.gradient = NO;
            
            return polylineRenderer;

        }
        
    }
    return nil;
}

//点标注的View的初始化
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation {
    
    if ([annotation isKindOfClass:[AMapNaviCarAnnotationX class]]) {
        static NSString *carAnnIdentifier = @"AMapNaviCarAnnotationViewIdentifier";
        
        if (self.carAnnotationView == nil) {
            self.carAnnotationView = [[AMapNaviCarAnnotationViewX alloc] initWithAnnotation:annotation reuseIdentifier:carAnnIdentifier];
        }
        
        self.carAnnotationView.enabled = NO;
        self.carAnnotationView.canShowCallout = NO;
        self.carAnnotationView.draggable = NO;
        
        return self.carAnnotationView;
    } else if ([annotation isKindOfClass:[AMapNaviCameraAnnotationX class]]) {
        
        static NSString *cameraAnnIdentifier = @"AMapNaviCameraAnnotationViewIdentifier";
        
        AMapNaviCameraAnnotationViewX *annView = (AMapNaviCameraAnnotationViewX *)[mapView dequeueReusableAnnotationViewWithIdentifier:cameraAnnIdentifier];
        if (annView == nil) {
            annView = [[AMapNaviCameraAnnotationViewX alloc] initWithAnnotation:annotation reuseIdentifier:cameraAnnIdentifier];
        }
        
        annView.enabled = NO;
        annView.canShowCallout = NO;
        annView.draggable = NO;
        
        return annView;

    } else if ([annotation isKindOfClass:[AMapNaviStartPointAnnotationX class]]) {
        
        static NSString *startAnnIdentifier = @"AMapNaviStartPointAnnotationViewIdentifier";
        
        AMapNaviStartPointAnnotationViewX *annView = (AMapNaviStartPointAnnotationViewX *)[mapView dequeueReusableAnnotationViewWithIdentifier:startAnnIdentifier];
        
        if (annView == nil) {
            annView = [[AMapNaviStartPointAnnotationViewX alloc] initWithAnnotation:annotation reuseIdentifier:startAnnIdentifier];
        }
        
        annView.enabled = NO;
        annView.canShowCallout = NO;
        annView.draggable = NO;
        
        return annView;
    } else if ([annotation isKindOfClass:[AMapNaviWayPointAnnotationX class]]) {
        static NSString *wayAnnIdentifier = @"AMapNaviWayPointAnnotationViewIdentifier";
        
        AMapNaviWayPointAnnotationViewX *annView = (AMapNaviWayPointAnnotationViewX *)[mapView dequeueReusableAnnotationViewWithIdentifier:wayAnnIdentifier];
        
        if (annView == nil) {
            annView = [[AMapNaviWayPointAnnotationViewX alloc] initWithAnnotation:annotation reuseIdentifier:wayAnnIdentifier];
        }
        
        annView.enabled = NO;
        annView.canShowCallout = NO;
        annView.draggable = NO;
        
        return annView;
    } else if ([annotation isKindOfClass:[AMapNaviEndPointAnnotationX class]]) {
        
        static NSString *endAnnIdentifier = @"AMapNaviEndPointAnnotationViewIdentifier";
        
        AMapNaviEndPointAnnotationViewX *annView = (AMapNaviEndPointAnnotationViewX *)[mapView dequeueReusableAnnotationViewWithIdentifier:endAnnIdentifier];
        
        if (annView == nil) {
            annView = [[AMapNaviEndPointAnnotationViewX alloc] initWithAnnotation:annotation reuseIdentifier:endAnnIdentifier];
        }
        
        annView.enabled = NO;
        annView.canShowCallout = NO;
        annView.draggable = NO;
        
        return annView;
    }
    
    return  nil;
}

@end
