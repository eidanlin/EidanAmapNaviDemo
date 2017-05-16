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
#define kAMapNaviShowCameraMinZoomLevel         16.0f

#define kAMapNaviTurnArrowDistance              20.0f
#define kAMapNaviShowTurnArrowMaxZoomLevel      19.0f
#define kAMapNaviShowTurnArrowMinZoomLevel      16.0f

#define kAMapNaviMoveDirectlyMaxDistance        300.0f
#define kAMapNaviMoveDirectlyMinDistance        1.0f

//views
#define kAMapNaviInfoViewBackgroundColor        [UIColor colorWithRed:30/255.0 green:33/255.0 blue:42/255.0 alpha:1]

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
@property (nonatomic, strong) AMapNaviGuidePolylineX *carToDestinationGuidePolyline;

//xib views
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
@property (nonatomic, weak) IBOutlet UIImageView *bottomBgImageViewPortrait;

@property (nonatomic, weak) IBOutlet UIView *bottomRemainBgView;
@property (nonatomic, weak) IBOutlet UILabel *bottomRemainTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *bottomRemainDistanceLabel;
@property (nonatomic, weak) IBOutlet UIView *bottomContinueNaviBgView;
@property (nonatomic, weak) IBOutlet UIButton *bottomContinueNaviBtnInLandscape;

//rightTipsView
@property (nonatomic, weak) IBOutlet UIButton *rightBrowserBtn;
@property (nonatomic, weak) IBOutlet UIButton *rightSwitchTrafficBtn;
@property (nonatomic, weak) IBOutlet AMapNaviTrafficBarViewX *rightTrafficBarView;
@property (nonatomic, weak) IBOutlet UIButton *zoomInBtn;  //放大
@property (nonatomic, weak) IBOutlet UIButton *zoomOutBtn; //缩小
@property (nonatomic, weak) IBOutlet UIButton *swtichTrackModeBtn;
@property (nonatomic, weak) IBOutlet UILabel *speedLabel;


//constraint both
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *setMoreBtnHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *rightBrowserBtnHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *rightSwitchTrafficBtnHeight;

//constraint portrait
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topInfoViewHeightPortrait;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *mapViewTopPortrait;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topInfoViewHeightInCrossModePortrait;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *bottomInfoViewRightPortrait;


//constraint landscape
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topInfoViewWidthLandscape;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *mapViewLeftLandscape;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *mapViewTopLandscape;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *crossImageViewHeightLandscape;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *crossImageViewWidthLandScape;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *rightBrowserBtnBottomLandscape;

//custom image set
@property (nonatomic, strong) UIImage *cameraImage;
@property (nonatomic, strong) UIImage *startPointImage;
@property (nonatomic, strong) UIImage *wayPointImage;
@property (nonatomic, strong) UIImage *endPointImage;
@property (nonatomic, strong) UIImage *carImage;
@property (nonatomic, strong) UIImage *carCompassImage;



@end

@implementation AMapNaviDriveViewX


#pragma mark - LifeCycle

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

- (void)dealloc {
    NSLog(@"----------- driveViewX dealloc");
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopMoveCarTimer];
    self.internalMapView.delegate = nil;
}

#pragma mark -Init

- (void)setUp {
    
    //self
    [[NSBundle mainBundle] loadNibNamed:@"AMapNaviDriveViewX" owner:self options:nil];
    [self addSubview:self.customView];
    self.customView.frame = self.bounds;
    self.customView.backgroundColor = kAMapNaviInfoViewBackgroundColor;
    self.customView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    //监听设备方向。
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientaionChanged) name:UIDeviceOrientationDidChangeNotification object:NULL];
    
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
    
    float shorterSide = MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);  //较短的一边
    float longerSide = MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);   //较长的一边
    
    //SDK给出的路口放大图的尺寸(500*320)
    float crossImageOriginWidth = 500.0;
    float crossImageOriginHeightInLPortrait = 320.0;  //竖屏
    float crossImageOriginHeightInLandscape = 382.0;  //横屏不按照SDK给，做了微调。
    
    //以下不管横竖屏，都是希望算出图片按比例缩放后应有的高度，来保证不变形
    //横屏下的计算，使用较长的一边作为顶边
    self.crossImageViewWidthLandScape.constant = longerSide / 2;
    self.crossImageViewHeightLandscape.constant = self.crossImageViewWidthLandScape.constant * crossImageOriginHeightInLandscape / crossImageOriginWidth;
    
    //竖屏的计算，使用较短的一边作为顶边
    self.topInfoViewHeightInCrossModePortrait.constant = shorterSide * crossImageOriginHeightInLPortrait / crossImageOriginWidth + 20 + 50;  //20为状态栏高度，50为信息横条所占的高度
    
}

