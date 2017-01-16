//
//  AMapNaviCarAnnotationViewX.m
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/1/13.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import "AMapNaviCarAnnotationViewX.h"
#import "AMapNaviViewUtilityX.h"

#define kCarAnnotationViewCarImage      @"default_navi_car_icon"
#define kCarAnnotationViewCompassImage  @"default_navi_location_compass"

@interface AMapNaviCarAnnotationViewX ()

@property (nonatomic, strong) UIImageView *carImageView;
@property (nonatomic, strong) UIImageView *compassImageView;

@end

@implementation AMapNaviCarAnnotationViewX

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier])
    {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        
        [self buildCarAnnotationView];
    }
    
    return self;
}

- (void)buildCarAnnotationView {
    
//    [self initProperties];
    
    self.carDirection = 0;
    
    [self addSubview:self.compassImageView];
    [self addSubview:self.carImageView];
}

- (UIImageView *)carImageView
{
    if (_carImageView == nil)
    {
        UIImage *carImage = [UIImage imageNamed:kCarAnnotationViewCarImage];
        
        _carImageView = [[UIImageView alloc] initWithImage:carImage];
        
        [_carImageView setFrame:CGRectMake(0, 0, 60, 60)];
        [_carImageView setCenter:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))];
    }
    return _carImageView;
}

- (UIImageView *)compassImageView
{
    if (_compassImageView == nil)
    {
        UIImage *compassImage = [UIImage imageNamed:kCarAnnotationViewCompassImage];
        
        _compassImageView = [[UIImageView alloc] initWithImage:compassImage];
        [_compassImageView setCenter:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))];
        
    }
    return _compassImageView;
}

- (void)setCarDirection:(double)carDirection {
    
    _carDirection = [AMapNaviViewUtilityX normalizeDegree:carDirection];
    
    double carRadians = (_carDirection - [[self mapView] rotationDegree]) / 180.f * M_PI;
    [self.carImageView setTransform:CGAffineTransformMakeRotation(carRadians)];
    
    [self updateCameraDegree];
}

- (void)setCompassDirection:(double)compassDirection
{
    _compassDirection = [AMapNaviViewUtilityX normalizeDegree:compassDirection];
    
    double compassRadians = (_compassDirection - [[self mapView] rotationDegree]) / 180.f * M_PI;
    [self.compassImageView setTransform:CGAffineTransformMakeRotation(compassRadians)];
}


- (void)updateCameraDegree {
    self.layer.transform = CATransform3DMakeRotation([[self mapView] cameraDegree] / 180.0 * M_PI, 1, 0, 0);
}

- (MAMapView *)mapView {
    return (MAMapView *)(self.superview.superview);
}

@end
