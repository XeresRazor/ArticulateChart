//
//  DTGChartView.m
//  ArticulateChart
//
//  Created by Green2, David on 11/22/14.
//  Copyright (c) 2014 Digital Worlds. All rights reserved.
//

#import "DTGChartView.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - DTGChartView Private Interface -
@interface DTGChartView ()
@property (nonatomic, strong) NSArray *stockClosingValues;
@property (nonatomic, strong) NSArray *stockDates;
@property (nonatomic, strong) NSDate *firstDate;
@property (nonatomic, strong) NSDate *lastDate;
@property (nonatomic) float lowestClose;
@property (nonatomic) float highestClose;
@property (nonatomic, strong) CALayer *chartLayer;
@property (nonatomic, strong) CAShapeLayer *gridLayer;
@property (nonatomic) CGFloat lowestCloseLabelValue;
@end



#pragma mark - DTGChartView Implementation -
// Static sizes for laying out the chart
static CGFloat chartElementPadding = 8.0;
static CGFloat chartSectionWidth = 80.0;
static CGFloat chartSectionHeight = 40.0;
static CGFloat chartDatePadding = 20.0;

static CGFloat labelFontSize = 12.0;

// Animation timing
static CGFloat segmentDuration = 0.5;


@implementation DTGChartView

-(void)viewWillMoveToSuperview:(NSView *)newSuperview {
	[super viewWillMoveToSuperview:newSuperview];
	self.layer.backgroundColor = [NSColor whiteColor].CGColor;
}

-(BOOL)setData:(NSDictionary *)data {
	NSArray *stockEntries = data[@"stockdata"];
	if (stockEntries == nil) {
		NSLog(@"Stock data not found.");
		return NO;
	}
	
	[self parseValuesFromArray:stockEntries];
	[self findDateAndValueRanges];
	[self setupLabels];
	
	return YES;
}

-(void)parseValuesFromArray:(NSArray *)stockEntries {
	// Parse out the dates and values into a pair of arrays
	NSMutableArray *closingValues = [NSMutableArray arrayWithCapacity:stockEntries.count];
	NSMutableArray *dates = [NSMutableArray arrayWithCapacity:stockEntries.count];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd"];
	
	for (NSDictionary *entry in stockEntries) {
		// Parse out the date
		NSString *dateString = entry[@"date"];
		NSDate *date = [dateFormatter dateFromString:dateString];
		
		// Parse out the closing value
		NSString *closeString = entry[@"close"];
		NSNumber *closingNumber = [NSNumber numberWithFloat:closeString.floatValue];
		
		[dates addObject:date];
		[closingValues addObject:closingNumber];
	}
	self.stockClosingValues = [closingValues copy];
	self.stockDates = [dates copy];
}

-(void)findDateAndValueRanges {
	// Find our highest and lowest dates and closing ranges
	self.firstDate = self.stockDates[0];
	self.lastDate = self.stockDates[0];
	self.lowestClose = ((NSNumber *)self.stockClosingValues[0]).floatValue;
	self.highestClose = ((NSNumber *)self.stockClosingValues[0]).floatValue;
	
	for (NSDate *date in self.stockDates) {
		if ([date compare:self.firstDate] == NSOrderedAscending) {
			self.firstDate = date;
		}
		if ([date compare:self.lastDate] == NSOrderedDescending) {
			self.lastDate = date;
		}
	}
	
	for (NSNumber *closingValue in self.stockClosingValues) {
		if (closingValue.floatValue < self.lowestClose) {
			self.lowestClose = closingValue.floatValue;
		}
		if (closingValue.floatValue > self.highestClose) {
			self.highestClose = closingValue.floatValue;
		}
	}
}