- (void)initProperties {
    
    //public
    _trackingMode = AMapNaviViewTrackingModeCarNorth;
    self.showMode = AMapNaviDriveViewShowModeCarPositionLocked; //默认锁车模式，此时lockCarPosition为YES
    _showUIElements = YES;
    _showCamera = YES;
    _showCrossImage = YES;
    _showStandardNightType = NO;
    _showBrowseRouteButton = YES;
    _showMoreButton = YES;
    _showTrafficBar = YES;
    _showTrafficButton = YES;
    _showTrafficLayer = YES;
    _showTurnArrow = YES;
    _showCompass = NO;
    _cameraDegree = kAMapNaviLockStateCameraDegree;
    _lineWidth = AMapNaviRoutePolylineDefaultWidth;
    
    //car and map move
    self.splitCount = AMapNaviMoveCarSplitCount;
    self.needMoving = NO;
    
    //private
    self.lockCarPosition = YES;
    
}

#pragma -mark Interface

- (void)setTrackingMode:(AMapNaviViewTrackingMode)trackingMode {
    _trackingMode = trackingMode;
    [self resetCarAnnotaionToRightStateAndIsNeedResetMapView:YES];  //如果是GPS导航，不移动位置，或者说导航信息没有更新，timer没有在走，这个时候你改变跟随模式，是没有效果的，所以为了一更改跟随模式就有效果，需要重设一下车和地图的状态
}

- (void)setShowUIElements:(BOOL)showUIElements {
    
    if (_showUIElements == showUIElements) {
        return;
    }
    
    _showUIElements = showUIElements;
    
    if (showUIElements) {  //显示UI
        self.mapViewTopPortrait.constant = self.topInfoViewHeightPortrait.constant;
        self.mapViewLeftLandscape.constant = self.topInfoViewWidthLandscape.constant;
        self.mapViewTopLandscape.constant = 20;
        self.internalMapView.layer.zPosition = 0;
        for (UIView *view in self.internalMapView.superview.subviews) {
            view.userInteractionEnabled = YES;
        }
        [self handleWhenCrossImageShowAndHide:nil];  //显示UI后，必须让路口放大图没有，否则会有bug。
    } else {
        self.mapViewTopPortrait.constant = 0;
        self.mapViewLeftLandscape.constant = 0;
        self.mapViewTopLandscape.constant = 0;
        self.internalMapView.layer.zPosition = 1;  //不能用bringSubviewToFront:，因为初始化的时候不起作用，而且屏幕旋转方向后，又会归位
        for (UIView *view in self.internalMapView.superview.subviews) {  //改变zPosition后，挡住地图的元素还会接受事件，应该让其他元素不能接受事件
            if (view != self.internalMapView) {
                view.userInteractionEnabled = NO;
            }
        }
    }
    
}

- (void)setShowCamera:(BOOL)showCamera {
    
    if (_showCamera == showCamera) {
        return;
    }
    
    _showCamera = showCamera;
    
    [self updateRouteCameraAnnotationWithStartIndex:0];
    [self updateRouteCameraAnnotationWithCameraInfos:self.cameraInfos];
}

- (void)setShowCrossImage:(BOOL)showCrossImage {
    
    if (_showCrossImage == showCrossImage) {
        return;
    }
    
    _showCrossImage = showCrossImage;
    
    [self handleWhenCrossImageShowAndHide:nil];
}

- (void)setShowStandardNightType:(BOOL)showStandardNightType {
    
    _showStandardNightType = showStandardNightType;
    
    [self setCustomMapStyleEnabled:NO];  //如果黑夜模式，把自定义模式关掉
    
    self.internalMapView.mapType = showStandardNightType ? MAMapTypeStandardNight : MAMapTypeNavi;
    
}

- (void)setShowBrowseRouteButton:(BOOL)showBrowseRouteButton {
    
    if (_showBrowseRouteButton == showBrowseRouteButton) {
        return;
    }
    
    _showBrowseRouteButton = showBrowseRouteButton;
    
    if (showBrowseRouteButton) {
        self.rightBrowserBtnHeight.constant = 53;
    } else {
        self.rightBrowserBtnHeight.constant = 0;
    }
    
    [self handleRightBrowserBtnBottomLandscape];
    
//    [self handleRightBrowserBtnShowOrHide];
}

- (void)setShowMoreButton:(BOOL)showMoreButton {
    
    if (_showMoreButton == showMoreButton) {
        return;
    }
    
    _showMoreButton = showMoreButton;
    
    if (showMoreButton) {
        self.bottomInfoViewRightPortrait.constant = 55;
        self.setMoreBtnHeight.constant = 53;
    } else {
        self.bottomInfoViewRightPortrait.constant = 0;
        self.setMoreBtnHeight.constant = 0;
    }
    
    [self handleRightBrowserBtnBottomLandscape];
    
}

