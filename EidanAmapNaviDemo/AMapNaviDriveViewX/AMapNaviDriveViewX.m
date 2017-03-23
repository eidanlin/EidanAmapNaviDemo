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
#import "AMapNaviTrafficBarViewX.h"

static const int AMapNaviMoveCarSplitCount = 14;  //值越大，车的运动越平滑
static const CGFloat AMapNaviMoveCarTimeInterval = 1.0/AMapNaviMoveCarSplitCount;

static const CGFloat AMapNaviRoutePolylineDefaultWidth = 15.f;  //显示规划的路径的默认宽度

static NSString *const AMapNaviInfoViewTurnIconImage =  @"default_navi_action_%ld";

#define kAMapNaviInternalAnimationDuration      0.2f

#define kAMapNaviLockStateZoomLevel             18.0f
#define kAMapNaviLockStateCameraDegree          30.0f

#define kAMapNaviShowCameraMaxZoomLevel         19.0f
#define kAMapNaviShowCameraMinZoomLevel         15.0f

#define kAMapNaviTurnArrowDistance              40.0f
#define kAMapNaviShowTurnArrowMinZoomLevel      16.0f

#define kAMapNaviMoveDirectlyMaxDistance        300.0f
#define kAMapNaviMoveDirectlyMinDistance        1.0f

//views
//#define KAMapNaviInfoViewTurnIconImage          @"default_navi_action_%ld"
#define kAMapNaviInfoViewBackgroundColor        [UIColor colorWithRed:39/255.0 green:44/255.0 blue:54/255.0 alpha:1]

@interface AMapNaviDriveViewX ()<MAMapViewDelegate>

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
@property (nonatomic, strong) AMapNaviLocation *currentCarLocation;
@property (nonatomic, strong) AMapNaviInfo *currentNaviInfo;      //当前正在导航的这一个时间点的导航具体信息，会快速的变化
@property (nonatomic, copy) NSArray<AMapNaviCameraInfo *> *cameraInfos;
@property (nonatomic, strong) AMapNaviRoute *currentNaviRoute;  //当前需要导航的的一整条路径的信息，开始导航后，就不再改变
@property (nonatomic, copy) NSArray <AMapNaviTrafficStatus *> *trafficStatus;  //前方交通路况信息(长度和拥堵情况)

//牵引线
@property (nonatomic, strong) AMapNaviGuidePolyline *carToDestinationGuidePolyline;

#pragma -mark xib views
@property (nonatomic, strong) IBOutlet UIView *customView;

//mapView
@property (nonatomic, weak) IBOutlet MAMapView *internalMapView;

//车道信息图
@property (nonatomic, weak) IBOutlet UIImageView *laneInfoView;

//topInfoView
@property (nonatomic, weak) IBOutlet UIView *topInfoView;
@property (nonatomic, weak) IBOutlet UIImageView *topTurnImageView;
@property (nonatomic, weak) IBOutlet UILabel *topTurnRemainLabel;
@property (nonatomic, weak) IBOutlet UILabel *topRoadLabel;

//topInfoViewIn路口放大图模式
@property (nonatomic, weak) IBOutlet UIView *topInfoContainerViewInCrossMode;
@property (nonatomic, weak) IBOutlet UIImageView *crossImageView;
@property (nonatomic, weak) IBOutlet UIImageView *topTurnImageViewInCrossMode;
@property (nonatomic, weak) IBOutlet UILabel *topTurnRemainLabelInCrossMode;
@property (nonatomic, weak) IBOutlet UILabel *topRoadLabelInCrossMode;


//bottomInfoView
@property (nonatomic, weak) IBOutlet UIView *bottomInfoView;
@property (nonatomic, weak) IBOutlet UIView *bottomRemainBgView;
@property (nonatomic, weak) IBOutlet UILabel *bottomRemainTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *bottomRemainDistanceLabel;
@property (nonatomic, weak) IBOutlet UIView *bottomContinueNaviBgView;
@property (nonatomic, weak) IBOutlet UIButton *bottomContinueNaviBtnInLandscape;

//rightTipsView
@property (nonatomic, weak) IBOutlet UIButton *rightBrowserBtn;
@property (nonatomic, weak) IBOutlet UIButton *rightSwitchTrafficBtn;
@property (nonatomic, weak) IBOutlet AMapNaviTrafficBarViewX *rightTrafficBarView;

//constraint portrait
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topInfoViewHeightPortrait;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *mapViewTopPortrait;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *crossImageViewHeightPortrait;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *crossImageViewWidthPortrait;