-(void)setupLabels {
	// Setup our labels
	float lowestClose = floorf(self.lowestClose / 5) * 5;
	float highestClose = ceilf(self.highestClose / 5) * 5;
	self.lowestCloseLabelValue = lowestClose;
	NSInteger valueLabelCount = (highestClose - lowestClose) / 5 + 1;
	
	// Setup our currency formatter
	NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
	[currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];

	NSMutableArray *valueStrings = [NSMutableArray arrayWithCapacity:valueLabelCount];
	for (float i = lowestClose; i <= highestClose; i += 5) {
		NSString *labelString = [currencyFormatter stringFromNumber:@(i)];
		[valueStrings addObject:labelString];
	}
	
	// Setup our date formatter
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	
	NSMutableArray *dateStrings = [NSMutableArray arrayWithCapacity:self.stockDates.count];
	for (NSDate *date in self.stockDates) {
		NSString *labelString = [dateFormatter stringFromDate:date];
		[dateStrings addObject:labelString];
	}
	
	[self resizeWindowToFitGridWithValueCount:valueLabelCount];
	[self layoutValueLabelsWithStrings:valueStrings];
	[self layoutDateLabelsWithStrings:dateStrings];
}

-(void)resizeWindowToFitGridWithValueCount:(NSInteger)valueLabelCount {
	CGSize viewSize = self.window.frame.size;
	viewSize.width  = chartElementPadding * 2 + (self.stockDates.count + 1) * chartSectionWidth;
	viewSize.height = chartElementPadding * 2 + (valueLabelCount) * chartSectionHeight + chartDatePadding;
	
	
	CGRect viewFrame = self.window.frame;
	viewFrame.size = viewSize;
	
	CGRect windowFrame = [self.window frameRectForContentRect:viewFrame];
	[self.window setMinSize:windowFrame.size];
	[self.window setMaxSize:windowFrame.size];
	
	[self.window setFrame:windowFrame display:YES animate:NO];
	
	
	viewFrame.origin = CGPointMake(0.0, 0.0);
	self.bounds = viewFrame;
	[self layoutGridInFrame:viewFrame];
}

-(void)layoutGridInFrame:(CGRect)viewFrame {
	// Setup a layer to draw our lines
	self.gridLayer = [[CAShapeLayer alloc] init];
	viewFrame = CGRectMake(-1.0, -1.0, viewFrame.size.width - (chartElementPadding - 1.0) * 2, viewFrame.size.height - (chartElementPadding - 1.0) * 2);
	
	self.gridLayer.bounds = viewFrame;
	self.gridLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.gridLayer.backgroundColor = [NSColor whiteColor].CGColor;
	self.gridLayer.lineWidth = 1.0;
	self.gridLayer.strokeColor = [NSColor lightGrayColor].CGColor;
	
	CGMutablePathRef path = CGPathCreateMutable();
	// Setup our grid path
	for (CGFloat x = 0; x < viewFrame.size.width; x += chartSectionWidth) {
		CGPathMoveToPoint(path, NULL, x, 0.0);
		CGPathAddLineToPoint(path, NULL, x, viewFrame.size.height - 1.5 - chartDatePadding);
	}
	for (CGFloat y = 0; y < viewFrame.size.height; y += chartSectionHeight) {
		CGPathMoveToPoint(path, NULL, 0.0, y);
		CGPathAddLineToPoint(path, NULL, viewFrame.size.width - 1.5, y);
	}
	
	[self.gridLayer setPath:path];
	CGPathRelease(path);
	[self.layer addSublayer:self.gridLayer];
}

-(void)layoutValueLabelsWithStrings:(NSArray *)labelStrings {
	NSFont *labelFont = [NSFont systemFontOfSize:labelFontSize];
	
	for (int i = 0; i < labelStrings.count; i++) {
		NSString *labelString = labelStrings[i];
		CGSize labelSize = [labelString sizeWithAttributes:@{NSFontAttributeName : labelFont}];
		
		CATextLayer *labelLayer = [[CATextLayer alloc] init];
		[labelLayer setString:labelString];
		CGRect labelRect = CGRectMake(chartElementPadding, chartSectionHeight * i, labelSize.width, labelSize.height);
		labelLayer.frame = labelRect;
		labelLayer.font = (__bridge CFTypeRef)(labelFont);
		labelLayer.fontSize = labelFontSize;
		labelLayer.foregroundColor = [NSColor blackColor].CGColor;
		[self.gridLayer addSublayer:labelLayer];
	}
}

