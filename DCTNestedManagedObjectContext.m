//
//  DCTCompatibleManagedObjectContext.m
//  WeatherMaps
//
//  Created by Daniel Tull on 08.01.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import "DCTNestedManagedObjectContext.h"

@interface NSManagedObjectContext (DCTCompatibleManagedObjectContext)
- (void)dctCompatibleManagedObjectContext_contextDidSave:(NSNotification *)notification;
@end

@interface DCTNestedManagedObjectContext ()
- (BOOL)dctInternal_isOS5;
@end

@implementation DCTNestedManagedObjectContext {
	DCTManagedObjectContextConcurrencyType concurrencyType;
	dispatch_queue_t queue;
	NSManagedObjectContext *parentContext;
}

- (BOOL)dctInternal_isOS5 {
	return ([[[UIDevice currentDevice] systemVersion] compare:@"5.0" options:NSNumericSearch] != NSOrderedAscending);
}

- (void)dealloc {
	dispatch_release(queue);
}

- (id)initWithConcurrencyType:(DCTManagedObjectContextConcurrencyType)ct {
	
	if ([NSManagedObjectContext instancesRespondToSelector:@selector(_cmd)]) {
		
		if (ct == DCTConfinementConcurrencyType)
			return [super initWithConcurrencyType:NSConfinementConcurrencyType];
		
		if (ct == DCTMainQueueConcurrencyType)
			return [super initWithConcurrencyType:NSMainQueueConcurrencyType];
		
		if (ct == DCTPrivateQueueConcurrencyType)
			return [super initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	}
	
	if (!(self = [super init])) return nil;
	
	concurrencyType = ct;
	
	if (ct == DCTPrivateQueueConcurrencyType)
		queue = dispatch_queue_create("uk.co.danieltull.DCTCompatibleManagedObjectContext.queue", DISPATCH_QUEUE_CONCURRENT);
	
	else
		queue = dispatch_get_main_queue();
	
	dispatch_retain(queue);
	
	return self;
}

- (void)setParentContext:(NSManagedObjectContext *)parent {
	
	if ([self dctInternal_isOS5])
		return [super setParentContext:parent];
	
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	
	[defaultCenter removeObserver:parent 
							 name:NSManagedObjectContextDidSaveNotification
						   object:self];
	
	parentContext = parent;
	
	self.persistentStoreCoordinator = parent.persistentStoreCoordinator;
	
	[defaultCenter addObserver:parentContext
					  selector:@selector(dctCompatibleManagedObjectContext_contextDidSave:) 
						  name:NSManagedObjectContextDidSaveNotification
						object:self];
}

- (NSManagedObjectContext *)parentContext {
	
	if ([self dctInternal_isOS5])
		return [super parentContext];
	
	return parentContext;
}

- (NSManagedObjectContextConcurrencyType)concurrencyType {
	
	if ([NSManagedObjectContext instancesRespondToSelector:_cmd])
		return [super concurrencyType];
	
	return concurrencyType;
}

- (void)performBlockAndWait:(void (^)())block {
	
	if ([NSManagedObjectContext instancesRespondToSelector:_cmd])
		return [super performBlockAndWait:block];
	
	if (concurrencyType == NSConfinementConcurrencyType) {
		block();
		return;
	}
	
	dispatch_sync(queue, block);
}

- (void)performBlock:(void (^)())block {
	
	if ([NSManagedObjectContext instancesRespondToSelector:_cmd])
		return [super performBlock:block];
	
	if (concurrencyType == NSConfinementConcurrencyType) {
		block();
		return;
	}
	
	dispatch_async(queue, block);
}

- (void)dctCompatibleManagedObjectContext_contextDidSave:(NSNotification *)notification {
	[self performBlock:^{
		[self mergeChangesFromContextDidSaveNotification:notification];
	}];
}

@end
@implementation NSManagedObjectContext (DCTCompatibleManagedObjectContext)

- (void)dctCompatibleManagedObjectContext_contextDidSave:(NSNotification *)notification {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self mergeChangesFromContextDidSaveNotification:notification];
	});
}


@end