//constraint landscape
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topInfoViewWidthLandscape;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *mapViewLeftLandscape;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *crossImageViewHeightLandscape;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *crossImageViewWidthLandScape;



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
    self.customView.backgroundColor = kAMapNaviInfoViewBackgroundColor;
    
    //监听设备方向。
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientaionChanged) name:UIDeviceOrientationDidChangeNotification object:NULL];
    
    //layoutConstraint
    [self configureTheConstraint];
    
    //property
    [self initProperties];
    
    //laneInfoView
    [self configureLaneInfoView];
    
    //topInfoView
    [self configureTopInfoView];
    
    //bottomInfoView
    [self configureBottomInfoView];
    
    //rightInfoView
    [self configureRightTipsView];
    
    //mapView
    [self configureMapView];
    
    //timer
    [self startMoveCarTimer];
    
}

//layoutConstraint
- (void)configureTheConstraint{
    
    //不同屏幕尺寸下改变路口放大图的大小，从而改变topInfoViewInCrossMode的大小
    float height = [UIScreen mainScreen].bounds.size.height;
    if (height == 375 || height == 667 ) {  //iphone7 竖屏和横屏
        self.crossImageViewWidthPortrait.constant = self.crossImageViewHeightPortrait.constant = 240;
        self.crossImageViewWidthLandScape.constant = self.crossImageViewHeightLandscape.constant = 265;
    } else if (height == 414 || height == 736 ) {//iphone7Plus竖屏和横屏
        self.crossImageViewWidthPortrait.constant = self.crossImageViewHeightPortrait.constant = 270;
        self.crossImageViewWidthLandScape.constant = self.crossImageViewHeightLandscape.constant = 295;
    }
    
}

- (void)initProperties {
    
    //public
    self.trackingMode = AMapNaviViewTrackingModeCarNorth;
    //以下几个变量都有重写setter，这边应该写成 _lineWidth = kAMapNaviRoutePolylineDefaultWidth 这种不会调用setter的写法，但是这几个变量，不写也没关系，因为即使走了setter也都会被return回来
    self.lineWidth = AMapNaviRoutePolylineDefaultWidth;
    self.cameraDegree = kAMapNaviLockStateCameraDegree;
    self.showTrafficLayer = YES;
    self.showMode = AMapNaviRideViewShowModeCarPositionLocked; //默认锁车模式，此时lockCarPosition为YES
    
    
    //car and map move
    self.splitCount = AMapNaviMoveCarSplitCount;
    self.needMoving = NO;
    
    //private
    self.lockCarPosition = YES;
    
}

- (void)layoutSubviews {
    self.customView.frame = self.bounds;
}

#pragma -mark dealloc

- (void)dealloc {
    NSLog(@"----------- driveViewX dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopMoveCarTimer];
    self.internalMapView.delegate = nil;
}

#pragma -mark Interface

- (void)setShowTrafficLayer:(BOOL)showTrafficLayer {
    _showTrafficLayer = showTrafficLayer;
    self.internalMapView.showTraffic = showTrafficLayer;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
    [self updateRoutePolyline];  //重绘路径
}

- (void)setCameraDegree:(CGFloat)cameraDegree {
    
    _cameraDegree = MAX(0, MIN(60.0, cameraDegree));
    
    if (self.lockCarPosition) {  //锁车模式下，摄像机的角度才是固定，生效的，非锁车模式下，用户自己会旋转成任意值。所以如果当前在锁车，直接改，不在锁车不用改，等切到锁车的时候，那边会改
        [self.internalMapView setCameraDegree:_cameraDegree animated:YES duration:kAMapNaviInternalAnimationDuration];
    }
    
}

- (void)setTrackingMode:(AMapNaviViewTrackingMode)trackingMode {
    _trackingMode = trackingMode;
    [self resetCarAnnotaionToRightStateAndIsNeedResetMapView:YES];  //如果是GPS导航，不移动位置，或者说导航信息没有更新，timer没有在走，这个时候你改变跟随模式，是没有效果的，所以为了一更改跟随模式就有效果，需要重设一下车和地图的状态
}

#pragma -mark 显示模式切换

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
    } else if (showMode == AMapNaviRideViewShowModeOverview) {
        [self handleShowModeToOverview];
    }
}

- (void)handleShowModeToNormal {
    self.lockCarPosition = NO;
    [self updateBottomInfoView];
    self.bottomContinueNaviBgView.hidden = NO;
    self.rightSwitchTrafficBtn.hidden = NO;
    self.rightBrowserBtn.hidden = self.rightBrowserBtn.selected = NO;  //从锁车模式或者全览模式，点击一下地图，都会切成普通模式，普通模式下，全览按钮就是可见且未被选择的状态
    self.rightTrafficBarView.hidden = YES;
}

