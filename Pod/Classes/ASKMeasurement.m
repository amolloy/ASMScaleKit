//
//  ASMScaleKitMeasurement.m
//  Pods
//
//  Created by Andrew Molloy on 7/17/14.
//
//

#import "ASKMeasurement.h"

@interface ASKMeasurement ()
@property (nonatomic, strong, readwrite) NSDate* date;
@property (nonatomic, strong, readwrite) NSDecimalNumber* weightInKg;
@property (nonatomic, strong, readwrite) NSString* uniqueId;
@end

@implementation ASKMeasurement

- (instancetype)initWithDate:(NSDate*)date
				  weightInKg:(NSDecimalNumber*)weightInKg
					uniqueId:(NSString*)uniqueId
{
	self = [super init];
	if (self)
	{
		self.date = date;
		self.weightInKg = weightInKg;
		self.uniqueId = uniqueId;
	}
	return self;
}
@end
