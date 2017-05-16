//
//  AMapNaviTrafficBarViewX.m
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/2/9.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import "AMapNaviTrafficBarViewX.h"

#define AMapNaviTrafficBarViewRGBA(R, G, B)   [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:0.9]

@interface AMapNaviTrafficBarViewX ()

@property (nonatomic, strong) UIImageView *carImageView;

@property (nonatomic, strong) CAShapeLayer *outterBorderLayer;

@property (nonatomic, strong) CALayer *lightBlueLayer;

@property (nonatomic, strong) CALayer *greyLayer;

@property (nonatomic, strong) CALayer *trafficStatusesContainerLayer;

@property (nonatomic, strong) NSArray <CAShapeLayer *> *trafficStatusLayerArray;

@property (nonatomic, weak) NSArray <AMapNaviTrafficStatus *> *trafficStatus;

@property (nonatomic, assign) float currentHeight;

@property (nonatomic, assign) float posPercent;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIColor *> *colors;

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
    
    //default
    self.currentHeight = self.bounds.size.height;
    self.posPercent = 0;
    _showCar = YES;
    
    //0-未知状态-blue; 1-通畅-green; 2-缓行-yellow; 3-阻塞-red; 4-严重阻塞-brown;
    self.colors = @{@(AMapNaviRouteStatusUnknow): [self defaultColorForStatus:AMapNaviRouteStatusUnknow],
                    @(AMapNaviRouteStatusSmooth): [self defaultColorForStatus:AMapNaviRouteStatusSmooth],
                    @(AMapNaviRouteStatusSlow): [self defaultColorForStatus:AMapNaviRouteStatusSlow],
                    @(AMapNaviRouteStatusJam): [self defaultColorForStatus:AMapNaviRouteStatusJam],
                    @(AMapNaviRouteStatusSeriousJam): [self defaultColorForStatus:AMapNaviRouteStatusSeriousJam]}.mutableCopy;
    
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
    
    [self drawOutterBorder];
    
    //位置减去1，是因为车的图没切好，离了1个像素的空白，如果顶着边切，就不用减去1
    self.carImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.bounds.size.width - 28) / 2, self.bounds.size.height - 1 , 28, 28)];
    self.carImageView.image = [UIImage imageNamed:@"default_navi_trafficbar_cursor.png"];
    self.carImageView.layer.zPosition = 2;  //数字越大，离观众越近，默认都是0
    [self addSubview:self.carImageView];
    
    //未知
    CAShapeLayer *trafficStatusUnknowLayer = [self createShapeLayr:self.bounds.size.width andStrokeColor:[self getColorWithStatus:AMapNaviRouteStatusUnknow]];
    [self.trafficStatusesContainerLayer addSublayer:trafficStatusUnknowLayer];
    
    //顺畅
    CAShapeLayer *trafficStatusSmoothLayer = [self createShapeLayr:self.bounds.size.width andStrokeColor:[self getColorWithStatus:AMapNaviRouteStatusSmooth]];
    [self.trafficStatusesContainerLayer addSublayer:trafficStatusSmoothLayer];
    
    //缓慢
    CAShapeLayer *trafficStatusSlowLayer = [self createShapeLayr:self.bounds.size.width andStrokeColor:[self getColorWithStatus:AMapNaviRouteStatusSlow]];
    [self.trafficStatusesContainerLayer addSublayer:trafficStatusSlowLayer];
    
    //堵塞
    CAShapeLayer *trafficStatusJamLayer = [self createShapeLayr:self.bounds.size.width andStrokeColor:[self getColorWithStatus:AMapNaviRouteStatusJam]];
    [self.trafficStatusesContainerLayer addSublayer:trafficStatusJamLayer];
    
    //严重堵塞
    CAShapeLayer *trafficStatusSeriousJamLayer = [self createShapeLayr:self.bounds.size.width andStrokeColor:[self getColorWithStatus:AMapNaviRouteStatusSeriousJam]];
    [self.trafficStatusesContainerLayer addSublayer:trafficStatusSeriousJamLayer];
    
    self.trafficStatusLayerArray = @[trafficStatusUnknowLayer, trafficStatusSmoothLayer, trafficStatusSlowLayer, trafficStatusJamLayer, trafficStatusSeriousJamLayer];
    
}