- (void)handleShowModeToLockedCarPosition {
    self.lockCarPosition = YES;
    [self updateBottomInfoView];
    self.bottomContinueNaviBgView.hidden = YES;
    self.rightSwitchTrafficBtn.hidden = YES;
    self.rightBrowserBtn.hidden = YES;
    self.rightTrafficBarView.hidden = NO;
    
    //恢复锁车模式，设置地图和车为正确状态，特别是车的倾斜角度,先把地图的倾斜角度设置对了，根据地图的倾斜角度设置车，顺序不能乱，设置车的倾斜角度中，也要设置地图的旋转角度
    if (self.carAnnotation) {
        [self changeToNaviModeAtPoint:[AMapNaviPoint locationWithLatitude:self.carAnnotation.coordinate.latitude longitude:self.carAnnotation.coordinate.longitude]];
    }
    [self resetCarAnnotaionToRightStateAndIsNeedResetMapView:YES];
    
    //如果从缩小到很小的非锁车模式（这个时候是没有电子眼图标的）直接点击“继续导航”，变成锁车模式，需要电子眼图标，所以需要画出来，不加这句话，就没有
    [self updateRouteCameraAnnotationWithStartIndex:0];
}

- (void)handleShowModeToOverview {
    self.lockCarPosition = NO;
    [self updateBottomInfoView];
    self.bottomContinueNaviBgView.hidden = YES;
    [self showMapRegionWithBounds:self.currentNaviRoute.routeBounds centerCoordinate:self.currentNaviRoute.routeCenterPoint];  //能走到这一步self.currentNaviRoute肯定有值，不然普通模式都不行，更不用说全览模式
}

//锁车模式下，设置地图为正确的状态
- (void)changeToNaviModeAtPoint:(AMapNaviPoint *)point {
    
    if (point == nil) return;
    
    [self.internalMapView setCameraDegree:self.cameraDegree animated:NO duration:kAMapNaviInternalAnimationDuration];  //不能有动画，否则恢复锁车模式的时候，车的倾斜角度要根据地图的来，地图如果动画切过去，车没办法正确设置，详见handleShowModeToLockedCarPosition中的resetCarAnnotaionToRightStateAndIsNeedResetMapView。
    [self.internalMapView setCenterCoordinate:CLLocationCoordinate2DMake(point.latitude, point.longitude) animated:YES];
    [self.internalMapView setZoomLevel:kAMapNaviLockStateZoomLevel animated:NO]; //设置为NO，为YES的话，第一个转弯路口没有箭头overlay，因为zoomLevel不对，被return回来了
}

//全览模式下，设置地图为正确的状态
- (void)showMapRegionWithBounds:(AMapNaviPointBounds *)bounds centerCoordinate:(AMapNaviPoint *)center {
    
    if (bounds == nil || center == nil) return;
    
    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(center.latitude, center.longitude);
    
    CLLocationDegrees latitudeDelta = bounds.northEast.latitude - bounds.southWest.latitude;
    CLLocationDegrees longitudeDelta = bounds.northEast.longitude - bounds.southWest.longitude;
    
    MACoordinateRegion region = MACoordinateRegionMake(centerCoordinate, MACoordinateSpanMake(latitudeDelta, longitudeDelta));
    MAMapRect mapRect = MAMapRectForCoordinateRegion(region);
    
    UIEdgeInsets insets = UIEdgeInsetsMake(20, 20, 20, 20);
    
    [self.internalMapView setRotationDegree:0 animated:YES duration:kAMapNaviInternalAnimationDuration];
    [self.internalMapView setCameraDegree:0 animated:YES duration:kAMapNaviInternalAnimationDuration];
    [self.internalMapView setVisibleMapRect:mapRect edgePadding:insets animated:YES];
}

//设置车的倾斜角度和旋转角度还有位置。也可以设置地图的中心点和旋转角度，但不设置地图的倾斜角度（即摄像机角度）
- (void)resetCarAnnotaionToRightStateAndIsNeedResetMapView:(BOOL)isNeed {
    
    [self.carAnnotationView setCarDirection:self.carAnnotationView.carDirection];
    [self.carAnnotationView setCompassDirection:0];
    
    //这边设置地图，特别是设置地图的旋转角度，如果是地图朝北，地图就是旋转0度（因为默认朝北），如果是车头朝北，地图就要设置成车的旋转角度，保证车头朝北，因为车头能朝北，就是地图旋转后形成的。
    if (self.lockCarPosition && isNeed) {  //需要 且在 锁车模式，才设置，如果不是锁车模式，地图不跟着动，设置地图就没有意义了，所以需要锁车模式
        
        double degree = 0;
        
        if (self.trackingMode == AMapNaviViewTrackingModeMapNorth) {
            degree = 0;
        } else if (self.trackingMode == AMapNaviViewTrackingModeCarNorth) {
            degree = self.carAnnotationView.carDirection;
        }
        
        [self.internalMapView setRotationDegree:degree animated:NO duration:0];
        [self.internalMapView setCenterCoordinate:self.carAnnotation.coordinate animated:NO];
    }
    
}

#pragma -mark car timer