-(void)layoutDateLabelsWithStrings:(NSArray *)labelStrings {
	NSFont *labelFont = [NSFont systemFontOfSize:labelFontSize];
	CGFloat labelBaseline = self.gridLayer.frame.size.height - chartDatePadding;// + chartElementPadding / 2.0;
	
	for (int i = 0; i < labelStrings.count; i++) {
		NSString *labelString = labelStrings[i];
		CGSize labelSize = [labelString sizeWithAttributes:@{NSFontAttributeName : labelFont}];
		labelSize.width = ceilf(labelSize.width);
		
		CATextLayer *labelLayer = [[CATextLayer alloc] init];
		[labelLayer setString:labelString];
		CGRect labelRect = CGRectMake((i + 1) * chartSectionWidth - labelSize.width / 2.0, labelBaseline, labelSize.width, labelSize.height);
		labelLayer.frame = labelRect;
		labelLayer.font = (__bridge CFTypeRef)(labelFont);
		labelLayer.fontSize = labelFontSize;
		labelLayer.foregroundColor = [NSColor blueColor].CGColor;
		[self.gridLayer addSublayer:labelLayer];
	}
}

-(void)animateToStockValues {
	// Remove all of our sublayers so we have a clean canvas
	[self.chartLayer removeFromSuperlayer];
	
	CGRect chartFrame = self.gridLayer.frame;
	chartFrame.size.height -= chartDatePadding;
	
	// The chartLayer is a container for the lines and points.
	self.chartLayer = [[CALayer alloc] init];
	self.chartLayer.frame = chartFrame;
	self.chartLayer.backgroundColor = [NSColor clearColor].CGColor;
	[self.layer addSublayer:self.chartLayer];
	
	// Setup for our animations
	CGFloat animationDuration = (self.stockClosingValues.count - 1) * segmentDuration;
	
	// Create our graph
	CAShapeLayer *lineLayer = [self linePathForStocksInFrame:chartFrame];
	[self.chartLayer addSublayer:lineLayer];
	
	// Animate the graph
	CABasicAnimation *lineAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
	lineAnimation.duration = animationDuration;
	lineAnimation.fromValue = @0.0;
	lineAnimation.toValue = @1.0;
	[lineLayer addAnimation:lineAnimation forKey:@"strokeEndAnimation"];
	
	// Add the animated dots and price labels
	for (int i = 0; i < self.stockClosingValues.count; i++) {
		CAShapeLayer *dotLayer = [self dotLayerForIndex:i];
		NSString *dotAnimKey = [NSString stringWithFormat:@"dot%d", i];
		[dotLayer addAnimation:[self dotAnimationForIndex:i] forKey:dotAnimKey];
		[self.chartLayer addSublayer:dotLayer];
		
		CATextLayer *labelLayer = [self textLayerForIndex:i];
		NSString *textAnimKey = [NSString stringWithFormat:@"text%d", i];
		[labelLayer addAnimation:[self dotAnimationForIndex:i] forKey:textAnimKey];
		[self.chartLayer addSublayer:labelLayer];
		
	}
	
}

-(CAShapeLayer *)linePathForStocksInFrame:(CGRect)chartFrame {
	CGMutablePathRef path = CGPathCreateMutable();
	for (int i = 0; i < self.stockClosingValues.count; i++) {
		CGPoint stockCoord = [self coordinateForStockEntry:i];
		if (i == 0) {
			CGPathMoveToPoint(path, NULL, stockCoord.x, stockCoord.y);
		} else {
			CGPathAddLineToPoint(path, NULL, stockCoord.x, stockCoord.y);
		}
	}
	CAShapeLayer *lineLayer = [[CAShapeLayer alloc] init];
	CGRect lineFrame = chartFrame;
	lineFrame.origin = CGPointMake(0.0, 0.0);
	lineLayer.frame = lineFrame;
	lineLayer.lineWidth = 3.0;
	lineLayer.lineCap = kCALineCapRound;
	lineLayer.strokeColor = [NSColor blueColor].CGColor;
	lineLayer.fillColor = [NSColor clearColor].CGColor;
	lineLayer.path = path;
	CGPathRelease(path);
	
	return lineLayer;
}

