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

#define kAMapNaviMoveCarSplitCount              14  //值越大，车的运动越平滑
#define kAMapNaviMoveCarTimeInterval            (1.0/kAMapNaviMoveCarSplitCount)
#define kAMapNaviInternalAnimationDuration      0.2f

#define kAMapNaviLockStateZoomLevel             18.0f
#define kAMapNaviLockStateCameraDegree          30.0f

#define kAMapNaviMoveDirectlyMaxDistance        300.0f
#define kAMapNaviMoveDirectlyMinDistance        1.0f

@interface AMapNaviDriveViewX ()<MAMapViewDelegate>

@property (nonatomic, strong) IBOutlet UIView *customView;

//mapView
@property (nonatomic, weak) IBOutlet MAMapView *internalMapView;

//private
@property (nonatomic, assign) BOOL lockCarPosition;  //车相对屏幕的位置是否不改变，YES代表不改变，车永远在屏幕中间，那么就需要移动地图中心点，NO代表改变，不需要改变地图中心点.

//car
@property (nonatomic, strong) NSTimer *moveCarTimer;
@property (nonatomic, strong) AMapNaviCarAnnotationX *carAnnotation;
@property (nonatomic, strong) AMapNaviCarAnnotationViewX *carAnnotationView;

//bottomInfoView
@property (nonatomic, weak) IBOutlet UIView *bottomInfoView;

//Data Component
@property (nonatomic, assign) BOOL needMoving;  //车的位置和方向是否需要改变，规则是：每更新一次导航信息，被设置为YES，车被顺滑的移动14次后，又被设置为NO，不再移动，等待下一次的导航信息更新
@property (nonatomic, assign) BOOL moveDirectly;  //一开始导航的时候，车是否应该被一步到位的设置到指定的起点位置和指定方向，一步到位就是没有动画，直接跳过去。

@property (nonatomic, assign) NSInteger splitCount;
@property (nonatomic, assign) NSInteger stepCount;

@property (nonatomic, strong) AMapNaviPoint *priorPoint;
@property (nonatomic, assign) double priorCarDirection;
@property (nonatomic, assign) double priorZoomLevel;

@property (nonatomic, assign) double directionOffset;
@property (nonatomic, assign) double zoomLevelOffset;
@property (nonatomic, assign) double latOffset;  //纬度
@property (nonatomic, assign) double lonOffset;  //经度


//Data Representable
@property (nonatomic, assign) AMapNaviMode currentNaviMode;
@property (nonatomic, copy) AMapNaviLocation *currentCarLocation;
@property (nonatomic, copy) AMapNaviInfo *currentNaviInfo;
@property (nonatomic, copy) AMapNaviRoute *currentNaviRoute;  //当前导航的路径的信息



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
    
    [self initProperties];
    
    //bottomInfoView
    [self configureBottomInfoView];
    
    //mapView
    [self configureMapView];
    
    [self startMoveCarTimer];
    
}

- (void)initProperties {
    self.splitCount = kAMapNaviMoveCarSplitCount;
    self.needMoving = NO;
    self.moveDirectly = YES;
    
    self.cameraDegree = kAMapNaviLockStateCameraDegree;
    
    //private
    self.lockCarPosition = YES;
    
}