//外边框层
- (void)drawOutterBorder {
    
    [self.outterBorderLayer removeFromSuperlayer];
    
    //边界要外扩，边界线的内边贴着self这个view的实际区域，外边直接超出了view，这样整个view的高度才是一个有效的总高度，以这个高度来计算百分比，比较方便，不用额外的减边界的宽度
    float outterBorderWidth = 4;
    float outterBorderOffset = outterBorderWidth / 2;
    UIBezierPath *outterPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(-outterBorderOffset, -outterBorderOffset, self.bounds.size.width + 2 * outterBorderOffset, self.bounds.size.height + 2 * outterBorderOffset) cornerRadius:8];
    
    self.outterBorderLayer = [self createShapeLayr:outterBorderWidth andStrokeColor:[UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1]];
    self.outterBorderLayer.path = outterPath.CGPath;
    self.outterBorderLayer.zPosition = 1;
    [self.layer addSublayer:self.outterBorderLayer];
}

- (void)layoutSubviews {
    
    if (self.currentHeight != self.bounds.size.height) {  //做一层判断，防止总是执行，提高效率，只在总的高度变了才执行，用于屏幕旋转适配
        self.currentHeight = self.bounds.size.height;
        self.lightBlueLayer.frame = self.bounds;
        [self drawOutterBorder];  //重画
        [self updateTrafficBarWithTrafficStatuses:self.trafficStatus];  //立刻更新色块的位置
        [self updateTrafficBarWithCarPositionPercent: self.posPercent];  //立刻更新车的位置
    }
    
}

#pragma -mark interface

- (void)setShowCar:(BOOL)showCar {
    
    _showCar = showCar;
    
    self.carImageView.hidden = !showCar;
}

- (NSDictionary<NSNumber *,UIColor *> *)statusColors {
    return [self.colors copy];
}

- (void)setStatusColors:(NSDictionary *)statusColors {
    
    for (NSNumber *status in self.colors.allKeys) {
        
        UIColor *newColor = [[statusColors objectForKey:status] copy];
        
        if (newColor != nil) {
            [self.colors setObject:newColor forKey:status];
        } else {
            [self.colors setObject:[self defaultColorForStatus:status.integerValue] forKey:status];
        }
        
        //改变颜色
        self.trafficStatusLayerArray[status.intValue].strokeColor = [self getColorWithStatus:status.intValue].CGColor;
        
    }
}


//更新车的位置，然后灰色跟着车，然后路况层的底部是灰色层的顶部
- (void)updateTrafficBarWithCarPositionPercent:(double)posPercent {
    
    self.posPercent = MAX(0, MIN(1, posPercent));
    
    //位置再减去1，是因为车的图没切好，离了1个像素的空白，如果顶着边切，就不用减去1
    self.carImageView.frame = CGRectMake(self.carImageView.frame.origin.x, self.bounds.size.height * (1 - self.posPercent) - 1, self.carImageView.frame.size.width, self.carImageView.frame.size.height);
    
    //+1也是图片没有切好的后遗症，为了不让灰色跑在车前面，灰色要往下微调
    self.greyLayer.frame = CGRectMake(0, self.carImageView.frame.origin.y + 1, self.bounds.size.width, self.bounds.size.height - self.carImageView.frame.origin.y - 1);
    
    //高度逐渐变小
    self.trafficStatusesContainerLayer.frame = CGRectMake(0, 0, self.bounds.size.width, self.greyLayer.frame.origin.y);
    
    //一开始不添加，等开始走动了，才添加，防止有闪烁的动画
    if (self.greyLayer.superlayer == nil) {
        [self.layer addSublayer:self.greyLayer];
    }
    
}

- (void)updateTrafficBarWithTrafficStatuses:(NSArray <AMapNaviTrafficStatus *> *)trafficStatuses {
    
    if (trafficStatuses.count == 0) {
        return;
    }
    
    self.trafficStatus = trafficStatuses;
    
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

- (UIColor *)getColorWithStatus:(AMapNaviRouteStatus)status {
    return [self.colors objectForKey:@(status)];
}

- (UIColor *)defaultColorForStatus:(AMapNaviRouteStatus)status {
    
    switch (status) {
        case AMapNaviRouteStatusSmooth:     //1-通畅-green
            return AMapNaviTrafficBarViewRGBA(27, 184, 46);
        case AMapNaviRouteStatusSlow:       //2-缓行-yellow
            return AMapNaviTrafficBarViewRGBA(253, 185, 44);
        case AMapNaviRouteStatusJam:        //3-阻塞-red
            return AMapNaviTrafficBarViewRGBA(240, 34, 43);
        case AMapNaviRouteStatusSeriousJam: //4-严重阻塞-brown
            return AMapNaviTrafficBarViewRGBA(166, 14, 22);
        default:                            //0-未知状态-blue
            return AMapNaviTrafficBarViewRGBA(142, 206, 253);
    }
}

@end