- (void)setShowTrafficBar:(BOOL)showTrafficBar {
    
    if (_showTrafficBar == showTrafficBar) {
        return;
    }
    
    _showTrafficBar = showTrafficBar;
    
    [self handleRightTrafficBarViewShowOrHide];
    
}

- (void)setShowTrafficButton:(BOOL)showTrafficButton {
    
    if (_showTrafficButton == showTrafficButton) {
        return;
    }
    
    _showTrafficButton = showTrafficButton;
    self.rightSwitchTrafficBtnHeight.constant = showTrafficButton ? 53 : 0;
    
}


- (void)setShowTrafficLayer:(BOOL)showTrafficLayer {
    
    _showTrafficLayer = showTrafficLayer;
    
    self.rightSwitchTrafficBtn.selected = !showTrafficLayer;
    self.internalMapView.showTraffic = showTrafficLayer;
}

- (void)setShowTurnArrow:(BOOL)showTurnArrow {
    
    if (_showTurnArrow == showTurnArrow) {
        return;
    }
    
    _showTurnArrow = showTurnArrow;
    
    [self updateRouteTurnArrowPolylineWithSegmentIndex:self.currentNaviInfo.currentSegmentIndex];
    
}

- (void)setShowCompass:(BOOL)showCompass {
    _showCompass = showCompass;
    self.internalMapView.showsCompass = showCompass;
}

- (void)setCameraDegree:(CGFloat)cameraDegree {
    
    _cameraDegree = MAX(0, MIN(60.0, cameraDegree));
    
    if (self.lockCarPosition) {  //锁车模式下，摄像机的角度才是固定，生效的，非锁车模式下，用户自己会旋转成任意值。所以如果当前在锁车，直接改，不在锁车不用改，等切到锁车的时候，那边会改
        [self.internalMapView setCameraDegree:_cameraDegree animated:YES duration:kAMapNaviInternalAnimationDuration];
    }
    
}

- (CGFloat)mapZoomLevel {
    return self.internalMapView.zoomLevel;
}

- (void)setMapZoomLevel:(CGFloat)mapZoomLevel {
    
    self.showMode = AMapNaviDriveViewShowModeNormal;  //设置zoomLevel进入非锁车状态
    
    [self.internalMapView setZoomLevel:mapZoomLevel animated:YES];
}

- (BOOL)showScale {
    return self.internalMapView.showsScale;
}

- (void)setShowScale:(BOOL)showScale {
    [self.internalMapView setShowsScale:showScale];
}


- (CGPoint)scaleOrigin {
    return self.internalMapView.scaleOrigin;
}

- (void)setScaleOrigin:(CGPoint)scaleOrigin {
    [self.internalMapView setScaleOrigin:scaleOrigin];
}


- (BOOL)customMapStyleEnabled {
    return self.internalMapView.customMapStyleEnabled;
}

- (void)setCustomMapStyleEnabled:(BOOL)customMapStyleEnabled {
    
    if (customMapStyleEnabled) {
        self.internalMapView.mapType = MAMapTypeStandard;
    } else {
        self.internalMapView.mapType = _showStandardNightType ? MAMapTypeStandardNight : MAMapTypeNavi;
    }
    
    [self.internalMapView setCustomMapStyleEnabled:customMapStyleEnabled];
}

- (void)setCustomMapStyle:(NSData *)customJson {
    [self.internalMapView setCustomMapStyle:customJson];
}

- (void)setCustomCalloutView:(MACustomCalloutView *)customCalloutView {
    
    _customCalloutView = customCalloutView;
    
    //carAnnotation未添加只保留customCalloutView的设置
    if (self.carAnnotationView == nil) return;
    
    if (_customCalloutView == nil) {
        [self.carAnnotationView setCustomCalloutView:nil];
        
        self.carAnnotationView.enabled = NO;
        self.carAnnotationView.canShowCallout = NO;
        [self.internalMapView deselectAnnotation:self.carAnnotation animated:NO];
    } else {
        [self.carAnnotationView setCustomCalloutView:_customCalloutView];
        
        self.carAnnotationView.enabled = YES;
        self.carAnnotationView.canShowCallout = YES;
        [self.internalMapView selectAnnotation:self.carAnnotation animated:NO];
    }
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = (lineWidth <= 0 ? AMapNaviRoutePolylineDefaultWidth : lineWidth);
    [self updateRoutePolyline];  //重绘路径
}

- (void)setNormalTexture:(UIImage *)normalTexture {
    _normalTexture = [normalTexture copy];
    
    [self updateRoutePolyline];  //更新RoutePolyline
}

- (void)setStatusTextures:(NSDictionary<NSNumber *,UIImage *> *)statusTextures {
    
    _statusTextures = [statusTextures copy];
    
    [self updateRoutePolyline];   //更新RoutePolyline
}