- (void)startMoveCarTimer {
    [self stopMoveCarTimer];
    
    AMapNaviTimerTargetX *target = [AMapNaviTimerTargetX new];
    target.realTarget = self;
    
    self.moveCarTimer = [NSTimer scheduledTimerWithTimeInterval:AMapNaviMoveCarTimeInterval target:target selector:@selector(moveCarLocationSmooth:) userInfo:nil repeats:YES];
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
    
    //如果偏航的很远，或者导航的起点和定位点离的很远，总之就是车的实际位置和车图标相差的距离超过300米，就一步到位的跳过去，不走动画，这样更简洁.
    if (self.moveDirectly) {
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
        
        [self updateCarToDestinationGuidePolylineWhenCarMove];
        
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
        
        [self updateCarToDestinationGuidePolylineWhenCarMove];
        
    } else {
        self.stepCount = 0;
        self.needMoving = NO;
    }
    
}

//上一次导航信息更新后的一些信息记录为prior，通过这一次导航信息和上一次信息的差值除于14，表示每一次设置的单位量，timer中就会每一次增加一个单位量，来平滑的做动画.
- (void)moveCarAnnotationToCoordinate:(AMapNaviPoint *)coordinate direction:(double)direction zoomLevel:(double)zoomLevle {
    
    if (coordinate == nil || coordinate.latitude == 0 || coordinate.longitude == 0) {
        return;
    }
    
    //上一次信息
    self.priorPoint = [AMapNaviPoint locationWithLatitude:self.carAnnotation.coordinate.latitude longitude:self.carAnnotation.coordinate.longitude];
    self.priorCarDirection = self.carAnnotationView.carDirection;
    self.priorZoomLevel = self.internalMapView.zoomLevel;
    
    //算出上一次和这一次两点之间的距离，如果超过300米，就在timer中，让车图标一步到位，不做动画
    double distance =[AMapNaviViewUtilityX distanceBetweenCoordinates:coordinate andPoint:self.priorPoint];
    if (distance > kAMapNaviMoveDirectlyMaxDistance) {
        self.moveDirectly = YES;
    } else {
        self.moveDirectly = NO;
    }
    
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
//    NSLog(@"导航模式更新");
    self.currentNaviMode = naviMode;

}

//路径信息更新：每次换路后，开始导航的时候才会调用一次(或者两次)，可用来设置这次导航路线的起点，让地图的初始位置正确，电子眼的初始化
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateNaviRoute:(AMapNaviRoute *)naviRoute {
    
//    NSLog(@"路径信息更新,%@",naviRoute);
    
    self.currentNaviRoute = naviRoute;
    
    //画出规划的路径，一般在这里画的路径都是不带路况信息，因为路况信息的回调还没调用。
    [self updateRoutePolyline];
    
    //牵引线
    [self updateCarToDestinationGuidLine];
    
    //起点，终点，沿途的点的绘制
    [self updateRoutePointAnnotation];
    
    //锁车模式下，地图的中心点，缩放级别，摄像机角度
    [self changeToNaviModeAtPoint:self.currentNaviRoute.routeStartPoint];
    
    //更新电子眼信息,这里的显示与否取决于zoomLevel.
    [self updateRouteCameraAnnotationWithStartIndex:0];
    
    //更新转向箭头，这里的显示与否有取决于zoomLevel,所以必须在changeToNaviModeAtPoint先把zoomLebel设定对了，再执行这个函数，第一个路口才会有箭头，而且changeToNaviModeAtPoint里面setZoomLevel不能有动画
    [self updateRouteTurnArrowPolylineWithSegmentIndex:0];
    
    //初始化一下，让一有路径信息，就有自车图标
    [self carAnnotation];
    
}