- (void)layoutSubviews {
    self.customView.frame = self.bounds;
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

//车的移动
- (void)moveCarLocationSmooth:(NSTimer *)timer {
    
    if (self.needMoving == NO) {
        return;
    }
    
    if (self.moveDirectly) {  //moveDirectly只有初始化的时候被设置为YES，然后车被一步到位的移动到指定位置后，就设置为No，所以这个分支最多只会执行一次
        double desLat = self.priorPoint.latitude + self.latOffset * self.splitCount;
        double desLon = self.priorPoint.longitude + self.lonOffset * self.splitCount;
        double desDirection = self.priorCarDirection + self.directionOffset * self.splitCount;
        
        if (self.lockCarPosition) {  //
            [self.internalMapView setRotationDegree:0 animated:YES duration:kAMapNaviInternalAnimationDuration];
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
        
        if (self.lockCarPosition) {
            [self.internalMapView setRotationDegree:0 animated:YES duration:kAMapNaviInternalAnimationDuration];
            [self.internalMapView setCenterCoordinate:CLLocationCoordinate2DMake(stepLat, stepLon) animated:YES];
        }
        
        [self.carAnnotation setCoordinate:CLLocationCoordinate2DMake(stepLat, stepLon)];
        [self.carAnnotationView setCarDirection:stepDirection];
        [self.carAnnotationView setCompassDirection:0];
        
    } else {
        self.stepCount = 0;
        self.needMoving = NO;
    }
    
}

//上一次导航信息更新后的一些信息记录为prior，通过这一次导航信息和上一次信息的差值除于14，表示每一次设置的单位量，timer中就会每一次增加一个单位量，来平滑的做动画.
- (void)moveCarToCoordinate:(AMapNaviPoint *)coordinate direction:(double)direction zoomLevel:(double)zoomLevle {
    if (coordinate == nil || coordinate.latitude == 0 || coordinate.longitude == 0) {
        return;
    }
    
    self.priorPoint = [AMapNaviPoint locationWithLatitude:self.carAnnotation.coordinate.latitude longitude:self.carAnnotation.coordinate.longitude];
    self.priorCarDirection = self.carAnnotationView.carDirection;
    self.priorZoomLevel = self.internalMapView.zoomLevel;
    
    self.stepCount = 0;
    self.latOffset = (coordinate.latitude - self.priorPoint.latitude) / self.splitCount;
    self.lonOffset = (coordinate.longitude - self.priorPoint.longitude) / self.splitCount;
    self.directionOffset = [self normalizeOffsetDegree:(direction - self.priorCarDirection)] / self.splitCount;
    self.zoomLevelOffset = (zoomLevle - self.priorZoomLevel) / self.splitCount;
    
    self.needMoving = YES;
    
}

- (double)normalizeOffsetDegree:(double)degree {
    return degree + ((degree > 180.f) ? -360.f : (degree < -180.f) ? 360.f : 0);
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

#pragma -mark AMapNaviDriveDataRepresentable

//导航模式更新，停止导航，开始GPS导航，开始模拟导航，的时候才会调用一次
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateNaviMode:(AMapNaviMode)naviMode {
    NSLog(@"导航模式更新");
    
    self.currentNaviMode = naviMode;
    
    self.moveDirectly = YES;
    
}

//路径信息更新：每次换路后，开始导航的时候才会调用一次(或者两次)，可用来设置这次导航路线的起点，让地图的初始位置正确。
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateNaviRoute:(AMapNaviRoute *)naviRoute {
    NSLog(@"路径信息更新");
    
    self.currentNaviRoute = naviRoute;
    
    //地图的中心点，缩放级别，摄像机角度
    [self changeToNaviModeAtPoint:self.currentNaviRoute.routeStartPoint];
    
}

//导航信息更新，如果是模拟导航，自车位置开始一段时间后，就不再更新，但是导航信息一直在更新，所以模拟导航以这个回调为准
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateNaviInfo:(AMapNaviInfo *)naviInfo {
    NSLog(@"导航信息更新");
    
    self.currentNaviInfo = naviInfo;
    
    if (self.carAnnotation == nil) {
        return;
    }
    
    //更新地图显示
    if (self.currentNaviMode == AMapNaviModeEmulator) {
        
        //比如，
        //因为初始化的时候self.moveDirectly设置为YES，timer中会直接一步到位的把车的位置和方向设置对了，可能存在你在楼里，导航开始的点离你比较远，会一直跳跃感。
        //这边需要算一下用户目前的位置和实际开始导航的起点的位置的距离，如果在300米以内，就将moveDirectly设置为NO，表示，timer中不需要移动地图上车的位置（300米这个误差，在地图上显示的感知比较小），如果大于300米，timer中会移动车的位置到指定地点，移动到后也会设置为NO，再也不会设置YES了，这个分支只会走一次。
        if (self.moveDirectly) {
            double distance = [AMapNaviViewUtilityX calcDistanceBetweenPoint:self.currentNaviInfo.carCoordinate andPoint:[AMapNaviPoint locationWithLatitude:self.carAnnotation.coordinate.latitude longitude:self.carAnnotation.coordinate.longitude]];
            NSLog(@"distance : %f",distance);
            if (distance <= kAMapNaviMoveDirectlyMaxDistance && distance > kAMapNaviMoveDirectlyMinDistance) {
                self.moveDirectly = NO;
            }
        }
        
        //每一次导航信息更新后，都算一下，车应该以什么样的角度显示在地图的哪个地方，needMoving 设置为YES。
        [self moveCarToCoordinate:self.currentNaviInfo.carCoordinate direction:self.currentNaviInfo.carDirection zoomLevel:kAMapNaviLockStateZoomLevel];
        
    }
}

//自车位置更新。模拟导航自车位置不更新，GPS导航自车位置才更新
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateNaviLocation:(AMapNaviLocation *)naviLocation {
    NSLog(@"自车位置更新");
    
    self.currentCarLocation = naviLocation;
    
    if (self.carAnnotation == nil) {
        return;
    }
    
    
}

#pragma -mark mapView

- (void)configureMapView {
    self.internalMapView.showsScale = NO;
    self.internalMapView.showsIndoorMap = NO;
    self.internalMapView.showsBuildings = NO;
    self.internalMapView.delegate = self;
    self.internalMapView.zoomLevel = 11.1;
    self.internalMapView.centerCoordinate = CLLocationCoordinate2DMake(39.906207, 116.397582);
}

- (void)updateRouteCameraAnnotationWithStartIndex:(NSInteger)startIndex {
    
    [self removeRouteCameraAnnotation];
    
    int index = (int)startIndex;
    
    while (index < self.currentNaviRoute.routeCameras.count && index < startIndex + 2) {
        AMapNaviCameraInfo *aCamera = [self.currentNaviRoute.routeCameras objectAtIndex:index];
        index++;
    }
}

- (void)removeRouteCameraAnnotation {
//    [self.internalMapView.annotations enumerateObjectsUsingBlock:^(id<MAAnnotation> obj, NSUInteger idx, BOOL *stop) {
//        if ([obj isKindOfClass:[AMapNaviCameraAnnotation class]])
//        {
//            [self.internalMapView removeAnnotation:obj];
//        }
//    }];
}

- (void)changeToNaviModeAtPoint:(AMapNaviPoint *)point {
    
    if (point == nil) return;
    
    [self.internalMapView setCameraDegree:self.cameraDegree animated:YES duration:kAMapNaviInternalAnimationDuration];
    [self.internalMapView setCenterCoordinate:CLLocationCoordinate2DMake(point.latitude, point.longitude) animated:YES];
    [self.internalMapView setZoomLevel:kAMapNaviLockStateZoomLevel animated:YES];
}


#pragma -mark bottomInfoView

- (void)configureBottomInfoView {
    self.bottomInfoView.backgroundColor = [UIColor colorWithRed:40/255.0 green:44/255.0 blue:55/255.0 alpha:0.85];
}

#pragma -mark xib btns click

- (IBAction)goBack:(id)sender {
    
}

#pragma mark - Private: MAMapViewDelegate

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
    }
    
    return  nil;
}

@end