- (void)setCameraImage:(UIImage *)cameraImage {
    
    _cameraImage = cameraImage;
    
    [self.internalMapView.annotations enumerateObjectsUsingBlock:^(id<MAAnnotation> obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[AMapNaviCameraAnnotationX class]]) {
            [[self.internalMapView viewForAnnotation:obj] setImage:_cameraImage];
        }
    }];
}

- (void)setStartPointImage:(UIImage *)startPointImage {
    
    _startPointImage = startPointImage;
    
    [self.internalMapView.annotations enumerateObjectsUsingBlock:^(id<MAAnnotation> obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[AMapNaviStartPointAnnotationX class]]) {
            [[self.internalMapView viewForAnnotation:obj] setImage:_startPointImage];
        }
    }];
}

- (void)setWayPointImage:(UIImage *)wayPointImage {
    _wayPointImage = wayPointImage;
    
    [self.internalMapView.annotations enumerateObjectsUsingBlock:^(id<MAAnnotation> obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[AMapNaviWayPointAnnotationX class]]) {
            [[self.internalMapView viewForAnnotation:obj] setImage:_wayPointImage];
        }
    }];
}

- (void)setEndPointImage:(UIImage *)endPointImage {
    _endPointImage = endPointImage;
    
    [self.internalMapView.annotations enumerateObjectsUsingBlock:^(id<MAAnnotation> obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[AMapNaviEndPointAnnotationX class]]) {
            [[self.internalMapView viewForAnnotation:obj] setImage:_endPointImage];
        }
    }];
}

- (void)setCarImage:(nullable UIImage *)carImage {
    
    _carImage = carImage;
    
    if (self.carAnnotationView) {
        [self.carAnnotationView setCarImage:_carImage];
    }
}

- (void)setCarCompassImage:(nullable UIImage *)carCompassImage {
    
    _carCompassImage = carCompassImage;
    
    if (self.carAnnotationView) {
        [self.carAnnotationView setCompassImage:_carCompassImage];
    }
    
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
        self.showMode = AMapNaviDriveViewShowModeNormal;
    }
    
}

- (void)setShowMode:(AMapNaviDriveViewShowMode)showMode {
    
    if (_showMode == showMode) {
        return;
    }
    
    _showMode = showMode;
    
    if (showMode == AMapNaviDriveViewShowModeNormal) {
        [self handleShowModeToNormal];
    } else if (showMode == AMapNaviDriveViewShowModeCarPositionLocked) {
        [self handleShowModeToLockedCarPosition];
    } else if (showMode == AMapNaviDriveViewShowModeOverview) {
        [self handleShowModeToOverview];
    }
}

- (void)handleShowModeToNormal {
    self.lockCarPosition = NO;
    [self updateBottomInfoView];
    self.bottomContinueNaviBgView.hidden = NO;
    self.rightSwitchTrafficBtn.hidden = NO;
    self.zoomInBtn.superview.hidden = NO;
    self.rightBrowserBtn.hidden = NO;
    self.rightBrowserBtn.selected = NO;  //从锁车模式或者全览模式，点击一下地图，都会切成普通模式，普通模式下，全览按钮就是可见且未被选择的状态
    self.speedLabel.superview.hidden = YES;
    
    [self handleWhenCrossImageShowAndHide:nil];
    
}

- (void)handleShowModeToLockedCarPosition {
    self.lockCarPosition = YES;
    [self updateBottomInfoView];
    self.bottomContinueNaviBgView.hidden = YES;
    self.rightSwitchTrafficBtn.hidden = YES;
    self.zoomInBtn.superview.hidden = YES;
    self.rightBrowserBtn.hidden = YES;
    self.speedLabel.superview.hidden = NO;
    
    [self handleRightTrafficBarViewShowOrHide];
    
    //恢复锁车模式，设置地图和车为正确状态，特别是车的倾斜角度,先把地图的倾斜角度设置对了，根据地图的倾斜角度设置车，顺序不能乱，设置车的倾斜角度中，也要设置地图的旋转角度
    if (self.carAnnotation) {
        [self changeToNaviModeAtPoint:[AMapNaviPoint locationWithLatitude:self.carAnnotation.coordinate.latitude longitude:self.carAnnotation.coordinate.longitude]];
    }
    [self resetCarAnnotaionToRightStateAndIsNeedResetMapView:YES];
    
    //如果从缩小到很小的非锁车模式（这个时候是没有电子眼图标的）直接点击“继续导航”，变成锁车模式，需要电子眼图标，所以需要画出来，不加这句话，就没有
    [self updateRouteCameraAnnotationWithStartIndex:0];
    [self updateRouteCameraAnnotationWithCameraInfos:self.cameraInfos];
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
    
    UIEdgeInsets insets = UIEdgeInsetsMake(80, 80, 80, 80);
    
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
    self.currentNaviMode = naviMode;
}

