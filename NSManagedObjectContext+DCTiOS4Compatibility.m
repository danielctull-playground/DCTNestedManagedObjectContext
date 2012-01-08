//
//  NSManagedObjectContext+DCTiOS4Compatibility.m
//  WeatherMaps
//
//  Created by Daniel Tull on 07.01.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import "NSManagedObjectContext+DCTiOS4Compatibility.h"
#import <objc/runtime.h>

@interface NSManagedObjectContext (DCTiOS4CompatibilityInternal)

+ (void)dctInternal_implmentOriginalSelector:(SEL)originalSelector withNewSelector:(SEL)newSelector;

- (void)dctiOS4CompatibilityInternal_contextDidSaveNotification:(NSNotification *)notification;

- (dispatch_queue_t)dctInternal_dispatchQueue;
- (void)dctInternal_setDispatchQueue:(dispatch_queue_t)queue;

- (void)dct_performBlock:(void (^)())block;
- (void)dct_performBlockAndWait:(void (^)())block;
- (NSManagedObjectContext *)dct_parentContext;
- (void)dct_setParentContext:(NSManagedObjectContext *)parent;
- (id)dct_initWithConcurrencyType:(NSManagedObjectContextConcurrencyType)ct;
- (NSManagedObjectContextConcurrencyType)dct_concurrencyType;

@end

@interface DCTNestedContextParentChildContainer : NSObject
@property (nonatomic, weak) NSManagedObjectContext *parentContext;
@property (nonatomic, weak) NSManagedObjectContext *childContext;
- (id)initWithParentContext:(NSManagedObjectContext *)parentContext childContext:(NSManagedObjectContext *)childContext;
@end

@implementation DCTNestedContextParentChildContainer
@synthesize parentContext;
@synthesize childContext;

- (id)initWithParentContext:(NSManagedObjectContext *)parent childContext:(NSManagedObjectContext *)child {
	if (!(self = [super init])) return nil;
	parentContext = parent;
	childContext = child;
	
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	
	[defaultCenter addObserver:child 
					  selector:@selector(dctiOS4CompatibilityInternal_contextDidSaveNotification:) 
						  name:NSManagedObjectContextDidSaveNotification
						object:parent];
	
	[defaultCenter addObserver:parent
					  selector:@selector(dctiOS4CompatibilityInternal_contextDidSaveNotification:) 
						  name:NSManagedObjectContextDidSaveNotification
						object:child];
	
	return self;
}

- (void)dealloc {
	
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	
	[defaultCenter removeObserver:childContext
							 name:NSManagedObjectContextDidSaveNotification
						   object:parentContext];
	
	[defaultCenter removeObserver:parentContext
							 name:NSManagedObjectContextDidSaveNotification
						   object:childContext];
}

@end


@interface DCTiOS4CompatibilityInternalQueueContainer : NSObject
@property (nonatomic, assign) dispatch_queue_t queue;
@end

@implementation DCTiOS4CompatibilityInternalQueueContainer
@synthesize queue;
- (void)setQueue:(dispatch_queue_t)q {
	dispatch_release(queue);
	queue = q;
	dispatch_retain(queue);
}
- (void)dealloc {
	dispatch_release(queue);
}
@end





@implementation NSManagedObjectContext (DCTiOS4Compatibility)

+ (void)dctInternal_implmentOriginalSelector:(SEL)originalSelector withNewSelector:(SEL)newSelector {
	
	if (![self instancesRespondToSelector:originalSelector]) {
		Method newMethod = class_getInstanceMethod(self, newSelector);
		class_addMethod(self, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
	}	
}

+ (void)load {
	[self dctInternal_implmentOriginalSelector:@selector(parentContext) withNewSelector:@selector(dct_parentContext)];
	[self dctInternal_implmentOriginalSelector:@selector(setParentContext:) withNewSelector:@selector(dct_setParentContext:)];
	[self dctInternal_implmentOriginalSelector:@selector(performBlockAndWait:) withNewSelector:@selector(dct_performBlockAndWait:)];
	[self dctInternal_implmentOriginalSelector:@selector(performBlock:) withNewSelector:@selector(dct_performBlock:)];
	[self dctInternal_implmentOriginalSelector:@selector(initWithConcurrencyType:) withNewSelector:@selector(dct_initWithConcurrencyType:)];
	[self dctInternal_implmentOriginalSelector:@selector(concurrencyType) withNewSelector:@selector(dct_concurrencyType)];
	
	if (![self instancesRespondToSelector:@selector(parentContext)]) {
		enum {
			NSConfinementConcurrencyType        = 0x00,
			NSPrivateQueueConcurrencyType       = 0x01,
			NSMainQueueConcurrencyType          = 0x02
		};
		typedef NSUInteger NSManagedObjectContextConcurrencyType;
	}
}

- (NSManagedObjectContextConcurrencyType)dct_concurrencyType {
	return [objc_getAssociatedObject(self, @selector(dct_concurrencyType)) unsignedIntValue];
}

- (dispatch_queue_t)dctInternal_dispatchQueue {
	DCTiOS4CompatibilityInternalQueueContainer *c = objc_getAssociatedObject(self, @selector(dctInternal_dispatchQueue));
	return c.queue;
}
- (void)dctInternal_setDispatchQueue:(dispatch_queue_t)queue {
	DCTiOS4CompatibilityInternalQueueContainer *c = [DCTiOS4CompatibilityInternalQueueContainer new];
	c.queue = queue;
	objc_setAssociatedObject(self, @selector(dctInternal_dispatchQueue), c, OBJC_ASSOCIATION_RETAIN);
}

- (void)dct_performBlock:(void (^)())block {
	
	if ([self dct_concurrencyType] == NSConfinementConcurrencyType) {
		block();
		return;
	}
	
	dispatch_async([self dctInternal_dispatchQueue], block);
}

- (void)dct_performBlockAndWait:(void (^)())block {
	
	if ([self dct_concurrencyType] == NSConfinementConcurrencyType) {
		block();
		return;
	}
	
	dispatch_sync([self dctInternal_dispatchQueue], block);
}

- (NSManagedObjectContext *)dct_parentContext {
	DCTNestedContextParentChildContainer *container = objc_getAssociatedObject(self, @selector(dct_parentContext));
	return container.parentContext;
}

- (void)dct_setParentContext:(NSManagedObjectContext *)parent {
	
	DCTNestedContextParentChildContainer *container = [[DCTNestedContextParentChildContainer alloc] initWithParentContext:parent
																											 childContext:self];
	objc_setAssociatedObject(self, @selector(dct_parentContext), container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	self.persistentStoreCoordinator = parent.persistentStoreCoordinator;
}

- (id)init_dctWithConcurrencyType:(NSManagedObjectContextConcurrencyType)ct {
	
	if (!(self = [self init])) return nil;
	
	objc_setAssociatedObject(self, @selector(dct_concurrencyType), [NSNumber numberWithUnsignedInt:ct], OBJC_ASSOCIATION_RETAIN);
	
	if (ct == NSPrivateQueueConcurrencyType) {
		[self dctInternal_setDispatchQueue:dispatch_queue_create("uk.co.danieltull.DCTNSManagedObjectContextiOS4Compatibility", DISPATCH_QUEUE_CONCURRENT)];
	} else if (ct == NSMainQueueConcurrencyType) {
		[self dctInternal_setDispatchQueue:dispatch_get_main_queue()];
	}
	
	return self;	
}

- (void)dctiOS4CompatibilityInternal_contextDidSaveNotification:(NSNotification *)notification {
	[self performBlock:^{
		[self mergeChangesFromContextDidSaveNotification:notification];
	}];
}


@end
