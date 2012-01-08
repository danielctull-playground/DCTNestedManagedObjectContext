//
//  NSManagedObjectContext+DCTiOS4Compatibility.h
//  WeatherMaps
//
//  Created by Daniel Tull on 07.01.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (DCTiOS4Compatibility)

/* Adds the following methods to iOS 4 NSManagedObjectContext
- (void)performBlock:(void (^)())block;
- (void)performBlockAndWait:(void (^)())block;
- (NSManagedObjectContext *)parentContext;
- (void)setParentContext:(NSManagedObjectContext *)parent;
- (id)initWithConcurrencyType:(NSManagedObjectContextConcurrencyType)ct;
- (NSManagedObjectContextConcurrencyType)concurrencyType;
*/

@end