//路径信息更新：每次换路后，开始导航的时候才会调用一次(或者两次)，可用来设置这次导航路线的起点，让地图的初始位置正确，电子眼的初始化
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateNaviRoute:(AMapNaviRoute *)naviRoute {
    
    self.currentNaviRoute = naviRoute;
    
    //画出规划的路径，一般在这里画的路径都是不带路况信息，因为路况信息的回调还没调用。
    [self updateRoutePolyline];
    
    //牵引线
    [self updateCarToDestinationGuidLine];
    
    //起点，终点，沿途的点的绘制
    [self updateRoutePointAnnotation];
    
    //非全览模式下，改变地图的中心点，缩放级别，摄像机角度。全览模式下，不能改变，否则界面按钮选中状态和地图状态不匹配，反正从全览模式到锁车模式changeToNaviModeAtPoint还会被调用
    if (self.showMode != AMapNaviDriveViewShowModeOverview) {
        [self changeToNaviModeAtPoint:self.currentNaviRoute.routeStartPoint];
    } else {  //全览模式下，重新适应一下，让路线都在可视范围内
        [self showMapRegionWithBounds:self.currentNaviRoute.routeBounds centerCoordinate:self.currentNaviRoute.routeCenterPoint];
    }
    
    //更新电子眼信息,这里的显示与否取决于zoomLevel.
    [self updateRouteCameraAnnotationWithStartIndex:0];
    
    //更新转向箭头，这里的显示与否有取决于zoomLevel,所以必须在changeToNaviModeAtPoint先把zoomLebel设定对了，再执行这个函数，第一个路口才会有箭头，而且changeToNaviModeAtPoint里面setZoomLevel不能有动画
    [self updateRouteTurnArrowPolylineWithSegmentIndex:0];
    
    //初始化一下，让一有路径信息，就有自车图标
    [self carAnnotation];
    
}

//导航实时信息更新，如果是模拟导航，自车位置开始一段时间后，就不再更新，但是导航实时信息一直在更新，所以模拟导航以这个回调为准
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateNaviInfo:(AMapNaviInfo *)naviInfo {
    
    //第一次没有self.currentNaviInfo需要，上一次导航信息的摄像头索引和这次的不一样也需要。
    BOOL isNeedUpdateTurnArrow = self.currentNaviInfo ? (self.currentNaviInfo.currentSegmentIndex != naviInfo.currentSegmentIndex) : YES;
    
    self.currentNaviInfo = naviInfo;
    
    //InfoView
    [self updateTopInfoView];
    [self updateBottomInfoView];
    
    //更新光柱中车的位置
    if (self.currentNaviRoute.routeLength > 0 && self.currentNaviInfo) {
        double posPercent = 1 - (double)self.currentNaviInfo.routeRemainDistance / self.currentNaviRoute.routeLength;
        [self.rightTrafficBarView updateTrafficBarWithCarPositionPercent:posPercent];
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
    
    self.currentCarLocation = naviLocation;
    
    self.speedLabel.text = [NSString stringWithFormat:@"%@",naviLocation.speed > 0 ? [NSString stringWithFormat:@"%ld",naviLocation.speed] : @"--"];
    
    if (self.carAnnotation == nil) {
        return;
    }
    
    //车的位置改变，需要对车的图标进行移动
    [self moveCarAnnotationToCoordinate:self.currentCarLocation.coordinate direction:self.currentCarLocation.heading zoomLevel:kAMapNaviLockStateZoomLevel];
    
}

//路况信息更新
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateTrafficStatus:(NSArray<AMapNaviTrafficStatus *> *)trafficStatus {
    
    self.trafficStatus = trafficStatus;
    
    //更新光柱中的路况信息
    if (trafficStatus) {
        [self.rightTrafficBarView updateTrafficBarWithTrafficStatuses:trafficStatus];
    }
    
    [self updateRoutePolyline]; //如果路况信息更新了，就要重画
}

//需要显示路口放大图了
- (void)driveManager:(AMapNaviDriveManager *)driveManager showCrossImage:(UIImage *)crossImage {
    [self handleWhenCrossImageShowAndHide:crossImage];
}

//需要把路口放大图了隐藏了
- (void)driveManagerHideCrossImage:(AMapNaviDriveManager *)driveManager {
    [self handleWhenCrossImageShowAndHide:nil];
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
        
        //高德地图和百度地图，如果导航的起点设置在离目前定位点很远的地方，是直接跳到导航起点开始导航，但是只要一移动(自车位置一回调)，车图标就会定位到当前位置，并触发偏航重算。所以我们先把车的初始位置放在起点.
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
    self.internalMapView.showsCompass = self.showCompass;
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


- (void)handleWhenCrossImageShowAndHide:(UIImage *)crossImage {
    
    if (self.showUIElements == NO) {  //如果不显示UI界面，这边就不处理，以便地图一直全屏
        return;
    }
    
    //1.有图，且锁车模式，且self.showCrossImage = YES，才显示路口放大图
    //2.目前有路口放大图，变成非锁车模式后，干掉路口放大图
    if (crossImage && self.showMode == AMapNaviDriveViewShowModeCarPositionLocked && self.showCrossImage) {  //有路口放大图，不管目前是横竖屏，统一都改了，当他切换横竖屏的时候自然好使
        self.crossImageView.image = crossImage;
        self.mapViewTopPortrait.constant = self.topInfoViewHeightInCrossModePortrait.constant;  //竖屏下
        self.mapViewLeftLandscape.constant = self.crossImageViewWidthLandScape.constant;  //横屏下
        self.topInfoContainerViewInCrossMode.hidden = NO;
        
    } else {
        self.crossImageView.image = nil;
        self.mapViewTopPortrait.constant = self.topInfoViewHeightPortrait.constant;  //竖屏下
        self.mapViewLeftLandscape.constant = self.topInfoViewWidthLandscape.constant;  //横屏下
        self.topInfoContainerViewInCrossMode.hidden = YES;
    }
    
    [self handleRightTrafficBarViewShowOrHide];
    
}


#pragma -mark 车道信息图 

- (void)configureLaneInfoView {
    self.laneInfoView.hidden = YES;
}

#pragma -mark TopInfoView

- (void)configureTopInfoView {
    self.topInfoView.superview.backgroundColor = kAMapNaviInfoViewBackgroundColor;
    self.topInfoView.hidden = YES;
    
    self.topInfoContainerViewInCrossMode.backgroundColor = kAMapNaviInfoViewBackgroundColor;
    self.topInfoContainerViewInCrossMode.hidden = YES;
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(turnImageViewTap)];
    UITapGestureRecognizer *tapGes1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(turnImageViewTap)];
    [self.topTurnImageView addGestureRecognizer:tapGes];
    [self.topTurnImageViewInCrossMode addGestureRecognizer:tapGes1];
}