//导航实时信息更新，如果是模拟导航，自车位置开始一段时间后，就不再更新，但是导航实时信息一直在更新，所以模拟导航以这个回调为准
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateNaviInfo:(AMapNaviInfo *)naviInfo {
//    NSLog(@"导航信息更新,%@",naviInfo);
    
    //第一次没有self.currentNaviInfo需要，上一次导航信息的摄像头索引和这次的不一样也需要。
    BOOL isNeedUpdateTurnArrow = self.currentNaviInfo ? (self.currentNaviInfo.currentSegmentIndex != naviInfo.currentSegmentIndex) : YES;
    
    self.currentNaviInfo = naviInfo;
    
    //InfoView
    [self updateTopInfoView];
    [self updateBottomInfoView];
    
    //更新光柱中车的位置
    if (self.currentNaviRoute.routeLength > 0 && self.currentNaviInfo) {
        double remainPercent = (double)self.currentNaviInfo.routeRemainDistance / self.currentNaviRoute.routeLength;
        [self.rightTrafficBarView updateCarPositionWithRouteRemainPercent:remainPercent];
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
    
}

//电子眼信息更新
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateCameraInfos:(NSArray<AMapNaviCameraInfo *> *)cameraInfos {
    self.cameraInfos = cameraInfos;
    [self updateRouteCameraAnnotationWithCameraInfos:cameraInfos];
}

//自车位置更新。模拟导航自车位置不会一直更新，GPS导航自车位置才能一直更新
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateNaviLocation:(AMapNaviLocation *)naviLocation {
    
//    NSLog(@"自车位置更新,%@",naviLocation.coordinate);
    
    self.currentCarLocation = naviLocation;
    
    if (self.carAnnotation == nil) {
        return;
    }
    
    //车的位置改变，需要对车的图标进行移动
    [self moveCarAnnotationToCoordinate:self.currentCarLocation.coordinate direction:self.currentCarLocation.heading zoomLevel:kAMapNaviLockStateZoomLevel];
    
}

//路况信息更新
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateTrafficStatus:(NSArray<AMapNaviTrafficStatus *> *)trafficStatus {
//    NSLog(@"路况信息更新");
    
    self.trafficStatus = trafficStatus;
    
    //更新光柱中的路况信息
    if (trafficStatus) {
        [self.rightTrafficBarView updateBarWithTrafficStatuses:trafficStatus];
    }
    
    [self updateRoutePolyline]; //如果路况信息更新了，就要重画
}

//需要显示路口放大图了
- (void)driveManager:(AMapNaviDriveManager *)driveManager showCrossImage:(UIImage *)crossImage {
    
    if (crossImage) {
        self.crossImageView.image = crossImage;
        self.crossImageView.hidden = NO;
        self.showMode = AMapNaviDriveViewShowModeCarPositionLocked; //如果有路口放大图，恢复锁车模式
    }
    
    [self handleWhenCrossImageShowAndHide];
}

//需要把路口放大图了隐藏了
- (void)driveManagerHideCrossImage:(AMapNaviDriveManager *)driveManager {
    
    self.crossImageView.image = nil;
    self.crossImageView.hidden = YES;
    
    [self handleWhenCrossImageShowAndHide];
    
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

#pragma -mark Orientaion

-(void)orientaionChanged{
    if([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft || [UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight){
        
    } else if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait || [UIDevice currentDevice].orientation == UIDeviceOrientationPortraitUpsideDown){
        
    }
}


#pragma -mark Private: Component

//初始化 车标注，指定初始位置，添加到地图
- (AMapNaviCarAnnotationX *)carAnnotation {
    if (_carAnnotation == nil) {
        
        AMapNaviPoint *coordinate = nil;
        
        //高德地图和百度地图，如果导航的起点设置在离目前定位点很远的地方，是直接跳到导航起点开始导航，但是只要一移动(自车位置一回调)，车图标就会定位到当前位置，并触发偏航重算。所以我们先把车的初始位置放在起点，然后GPS导航中，自车位置从自车位置回调中取，模拟导航中，自车位置从导航信息回调中取
        if (self.currentNaviRoute.routeStartPoint) {
            coordinate = self.currentNaviRoute.routeStartPoint;
        }

        //如果 coordinate还是为nil，就先等着，车的图标一定要等到有一个有效的位置，才可以画出来
        if (coordinate == nil) {
            return nil;
        }
        
        _carAnnotation = [AMapNaviCarAnnotationX new];
        _carAnnotation.coordinate = CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude);
        
        //如果AMapNaviCarAnnotationX遵循了MAAnimatableAnnotation协议，就可以使用地图的实时刷新函数，不用我们自己写timer了。
//        __weak typeof(self) weakSelf = self;
//        _carAnnotation.stepCallback = ^(CGFloat timeDelta) {
//            [weakSelf moveCarLocationSmooth:nil];
//        };
        
        [self.internalMapView addAnnotation:_carAnnotation];
        [self.internalMapView selectAnnotation:_carAnnotation animated:NO];
        
        //牵引线
        [self updateCarToDestinationGuidLine];
        
    }
    return _carAnnotation;
}

- (double)normalizeOffsetDegree:(double)degree {
    return degree + ((degree > 180.f) ? -360.f : (degree < -180.f) ? 360.f : 0);
}

#pragma -mark MapView

- (void)configureMapView {
    
    self.internalMapView.mapType = MAMapTypeNavi;
    self.internalMapView.showsScale = NO;
    self.internalMapView.showsIndoorMap = NO;
    self.internalMapView.showsBuildings = NO;
    self.internalMapView.showsCompass = NO;
    self.internalMapView.maxRenderFrame = 30;
    self.internalMapView.isAllowDecreaseFrame = NO;  //不允许降帧，否则地图一段时间不动的情况下，会被降帧，车的移动就会出现卡顿
    self.internalMapView.delegate = self;
    self.internalMapView.zoomLevel = 11.1;
    self.internalMapView.centerCoordinate = CLLocationCoordinate2DMake(39.906207, 116.397582);
    self.internalMapView.showTraffic = self.showTrafficLayer;
    
    [self.internalMapView setTrafficStatus:  @{@(MATrafficStatusSmooth)    : [UIColor colorWithRed:148/255.0 green:215/255.0 blue:115/255.0 alpha:1],
                                              @(MATrafficStatusSlow)       : [UIColor colorWithRed:231/255.0 green:211/255.0 blue:82/255.0 alpha:1],
                                              @(MATrafficStatusJam)        : [UIColor colorWithRed:231/255.0 green:138/255.0 blue:107/255.0 alpha:1],
                                              @(MATrafficStatusSeriousJam) : [UIColor colorWithRed:189/255.0 green:93/255.0 blue:115/255.0 alpha:1]}];
    
    [self.internalMapView removeOverlays:self.internalMapView.overlays];
    [self.internalMapView removeAnnotations:self.internalMapView.annotations];
}

#pragma -mark 路口放大图


- (void)handleWhenCrossImageShowAndHide {
    
    if (self.crossImageView.image) {  //有路口放大图，不管目前是横竖屏，统一都改了，当他切换横竖屏的时候自然好使
        self.mapViewTopPortrait.constant = self.crossImageViewHeightPortrait.constant + 20;  //竖屏:放大图的高度＋状态栏的高度
        self.mapViewLeftLandscape.constant = self.crossImageViewWidthLandScape.constant;  //横屏下
        self.topInfoContainerViewInCrossMode.hidden = NO;
    } else {
        self.mapViewTopPortrait.constant = self.topInfoViewHeightPortrait.constant;
        self.mapViewLeftLandscape.constant = self.topInfoViewWidthLandscape.constant;
        self.topInfoContainerViewInCrossMode.hidden = YES;
    }
    
}


#pragma -mark 车道信息图 

- (void)configureLaneInfoView {
    self.laneInfoView.hidden = YES;
}

#pragma -mark topInfoView

- (void)configureTopInfoView {
    self.topInfoView.superview.backgroundColor = kAMapNaviInfoViewBackgroundColor;
    self.topInfoView.hidden = YES;
    
    self.topInfoContainerViewInCrossMode.backgroundColor = kAMapNaviInfoViewBackgroundColor;
    self.topInfoContainerViewInCrossMode.hidden = YES;
}

- (void)updateTopInfoView {
    if (self.currentNaviInfo) {
        
        self.topTurnRemainLabel.text = [NSString stringWithFormat:@"%@后",[AMapNaviViewUtilityX normalizedRemainDistance:self.currentNaviInfo.segmentRemainDistance]];
        self.topRoadLabel.text = self.currentNaviInfo.nextRoadName;
        
        self.topTurnRemainLabelInCrossMode.text = self.topTurnRemainLabel.text;
        self.topRoadLabelInCrossMode.text = self.topRoadLabel.text;
        
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:AMapNaviInfoViewTurnIconImage,self.currentNaviInfo.iconType]];
        if (image == nil) {
            image = [UIImage imageNamed:[NSString stringWithFormat:AMapNaviInfoViewTurnIconImage,AMapNaviIconTypeStraight]];
        }
        self.topTurnImageView.image = image;
        self.topTurnImageViewInCrossMode.image = image;
        
        if (self.topInfoView.hidden == YES) {
            self.topInfoView.hidden = NO;
        }
    } else {
        if (self.topInfoView.hidden == NO) {
            self.topInfoView.hidden = YES;
            self.topInfoContainerViewInCrossMode.hidden = YES;
        }
    }
}

