//
//  AMapNaviTrafficBarViewX.m
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/2/9.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import "AMapNaviTrafficBarViewX.h"

#define AMapNaviTrafficBarViewRGBA(R, G, B)   [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:0.8]

@interface AMapNaviTrafficBarViewX ()

@property (nonatomic, strong) UIImageView *carImageView;

@property (nonatomic, strong) CALayer *lightBlueLayer;

@property (nonatomic, strong) CALayer *greyLayer;

@property (nonatomic, strong) CALayer *trafficStatusesContainerLayer;

@property (nonatomic, strong) NSArray <CAShapeLayer *> *trafficStatusLayerArray;

@end

@implementation AMapNaviTrafficBarViewX

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
    
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = NO;
    
    //初始化时候那个蓝色层，随后一闪而过
    self.lightBlueLayer = [CALayer layer];
    self.lightBlueLayer.frame = self.bounds;
    self.lightBlueLayer.backgroundColor = AMapNaviTrafficBarViewRGBA(0, 255, 255).CGColor;
    self.lightBlueLayer.masksToBounds = YES;
    [self.layer addSublayer:self.lightBlueLayer];
    
    //已经走过的灰色层
    self.greyLayer = [CALayer layer];
    self.greyLayer.backgroundColor = AMapNaviTrafficBarViewRGBA(154, 154, 154).CGColor;
    
    //路况信息层的容器
    self.trafficStatusesContainerLayer = [CALayer layer];
    self.trafficStatusesContainerLayer.frame = self.bounds;
    self.trafficStatusesContainerLayer.masksToBounds = YES;
    [self.layer addSublayer:self.trafficStatusesContainerLayer];
    
    //边界要外扩，边界线的内边贴着self这个view的实际区域，外边直接超出了view，这样整个view的高度才是一个有效的总高度，以这个高度来计算百分比，比较方便，不用额外的减边界的宽度
    float outterBorderWidth = 3;
    float outterBorderOffset = outterBorderWidth / 2;
    UIBezierPath *outterPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(-outterBorderOffset, -outterBorderOffset, self.bounds.size.width + 2 * outterBorderOffset, self.bounds.size.height + 2 * outterBorderOffset) cornerRadius:4];
    
    CAShapeLayer *outterBorderLayer = [self createShapeLayr:outterBorderWidth andStrokeColor:AMapNaviTrafficBarViewRGBA(255, 255, 255)];
    outterBorderLayer.path = outterPath.CGPath;
    outterBorderLayer.zPosition = 1;
    [self.layer addSublayer:outterBorderLayer];
    
    //位置减去1，是因为车的图没切好，离了1个像素的空白，如果顶着边切，就不用减去1
    self.carImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.bounds.size.width - 28) / 2, self.bounds.size.height - 1 , 28, 28)];
    self.carImageView.image = [UIImage imageNamed:@"default_navi_trafficbar_cursor.png"];
    self.carImageView.layer.zPosition = 2;  //数字越大，离观众越近，默认都是0
    [self addSubview:self.carImageView];
    
    //未知
    CAShapeLayer *trafficStatusUnknowLayer = [self createShapeLayr:self.bounds.size.width andStrokeColor:AMapNaviTrafficBarViewRGBA(26, 166, 239)];
    [self.trafficStatusesContainerLayer addSublayer:trafficStatusUnknowLayer];
    
    //顺畅
    CAShapeLayer *trafficStatusSmoothLayer = [self createShapeLayr:self.bounds.size.width andStrokeColor:AMapNaviTrafficBarViewRGBA(65, 223, 16)];
    [self.trafficStatusesContainerLayer addSublayer:trafficStatusSmoothLayer];
    
    //缓慢
    CAShapeLayer *trafficStatusSlowLayer = [self createShapeLayr:self.bounds.size.width andStrokeColor:AMapNaviTrafficBarViewRGBA(255, 255, 0)];
    [self.trafficStatusesContainerLayer addSublayer:trafficStatusSlowLayer];
    
    //堵塞
    CAShapeLayer *trafficStatusJamLayer = [self createShapeLayr:self.bounds.size.width andStrokeColor:AMapNaviTrafficBarViewRGBA(255, 0, 0)];
    [self.trafficStatusesContainerLayer addSublayer:trafficStatusJamLayer];
    
    //严重堵塞
    CAShapeLayer *trafficStatusSeriousJamLayer = [self createShapeLayr:self.bounds.size.width andStrokeColor:AMapNaviTrafficBarViewRGBA(160, 8, 8)];
    [self.trafficStatusesContainerLayer addSublayer:trafficStatusSeriousJamLayer];
    
    self.trafficStatusLayerArray = @[trafficStatusUnknowLayer, trafficStatusSmoothLayer, trafficStatusSlowLayer, trafficStatusJamLayer, trafficStatusSeriousJamLayer];
    
}

