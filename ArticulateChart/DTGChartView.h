//
//  DTGChartView.h
//  ArticulateChart
//
//  Created by Green2, David on 11/22/14.
//  Copyright (c) 2014 Digital Worlds. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DTGChartView : NSView

/// Instructs the view to load a dataset from a parsed JSON dictionary.
/// Returns: false if data cannot be loaded.

-(BOOL)configureWithStockDictionary:(NSDictionary *)data;
-(void)animateToStockValues;
@end