-(CAShapeLayer *)dotLayerForIndex:(NSInteger)index {
	CGPoint location = [self coordinateForStockEntry:index];
	CGFloat dotRadius = 3.0;
	CGRect dotRect = CGRectMake(0.0, 0.0, dotRadius * 2.0, dotRadius * 2.0);
	CGPathRef path = CGPathCreateWithEllipseInRect(dotRect, NULL);
	CAShapeLayer *dotLayer = [[CAShapeLayer alloc] init];
	dotRect.origin.x = location.x - dotRadius;
	dotRect.origin.y = location.y - dotRadius;
	dotLayer.frame = dotRect;
	dotLayer.lineWidth = 1.0;
	dotLayer.strokeColor = [NSColor blackColor].CGColor;
	dotLayer.fillColor = [NSColor blueColor].CGColor;
	dotLayer.path = path;
	
	CGPathRelease(path);
	
	return dotLayer;
}

-(CABasicAnimation *)dotAnimationForIndex:(NSInteger)index {
	CABasicAnimation *dotAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	dotAnimation.duration = 0.1;
	dotAnimation.fromValue = @0.0;
	dotAnimation.toValue = @1.0;
	dotAnimation.beginTime = CACurrentMediaTime() + (index * segmentDuration);
	dotAnimation.fillMode = kCAFillModeBackwards;
	
	return dotAnimation;
}

-(CATextLayer *)textLayerForIndex:(NSInteger)index {
	CGPoint location = [self coordinateForStockEntry:index];
	NSFont *labelFont = [NSFont systemFontOfSize:labelFontSize];
	
	NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
	[currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];

	
	NSString *labelString = [currencyFormatter stringFromNumber:self.stockClosingValues[index]];
	CGSize labelSize = [labelString sizeWithAttributes:@{NSFontAttributeName : labelFont}];
	
	CATextLayer *labelLayer = [[CATextLayer alloc] init];
	[labelLayer setString:labelString];
	
	CGRect labelRect = CGRectMake(location.x - labelSize.width / 2.0 + labelSize.height, location.y - labelSize.height / 2.0, labelSize.width, labelSize.height);
	labelLayer.frame = labelRect;
	labelLayer.font = (__bridge CFTypeRef)(labelFont);
	labelLayer.fontSize = labelFontSize;
	labelLayer.foregroundColor = [NSColor blackColor].CGColor;
	labelLayer.backgroundColor = [NSColor whiteColor].CGColor;
	labelLayer.transform = CATransform3DMakeRotation(M_PI / 2.0, 0.0, 0.0, 1.0);
	
	return labelLayer;
}

-(CABasicAnimation *)textAnimationForIndex:(NSInteger)index {
	CABasicAnimation *textAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	textAnimation.duration = 0.2;
	textAnimation.fromValue = @0.0;
	textAnimation.toValue = @1.0;
	textAnimation.beginTime = CACurrentMediaTime() + (index * segmentDuration);
	textAnimation.fillMode = kCAFillModeBackwards;
	
	return textAnimation;
}

-(CGPoint)coordinateForStockEntry:(NSInteger)index {
	// X coordinate is a simple multiple of the section width
	CGFloat x = chartSectionWidth * (index + 1) + 1.0;
	// Y coordinate needs to be scaled
	CGFloat adjustedValue = ((NSNumber *)self.stockClosingValues[index]).floatValue - self.lowestCloseLabelValue;
	int ySection = (int)(adjustedValue / 5) + 1.0;
	CGFloat percentageOfSection = (adjustedValue - (ySection * 5.0)) / 5.0;
	
	return CGPointMake(x, percentageOfSection * chartSectionHeight + chartSectionHeight * ySection);
}

@end