#pragma -mark bottomInfoView

- (void)configureBottomInfoView {
    self.bottomRemainBgView.hidden = YES;
    self.bottomContinueNaviBgView.hidden = YES;
    self.bottomContinueNaviBtnInLandscape.layer.cornerRadius = 3;
}

- (void)updateBottomInfoView {
    if (self.currentNaviInfo && (self.showMode == AMapNaviRideViewShowModeCarPositionLocked || self.showMode == AMapNaviRideViewShowModeOverview)) {  //如果不是锁车状态或者全览模式，bottomRemainBgView不应该显示
        
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

#pragma -mark rightTipsView

- (void)configureRightTipsView {
    self.rightBrowserBtn.hidden = YES;
    self.rightSwitchTrafficBtn.hidden = YES;
}

#pragma -mark xib btns click

//更多按钮点击
- (IBAction)moreBtnClick:(id)sender {

    //更改跟随模式
    if (self.trackingMode == AMapNaviViewTrackingModeMapNorth) {
        self.trackingMode = AMapNaviViewTrackingModeCarNorth;
    } else if (self.trackingMode == AMapNaviViewTrackingModeCarNorth) {
        self.trackingMode = AMapNaviViewTrackingModeMapNorth;
    }
}

//继续导航按钮点击
- (IBAction)continueNaviBtnClick:(id)sender {
    self.showMode = AMapNaviRideViewShowModeCarPositionLocked;  //切换成锁车模式
}

//切换路况按钮点击
- (IBAction)swichTrafficBtnClick:(id)sender {
    UIButton *btn = (UIButton *)sender;
    
    if (btn.selected == NO) {  //点击从有路况切成没路况
        self.showTrafficLayer = NO;
    } else { //点击从无路况切成有路况
        self.showTrafficLayer = YES;
    }
    
    btn.selected = !btn.selected;
}


//全览按钮点击
- (IBAction)browserBtnClick:(id)sender {
    UIButton *btn = (UIButton *)sender;
    
    if (btn.selected == NO) {  //点击从普通模式切换成全览模式
        self.showMode = AMapNaviRideViewShowModeOverview;
    } else { //点击从全览模式切换成锁车模式
        self.showMode = AMapNaviRideViewShowModeCarPositionLocked;
    }
    
    btn.selected = !btn.selected;
}


- (IBAction)goBack:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(driveViewXCloseButtonClicked:)]) {
        [self.delegate driveViewXCloseButtonClicked:self];
    }
    
}

