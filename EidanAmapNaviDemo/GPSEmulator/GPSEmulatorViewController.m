//
//  GPSEmulatorViewController.m
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/2/23.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import "GPSEmulatorViewController.h"
#import <AMapNaviKit/AMapNaviKit.h>
#import "AMapNaviDriveViewX.h"

#import "SpeechSynthesizer.h"
#import "GPSEmulator.h"

@interface GPSEmulatorViewController () <AMapNaviDriveManagerDelegate,AMapNaviDriveViewXDelegate>

@property (nonatomic, strong) AMapNaviDriveManager *driveManager;

@property (nonatomic, strong) AMapNaviPoint *startPoint;
@property (nonatomic, strong) AMapNaviPoint *endPoint;

@property (nonatomic, weak) IBOutlet AMapNaviDriveViewX *driveView;

@property (nonatomic, strong) GPSEmulator *gpsEmulator;

@end

@implementation GPSEmulatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.gpsEmulator = [[GPSEmulator alloc] init];
    
    //为了方便展示GPS模拟的结果，我们提前录制了一段GPS坐标，同时配合固定的两个点进行算路导航
    self.startPoint = [AMapNaviPoint locationWithLatitude:40.080603 longitude:116.602853];  //机场
//    self.startPoint = [AMapNaviPoint locationWithLatitude:39.989773 longitude:116.479872];
//    self.endPoint   = [AMapNaviPoint locationWithLatitude:39.992194 longitude:116.482474];
//    self.endPoint = [AMapNaviPoint locationWithLatitude:39.992405 longitude:116.482665];
    self.endPoint   = [AMapNaviPoint locationWithLatitude:39.995839 longitude:116.451204];
    
    self.driveManager = [[AMapNaviDriveManager alloc] init];
    [self.driveManager setDelegate:self];
    
    self.driveView.delegate = self;
    
    //将driveView添加为导航数据的Representative，使其可以接收到导航诱导数据
    [self.driveManager addDataRepresentative:self.driveView];
}

- (void)viewDidAppear:(BOOL)animated {
    [self calculateRoute];
}

//进行路径规划
- (void)calculateRoute {
    [self.driveManager calculateDriveRouteWithStartPoints:@[self.startPoint]
                                                endPoints:@[self.endPoint]
                                                wayPoints:nil
                                          drivingStrategy:AMapNaviDrivingStrategySingleDefault];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    NSLog(@"------------------ VC dealloc");
}

#pragma mark - GPS Emulator

//开始传入GPS模拟数据进行导航
- (void)startGPSEmulator {
    if ([self.gpsEmulator isSimulating])
    {
        NSLog(@"GPSEmulator is already running");
        return;
    }
    
    //开启使用外部GPS数据
    [self.driveManager setEnableExternalLocation:YES];
    
    //开始GPS导航
    [self.driveManager startGPSNavi];
    
    __weak typeof(self) weakSelf = self;
    [self.gpsEmulator startEmulatorUsingLocationBlock:^(CLLocation *location, NSUInteger index, NSDate *addedTime, BOOL *stop) {
        
        //注意：需要使用当前时间作为时间戳
        CLLocation *newLocation = [[CLLocation alloc] initWithCoordinate:location.coordinate
                                                                altitude:location.altitude
                                                      horizontalAccuracy:location.horizontalAccuracy
                                                        verticalAccuracy:location.verticalAccuracy
                                                                  course:location.course
                                                                   speed:location.speed
                                                               timestamp:[NSDate dateWithTimeIntervalSinceNow:0]];
        
        //传入GPS模拟数据
        [weakSelf.driveManager setExternalLocation:newLocation isAMapCoordinate:NO];
        
//        NSLog(@"SimGPS:{%f-%f-%f-%f}", location.coordinate.latitude, location.coordinate.longitude, location.speed, location.course);
    }];
}

//停止传入GPS模拟数据
- (void)stopGPSEmulator {
    [self.gpsEmulator stopEmulator];
    
    [self.driveManager stopNavi];
    
//    [self.driveManager setEnableExternalLocation:NO];
}


#pragma mark - AMapNaviDriveViewXDelegate

- (void)driveViewXCloseButtonClicked:(AMapNaviDriveViewX *)driveView {
    
    //停止导航
    
    [self stopGPSEmulator];
    
    [self.driveManager removeDataRepresentative:self.driveView];
    
    //停止语音
    [[SpeechSynthesizer sharedSpeechSynthesizer] stopSpeak];
    
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - AMapNaviDriveManager Delegate

- (void)driveManager:(AMapNaviDriveManager *)driveManager error:(NSError *)error
{
    NSLog(@"error:{%ld - %@}", (long)error.code, error.localizedDescription);
}

- (void)driveManagerOnCalculateRouteSuccess:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"onCalculateRouteSuccess");
//    [self startGPSEmulator];
    [self performSelector:@selector(startGPSEmulator) withObject:nil afterDelay:5];
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager onCalculateRouteFailure:(NSError *)error
{
    NSLog(@"onCalculateRouteFailure:{%ld - %@}", (long)error.code, error.localizedDescription);
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager didStartNavi:(AMapNaviMode)naviMode
{
    NSLog(@"didStartNavi");
}

- (void)driveManagerNeedRecalculateRouteForYaw:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"needRecalculateRouteForYaw");
}

- (void)driveManagerNeedRecalculateRouteForTrafficJam:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"needRecalculateRouteForTrafficJam");
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager onArrivedWayPoint:(int)wayPointIndex
{
    NSLog(@"onArrivedWayPoint:%d", wayPointIndex);
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType
{
    //    NSLog(@"playNaviSoundString:{%ld:%@}", (long)soundStringType, soundString);
    
    [[SpeechSynthesizer sharedSpeechSynthesizer] speakString:soundString];
}

- (void)driveManagerDidEndEmulatorNavi:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"didEndEmulatorNavi");
}

- (void)driveManagerOnArrivedDestination:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"onArrivedDestination");
    [self stopGPSEmulator];
}




@end