#pragma -mark interface

//更新车的位置，然后灰色跟着车，然后路况层的底部是灰色层的顶部
- (void)updateCarPositionWithRouteRemainPercent:(double)remainPercent {
    
    double lastRemainPercent = MAX(0, MIN(1, remainPercent));
    
    //位置再减去1，是因为车的图没切好，离了1个像素的空白，如果顶着边切，就不用减去1
    self.carImageView.frame = CGRectMake(self.carImageView.frame.origin.x, self.bounds.size.height * lastRemainPercent - 1, self.carImageView.frame.size.width, self.carImageView.frame.size.height);
    
    //+2也是图片没有切好的后遗症，为了不让灰色跑在车前面，灰色要往下微调
    self.greyLayer.frame = CGRectMake(0, self.carImageView.frame.origin.y + 2, self.bounds.size.width, self.bounds.size.height - self.carImageView.frame.origin.y - 2);
    
    //高度逐渐变小
    self.trafficStatusesContainerLayer.frame = CGRectMake(0, 0, self.bounds.size.width, self.greyLayer.frame.origin.y);
    
    //一开始不添加，等开始走动了，才添加，防止有闪烁的动画
    if (self.greyLayer.superlayer == nil) {
        [self.layer addSublayer:self.greyLayer];
    }
    
}

- (void)updateBarWithTrafficStatuses:(NSArray <AMapNaviTrafficStatus *> *)trafficStatuses {
    
    if (self.lightBlueLayer.superlayer) {
        [self.lightBlueLayer removeFromSuperlayer];
    }
    
    //代表的是线的中心点的X坐标，线的宽度为self.bounds.size.width，刚刚好填满整个bar的横截面
    float pointX = self.bounds.size.width / 2;
    
    UIBezierPath *pathUnknow = [UIBezierPath bezierPath];
    UIBezierPath *pathSmooth = [UIBezierPath bezierPath];
    UIBezierPath *pathSlow = [UIBezierPath bezierPath];
    UIBezierPath *pathJam = [UIBezierPath bezierPath];
    UIBezierPath *pathSeriousJam = [UIBezierPath bezierPath];
    NSArray <UIBezierPath *> *pathArray = @[pathUnknow,pathSmooth,pathSlow,pathJam,pathSeriousJam];
    
    __block NSInteger totalLength = 0;
    [trafficStatuses enumerateObjectsUsingBlock:^(AMapNaviTrafficStatus *aTraffic, NSUInteger idx, BOOL *stop) {
        totalLength += aTraffic.length;
    }];
    
    
    //需要倒序，因为最后一个路况在最上面
    __block NSInteger hasLength = 0;
    [trafficStatuses enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AMapNaviTrafficStatus * _Nonnull aTraffic, NSUInteger idx, BOOL * _Nonnull stop) {
        
        UIBezierPath *eachPath = [UIBezierPath bezierPath]; //每一段都有自己的起点和终点，直接移动到这一段的起点，然后画到这一段的终点，然后把这一段给对应的大线，也就是所有的大线都是一节一节的
        
        [eachPath moveToPoint:CGPointMake(pointX, (double)hasLength / totalLength * self.bounds.size.height)];  //移动起点
        
        hasLength += aTraffic.length;
        
        [eachPath addLineToPoint:CGPointMake(pointX, (double)hasLength / totalLength * self.bounds.size.height)];  //画到终点
        
        [pathArray[aTraffic.status] appendPath:eachPath];  //一一对应，把这一段接到对应的线段上
    }];
    
    //一一对应，每一次重新给path，layer就会重新绘制
    for (int i = 0; i < self.trafficStatusLayerArray.count; i ++) {
        self.trafficStatusLayerArray[i].path = pathArray[i].CGPath;
    }
    
}

#pragma -mark private

- (CAShapeLayer *)createShapeLayr:(float)lineWidth andStrokeColor:(UIColor *)strokeColor {
    CAShapeLayer* shapeLayer = [CAShapeLayer layer];
    shapeLayer.lineWidth = lineWidth;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.strokeColor = strokeColor.CGColor;
    return shapeLayer;
}

@end
