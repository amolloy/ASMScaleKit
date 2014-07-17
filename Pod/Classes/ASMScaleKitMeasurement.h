//
//  ASMScaleKitMeasurement.h
//  Pods
//
//  Created by Andrew Molloy on 7/17/14.
//
//

#import <Foundation/Foundation.h>

@interface ASMScaleKitMeasurement : NSObject

@property (nonatomic, strong, readonly) NSDate* date;
@property (nonatomic, strong, readonly) NSDecimalNumber* weightInKg;
@property (nonatomic, strong, readonly) NSString* uniqueId;

- (instancetype)initWithDate:(NSDate*)date
				  weightInKg:(NSDecimalNumber*)weightInKg
					uniqueId:(NSString*)uniqueId;

@end
