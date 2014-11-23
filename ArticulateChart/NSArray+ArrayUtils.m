//
//  NSArray+ArrayUtils.m
//  ArticulateChart
//
//  Created by Green2, David on 11/22/14.
//  Copyright (c) 2014 Digital Worlds. All rights reserved.
//

#import "NSArray+ArrayUtils.h"

@implementation NSArray (ArrayUtils)

- (id)objectAtIndex:(NSUInteger)index ifKindOf:(Class)kind {
	return [self objectAtIndex:index ifKindOf:kind defaultValue:nil];
}

- (id)objectAtIndex:(NSUInteger)index ifKindOf:(Class)kind defaultValue:(id)defaultValue {
	id obj = self[index];
	return [obj isKindOfClass:kind] ? obj : defaultValue;
}

#pragma mark - Type specific helpers
- (NSNumber*)numberAtIndex:(NSUInteger)index {
	return [self objectAtIndex:index ifKindOf:[NSNumber class]];
}
@end