- (void)turnImageViewTap {
    
}

- (void)updateTopInfoView {
    if (self.currentNaviInfo) {
        
        self.topTurnRemainLabel.text = [NSString stringWithFormat:@"%@后",[AMapNaviViewUtilityX normalizedRemainDistance:self.currentNaviInfo.segmentRemainDistance]];
        self.topRoadLabel.text = self.currentNaviInfo.nextRoadName;
        
        self.topTurnRemainLabelInCrossMode.text = self.topTurnRemainLabel.text;
        self.topRoadLabelInCrossMode.text = self.topRoadLabel.text;
        
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:AMapNaviInfoViewTurnIconImage,(long)self.currentNaviInfo.iconType]];
        if (image == nil) {
            image = [UIImage imageNamed:[NSString stringWithFormat:AMapNaviInfoViewTurnIconImage,(long)AMapNaviIconTypeStraight]];
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

#pragma -mark BottomInfoView

- (void)configureBottomInfoView {
    self.bottomRemainBgView.hidden = YES;
    self.bottomContinueNaviBgView.hidden = YES;
    self.bottomBgImageViewPortrait.image = [[UIImage imageNamed:@"default_navi_bottom_bg"] stretchableImageWithLeftCapWidth:25 topCapHeight:25];
    self.bottomContinueNaviBtnInLandscape.layer.cornerRadius = 3;
}

- (void)updateBottomInfoView {
    if (self.currentNaviInfo && (self.showMode == AMapNaviDriveViewShowModeCarPositionLocked || self.showMode == AMapNaviDriveViewShowModeOverview)) {  //如果不是锁车状态或者全览模式，bottomRemainBgView不应该显示
        
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

#pragma -mark RightTipsView

- (void)configureRightTipsView {
    self.rightBrowserBtn.hidden = YES;
    self.rightSwitchTrafficBtn.hidden = YES;
    self.zoomInBtn.superview.hidden = YES;
    self.swtichTrackModeBtn.selected = self.trackingMode == AMapNaviViewTrackingModeCarNorth ? NO : YES;
    [self updateZoomButtonState];
}

- (void)handleRightTrafficBarViewShowOrHide {
    
    //只有在锁车模式，且没有路口放大图，才会有光柱图,其实，现在的逻辑就是锁车，一定不会有路口放大图了，所以 && self.crossImageView.image == nil 有点多余
    if (self.showMode == AMapNaviDriveViewShowModeCarPositionLocked && self.crossImageView.image == nil && self.showTrafficBar) {
        self.rightTrafficBarView.hidden = NO;
    } else {
        self.rightTrafficBarView.hidden = YES;
    }
}

//当设置全览或者设置按钮的显示与隐藏后，需要调用的
- (void)handleRightBrowserBtnBottomLandscape {
    
    if (self.showMoreButton && self.showBrowseRouteButton) {  //两者都有
        self.rightBrowserBtnBottomLandscape.constant = 63;
    } else if (!self.showMoreButton && !self.showBrowseRouteButton) {  //两者都没有
        self.rightBrowserBtnBottomLandscape.constant = 1;
    } else if(self.showMoreButton && !self.showBrowseRouteButton){  //有设置，没预览
        self.rightBrowserBtnBottomLandscape.constant = 55;
    } else if (!self.showMoreButton && self.showBrowseRouteButton) {  //有预览，没设置
        self.rightBrowserBtnBottomLandscape.constant = 5;
    }
    
}

//这个函数目前不使用，隐藏全览按钮，不通过此方法处理，直接改按钮的高度
- (void)handleRightBrowserBtnShowOrHide {
    
    if (self.showMode == AMapNaviDriveViewShowModeCarPositionLocked || self.showBrowseRouteButton == NO) {
        self.rightBrowserBtn.hidden = YES;
    } else {
        self.rightBrowserBtn.hidden = NO;
    }
    
    if (self.showMode == AMapNaviDriveViewShowModeNormal) {
        self.rightBrowserBtn.selected = NO;  //从锁车模式或者全览模式，点击一下地图，都会切成普通模式，普通模式下，全览按钮就是可见且未被选择的状态
    }
    
}

- (void)updateZoomButtonState {
    self.zoomInBtn.enabled = self.internalMapView.zoomLevel < self.internalMapView.maxZoomLevel;
    self.zoomOutBtn.enabled = self.internalMapView.zoomLevel > self.internalMapView.minZoomLevel;
}

#pragma -mark Xib btns click

//更多按钮点击
- (IBAction)moreBtnClick:(id)sender {

}

- (IBAction)switchTrackingMode:(id)sender {
    
    UIButton *btn = (UIButton *)sender;
    
    //更改跟随模式
    if (self.trackingMode == AMapNaviViewTrackingModeMapNorth) {
        self.trackingMode = AMapNaviViewTrackingModeCarNorth;
        btn.selected = NO;
    } else if (self.trackingMode == AMapNaviViewTrackingModeCarNorth) {
        self.trackingMode = AMapNaviViewTrackingModeMapNorth;
        btn.selected = YES;
    }
}


//继续导航按钮点击
- (IBAction)continueNaviBtnClick:(id)sender {
    self.showMode = AMapNaviDriveViewShowModeCarPositionLocked;  //切换成锁车模式
}

//切换路况按钮点击
- (IBAction)swichTrafficBtnClick:(id)sender {
    self.showTrafficLayer = !self.showTrafficLayer;
}


//全览按钮点击
- (IBAction)browserBtnClick:(id)sender {
    UIButton *btn = (UIButton *)sender;
    
    if (btn.selected == NO) {  //点击从普通模式切换成全览模式
        self.showMode = AMapNaviDriveViewShowModeOverview;
    } else { //点击从全览模式切换成锁车模式
        self.showMode = AMapNaviDriveViewShowModeCarPositionLocked;
    }
    
    btn.selected = !btn.selected;
}

- (IBAction)zoomInButtonAction:(id)sender {
    [self.internalMapView setZoomLevel:(self.internalMapView.zoomLevel + 1.0) animated:YES];
    [self updateZoomButtonState];
}

- (IBAction)zoomOutButtonAction:(id)sender {
    [self.internalMapView setZoomLevel:(self.internalMapView.zoomLevel - 1.0) animated:YES];
    [self updateZoomButtonState];
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
    
    [self removeRouteCameraAnnotation];  //每次更新前，先全部移除所有电子眼
    
    if (self.currentNaviRoute == nil || self.showCamera == NO) {  //没有路径，就无从显示
        return;
    }
    
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
    
    if (self.showCamera == NO) {
        return;
    }
    
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
        
        self.carToDestinationGuidePolyline = [AMapNaviGuidePolylineX polylineWithCoordinates:coordinates count:2];
        
        free(coordinates);
        coordinates = NULL;
        
        [self removeCarToDestinationGuidLine];  //分开写remove，保证再加入新的，才把就的移除掉，防止出现2条
        
        [self.internalMapView addOverlay:self.carToDestinationGuidePolyline level:MAOverlayLevelAboveLabels];
    }
}

//remove
- (void)removeCarToDestinationGuidLine{
    [self.internalMapView.overlays enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[AMapNaviGuidePolylineX class]]) {
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
    
    if (self.currentNaviRoute == nil || self.showTurnArrow == NO ) {
        return;
    }
    
    if (segmentIndex < 0 || segmentIndex >= self.currentNaviRoute.routeSegmentCount - 1) {  //最后一个分段也不用更新
        return;
    }
    
    //如果用户把地图缩放得很小，箭头的宽度还是那么大，覆盖了地图的区域就很大了，不精确了，就没有指导意义了
    if (self.internalMapView.zoomLevel < kAMapNaviShowTurnArrowMinZoomLevel || self.internalMapView.zoomLevel > kAMapNaviShowTurnArrowMaxZoomLevel) {
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
        
        double dis = [AMapNaviViewUtilityX distanceBetweenCoordinates:curSegCoor[i] andPoint:curSegCoor[i - 1]];
        
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
        
        double dis = [AMapNaviViewUtilityX distanceBetweenCoordinates:nextSegCoor[i] andPoint:nextSegCoor[i + 1]];
        
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
        
        double segmenLength = [AMapNaviViewUtilityX distanceBetweenCoordinates:oriCoordinateArray[i - 1] andPoint:oriCoordinateArray[i]]; //A到B的长度，B到C，C到D，D到E,第二个循环：E到F,F到G
        
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
            UIImage *image = [self textureImageWithTrafficPolyline:self.trafficStatus[statusesIndex].status]; //AE`的纹理
            if (image) {
                [resultTextureImagesArray addObject:image];
            }
            
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
        UIImage *image = [self textureImageWithTrafficPolyline:self.trafficStatus.lastObject.status];
        if (image) {
            [resultTextureImagesArray addObject:image];
        }
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
    UIImage *image = [self textureImageWithoutTrafficPolyline];
    if (image) {
       polyline.polylineTextureImages = @[image];
    }
    
    free(coordinates);
    coordinates = NULL;
    
    [self.internalMapView addOverlay:polyline level:MAOverlayLevelAboveRoads];
}

//没有交通状态的纹理图片
- (UIImage *)textureImageWithoutTrafficPolyline {
    
    UIImage *textureImage = (self.normalTexture != nil ? self.normalTexture : [UIImage imageNamed:AMapNaviRoutePolylineImageDefault]);
    
    return textureImage;
}

- (UIImage *)textureImageWithTrafficPolyline:(AMapNaviRouteStatus)routeStatus {
    
    UIImage *textureImage = [self.statusTextures objectForKey:@(routeStatus)];
    
    return (textureImage != nil ? textureImage : [self defaultTextureImageForRouteStatus:routeStatus]);
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
        
        [self updateRouteTurnArrowPolylineWithSegmentIndex:self.currentNaviInfo.currentSegmentIndex]; //更新turnArrowPolyline
        [self updateRouteCameraAnnotationWithStartIndex:0]; //实现全览或者地图缩放的比较小，摄像头不画，放大到一定程度，又有摄像头
        [self updateRouteCameraAnnotationWithCameraInfos:self.cameraInfos]; //同上
        [self updateZoomButtonState]; //更新zoomButtonState
    }
    
}

- (void)mapView:(MAMapView *)mapView didDeselectAnnotationView:(MAAnnotationView *)view {
    if (view == self.carAnnotationView && self.customCalloutView != nil) {
        [self.internalMapView selectAnnotation:self.carAnnotation animated:NO];
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
    } else if ([overlay isKindOfClass:[AMapNaviGuidePolylineX class]]) {  //牵引线
        
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
        
        [self.carAnnotationView setZIndex:INT_MAX];
        [self.carAnnotationView setCarImage:self.carImage];
        [self.carAnnotationView setCompassImage:self.carCompassImage];
        
        self.carAnnotationView.enabled = NO;
        self.carAnnotationView.canShowCallout = NO;
        self.carAnnotationView.draggable = NO;
        
        [self setCustomCalloutView:self.customCalloutView];
        
        return self.carAnnotationView;
    } else if ([annotation isKindOfClass:[AMapNaviCameraAnnotationX class]]) {
        
        static NSString *cameraAnnIdentifier = @"AMapNaviCameraAnnotationViewIdentifier";
        
        AMapNaviCameraAnnotationViewX *annView = (AMapNaviCameraAnnotationViewX *)[mapView dequeueReusableAnnotationViewWithIdentifier:cameraAnnIdentifier];
        if (annView == nil) {
            annView = [[AMapNaviCameraAnnotationViewX alloc] initWithAnnotation:annotation reuseIdentifier:cameraAnnIdentifier];
        }
        
        [annView setImage:_cameraImage];
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
        
        [annView setImage:_startPointImage];
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
        
        [annView setImage:_wayPointImage];
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
        
        [annView setImage:_endPointImage];
        annView.enabled = NO;
        annView.canShowCallout = NO;
        annView.draggable = NO;
        
        return annView;
    }
    
    return  nil;
}

@end