#pragma mark - 路径信息更新后，才会更新的起点，终点，途径点

- (void)updateRoutePointAnnotation {
    
    if (self.currentNaviRoute == nil) {  //没有路径，就无从显示
        return;
    }
    
    [self removeNaviRoutePointAnnotation];
    
//    //StartPoint
//    AMapNaviPoint *startPoint = self.currentNaviRoute.routeStartPoint;
//    CLLocationCoordinate2D start = CLLocationCoordinate2DMake(startPoint.latitude, startPoint.longitude);
//    AMapNaviStartPointAnnotationX *startAnnotation = [[AMapNaviStartPointAnnotationX alloc] initWithCoordinate:start];
//    [self.internalMapView addAnnotation:startAnnotation];
    
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

///刚选择路径的时候，画出所有的电子眼，但只是图标
- (void)updateRouteCameraAnnotationWithStartIndex:(NSInteger)startIndex {
    
    if (self.currentNaviRoute == nil) {  //没有路径，就无从显示
        return;
    }
    
    [self removeRouteCameraAnnotation];  //每次更新前，先全部移除所有电子眼
    
    //zoomLevel不在范围内，这里取决于你全览或者放大缩小到一定程度，还是否想看到电子眼图标。
    if (self.internalMapView.zoomLevel > kAMapNaviShowCameraMaxZoomLevel || self.internalMapView.zoomLevel < kAMapNaviShowCameraMinZoomLevel){
        return;
    }
    
    int index = (int)startIndex;
    
    while (index < self.currentNaviRoute.routeCameras.count ) {  //只更新当前的电子眼信息，和当前的下一个，每次更新，只更新最近的这两个
        AMapNaviCameraInfo *aCamera = [self.currentNaviRoute.routeCameras objectAtIndex:index];
        
        AMapNaviCameraAnnotationX *anno = [[AMapNaviCameraAnnotationX alloc] init];
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

- (void)updateRouteCameraAnnotationWithCameraInfos:(NSArray <AMapNaviCameraInfo *> *)cameraInfos
{
    [self removeRouteCameraTypeAnnotation];  //如果数组为空，也是先移除，再return回去，因为数组为空，就是代表你刚路过完一个摄像头，要把其从地图上移除
    
    //zoomLevel不在范围内，这里取决于你全览或者放大缩小到一定程度，还是否想看到电子眼图标。
    if (self.internalMapView.zoomLevel > kAMapNaviShowCameraMaxZoomLevel || self.internalMapView.zoomLevel < kAMapNaviShowCameraMinZoomLevel) {
        return;
    }
    
    int index = 0;
    
    while (index < cameraInfos.count && index < 2) { //只更新当前的电子眼信息，和当前的下一个，每次更新，只更新最近的这两个
        AMapNaviCameraInfo *aCamera = [cameraInfos objectAtIndex:index];
        
        AMapNaviCameraTypeAnnotationX *anno = [[AMapNaviCameraTypeAnnotationX alloc] init];
        anno.coordinate = CLLocationCoordinate2DMake(aCamera.coordinate.latitude, aCamera.coordinate.longitude);
        anno.cameraInfo = aCamera;
        anno.index = index;
        [self.internalMapView addAnnotation:anno];
        
        index++;
    }
}

- (void)removeRouteCameraTypeAnnotation {
    [self.internalMapView.annotations enumerateObjectsUsingBlock:^(id<MAAnnotation> obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[AMapNaviCameraTypeAnnotationX class]]) {
            [self.internalMapView removeAnnotation:obj];
        }
    }];
}

#pragma mark - 牵引线

//画出牵引线：前提条件：1.有车图标，才有自车位置；2.有路线，才有合适的终点。所以需要2个地方调用，因为我们没办法确认2个条件成立的时机
- (void)updateCarToDestinationGuidLine {
    
    if (self.currentNaviRoute == nil || self.carAnnotation == nil) {
        [self removeCarToDestinationGuidLine];
    } else {
        CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)malloc(2 * sizeof(CLLocationCoordinate2D));
        
        coordinates[0] = self.carAnnotation.coordinate;
        coordinates[1] = CLLocationCoordinate2DMake(self.currentNaviRoute.routeEndPoint.latitude, self.currentNaviRoute.routeEndPoint.longitude);
        
        self.carToDestinationGuidePolyline = [AMapNaviGuidePolyline polylineWithCoordinates:coordinates count:2];
        
        free(coordinates);
        coordinates = NULL;
        
        [self removeCarToDestinationGuidLine];  //分开写remove，保证再加入新的，才把就的移除掉，防止出现2条
        
        [self.internalMapView addOverlay:self.carToDestinationGuidePolyline level:MAOverlayLevelAboveLabels];
    }
}

