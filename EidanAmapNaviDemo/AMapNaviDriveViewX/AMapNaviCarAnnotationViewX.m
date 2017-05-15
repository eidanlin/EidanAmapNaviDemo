//
//  AMapNaviCarAnnotationViewX.m
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/1/13.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import "AMapNaviCarAnnotationViewX.h"
#import "AMapNaviViewUtilityX.h"

#define kCarAnnotationViewCarImage      @"default_navi_new_location"
#define kCarAnnotationViewCompassImage  @"default_navi_carlocation_compass"

@interface AMapNaviCarAnnotationViewX ()

@property (nonatomic, strong) UIImageView *carImageView;
@property (nonatomic, strong) UIImageView *compassImageView;

@end

@implementation AMapNaviCarAnnotationViewX


- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    
    BOOL inside = [super pointInside:point withEvent:event];
    
    if(!inside) {
        if(self.carImageView) {
            inside = [self.carImageView pointInside:[self convertPoint:point toView:self.carImageView] withEvent:event];
        }
        else if (self.compassImageView) {
            inside = [self.compassImageView pointInside:[self convertPoint:point toView:self.compassImageView] withEvent:event];
        }
    }
    
    return inside;
}



- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        
        [self buildCarAnnotationView];
    }
    
    return self;
}

- (void)buildCarAnnotationView {
    
    _showCompass = YES;
    _carDirection = 0;
    _compassDirection = 0;
    
    [self addSubview:self.compassImageView];
    [self addSubview:self.carImageView];
}

- (UIImageView *)carImageView {
    if (_carImageView == nil) {
        
        UIImage *carImage = [UIImage imageNamed:kCarAnnotationViewCarImage];
        
        _carImageView = [[UIImageView alloc] initWithImage:carImage];
        
        [_carImageView setFrame:CGRectMake(0, 0, 35, 35)];
        [_carImageView setCenter:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))];
    }
    return _carImageView;
}

- (UIImageView *)compassImageView {
    
    if (_compassImageView == nil) {
        UIImage *compassImage = [UIImage imageNamed:kCarAnnotationViewCompassImage];
        
        _compassImageView = [[UIImageView alloc] initWithImage:compassImage];
        [_compassImageView setCenter:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))];
        
    }
    return _compassImageView;
}

#pragma mark - Interface

- (void)setShowCompass:(BOOL)showCompass {
    _showCompass = showCompass;
    
    self.compassImageView.hidden = !_showCompass;
}

- (void)setCarDirection:(double)carDirection {
    
    _carDirection = [AMapNaviViewUtilityX normalizeDegree:carDirection];
    
    double carRadians = (_carDirection - [[self mapView] rotationDegree]) / 180.f * M_PI;
    [self.carImageView setTransform:CGAffineTransformMakeRotation(carRadians)];
    
    [self updateCameraDegree];
}

- (void)setCompassDirection:(double)compassDirection {
    _compassDirection = [AMapNaviViewUtilityX normalizeDegree:compassDirection];
    
    double compassRadians = (_compassDirection - [[self mapView] rotationDegree]) / 180.f * M_PI;
    [self.compassImageView setTransform:CGAffineTransformMakeRotation(compassRadians)];
}


- (void)updateCameraDegree {
    self.layer.transform = CATransform3DMakeRotation([[self mapView] cameraDegree] / 180.0 * M_PI, 1, 0, 0);
}

- (void)setCarImage:(nullable UIImage *)carImage {
    if (carImage) {
        [self.carImageView setImage:carImage];
    } else {
        [self.carImageView setImage:[UIImage imageNamed:kCarAnnotationViewCarImage]];
    }
}

- (void)setCompassImage:(nullable UIImage *)compassImage {
    if (compassImage) {
        [self.compassImageView setImage:compassImage];
    } else {
        [self.compassImageView setImage:[UIImage imageNamed:kCarAnnotationViewCompassImage]];
    }
}

- (MAMapView *)mapView {
    return (MAMapView *)(self.superview.superview);
}

@end
