//
//  DCTCompatibleManagedObjectContext.h
//  WeatherMaps
//
//  Created by Daniel Tull on 08.01.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import <CoreData/CoreData.h>

enum {
	DCTConfinementConcurrencyType        = 0x00,
	DCTPrivateQueueConcurrencyType       = 0x01,
	DCTMainQueueConcurrencyType          = 0x02
};
typedef NSUInteger DCTManagedObjectContextConcurrencyType;

@interface DCTNestedManagedObjectContext : NSManagedObjectContext
- (id)initWithConcurrencyType:(DCTManagedObjectContextConcurrencyType)ct;
@end