//remove
- (void)removeCarToDestinationGuidLine{
    [self.internalMapView.overlays enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[AMapNaviGuidePolyline class]]) {
            [self.internalMapView removeOverlay:obj];
        }
    }];
}

//移动牵引线的起点当车移动后
- (void)updateCarToDestinationGuidePolylineWhenCarMove {
    if (self.carToDestinationGuidePolyline) {
        
        CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)malloc(2 * sizeof(CLLocationCoordinate2D));
        
        coordinates[0] = self.carAnnotation.coordinate;
        coordinates[1] = CLLocationCoordinate2DMake(self.currentNaviRoute.routeEndPoint.latitude, self.currentNaviRoute.routeEndPoint.longitude);
        
        [self.carToDestinationGuidePolyline setPolylineWithCoordinates:coordinates count:2];
        
        free(coordinates);
        coordinates = NULL;
    }
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
    coordinates = NULL;
    
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
    
    if (self.trafficStatus.count) {  //有路况信息，才能显示带路况的路径
        [self addRoutePolylineWithTrafficStatus];
    } else {
        [self addRoutePolylineWithoutTrafficStatus];
    }
    
    //为了让转弯箭头在路径上层，不被遮挡，每次更新路径，都要让转弯箭头重新画，如果self.currentNaviInfo为nil，则索引为0
    [self updateRouteTurnArrowPolylineWithSegmentIndex:self.currentNaviInfo.currentSegmentIndex];
    
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
        while ((int)resultDrawStyleIndexArray.count - 1 >= (int)self.trafficStatus.count) {  //这里必须强转成int，进行条件判断，否则当resultDrawStyleIndexArray数组为0个，resultDrawStyleIndexArray.count - 1 就为无穷大,那么就死循环了，直接卡死.
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
    
    free(coordinates);
    coordinates = NULL;
    
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
    
    free(coordinates);
    coordinates = NULL;
    
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
    
    //用户利用手势改变地图的摄像机角度，缩放地图，地图的旋转角度，一定会进入非锁车模式
    if (self.lockCarPosition == NO) {
//        [self resetCarAnnotaionToRightStateAndIsNeedResetMapView:NO]; 这个时候我们要更新一下车的倾斜角度，来保证和地图平面平行，否则很怪。貌似地图5.0.0后，不用处理平行的问题。
        [self updateRouteCameraAnnotationWithStartIndex:0]; //实现全览或者地图缩放的比较小，摄像头不画，放大到一定程度，又有摄像头
        [self updateRouteCameraAnnotationWithCameraInfos:self.cameraInfos]; //同上
    }
    
}

//覆盖物的属性设置
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay {
    
    if ([overlay isKindOfClass:[AMapNaviRouteTurnArrowPolylineX class]]) {  //转弯箭头
        
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        
        polylineRenderer.strokeColor = [UIColor colorWithRed:49.0/255.0 green:168.0/255.0 blue:249.0/255.0 alpha:1.0];
        polylineRenderer.lineWidth = 12.0f;
        polylineRenderer.lineCapType = kMALineCapArrow;
        
        return polylineRenderer;
    } else if ([overlay isKindOfClass:[AMapNaviGuidePolyline class]]) {  //牵引线
        
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        
        polylineRenderer.strokeColor = [UIColor colorWithRed:213.0/255.0 green:35/255.0 blue:33/255.0 alpha:1.0];
        polylineRenderer.lineWidth = 2.0f;
        polylineRenderer.lineCapType = kMALineCapButt;
        
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

    } else if ([annotation isKindOfClass:[AMapNaviCameraTypeAnnotationX class]]) {
        
        static NSString *cameraAnnIdentifier = @"AMapNaviCameraAnnotationTypeViewIdentifier";
        
        AMapNaviCameraTypeAnnotationX *cameraAnno = (AMapNaviCameraTypeAnnotationX *)annotation;
        
        AMapNaviCameraTypeAnnotationViewX *annView = (AMapNaviCameraTypeAnnotationViewX *)[mapView dequeueReusableAnnotationViewWithIdentifier:cameraAnnIdentifier];
        if (annView == nil) {
            annView = [[AMapNaviCameraTypeAnnotationViewX alloc] initWithAnnotation:annotation reuseIdentifier:cameraAnnIdentifier cameraInfo:cameraAnno.cameraInfo andIndex:cameraAnno.index];
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
