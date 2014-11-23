//
//  DTGChartViewController.m
//  ArticulateChart
//
//  Created by Green2, David on 11/22/14.
//  Copyright (c) 2014 Digital Worlds. All rights reserved.
//

#import "DTGChartViewController.h"

@implementation DTGChartViewController

- (void)viewDidLoad {
	[super viewDidLoad];
}

-(void)viewWillAppear {
	[super viewWillAppear];
	
	NSData *stockData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"stockprices" ofType:@"json"]];
	NSError *error = nil;
	id stockObject = [NSJSONSerialization JSONObjectWithData:stockData options:0 error:&error];
	if (stockObject == nil) {
		NSLog(@"Unable to load stock data from App Resources. Error: %@", error.localizedDescription);
		[[NSException exceptionWithName:@"Missing Resource" reason:@"Unable to load price information from stockprices.json" userInfo:@{@"error": error}] raise];
	}
	
	// Verify that data correctly loaded as a dictionary.
	if (![stockObject isKindOfClass:[NSDictionary class]]) {
		NSLog(@"Stock data is in an invalid format.");
		[[NSException exceptionWithName:@"Invalid Resource" reason:@"Stock price data is invalidly formatted." userInfo:nil] raise];
	}
	
	NSDictionary *stocks = (NSDictionary *)stockObject;
	if ([self.chartView setData:stocks]) {
		[self.chartView animateToStockValues];
	} else {
		NSLog(@"Chart view was unable to load stock data.");
		[[NSException exceptionWithName:@"Unable to load Stock data" reason:@"Chart view was unable to load stock data." userInfo:nil] raise];
	}
}

- (void)setRepresentedObject:(id)representedObject {
	[super setRepresentedObject:representedObject];

	// Update the view, if already loaded.
}

-(void)mouseUp:(NSEvent *)theEvent {
	[self.chartView animateToStockValues];
}

@end
