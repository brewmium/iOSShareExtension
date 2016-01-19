//
//  ShareManager.m
//  HelloShare
//
//  Created by Eric Hayes on 1/19/16.
//  Copyright © 2016 Eric Hayes. All rights reserved.
//

#import "ShareManager.h"
#import "MMWormhole.h"
#import "ShareObject.h"

@interface ShareManager ()

@property (nonatomic, strong) MMWormhole *wormhole;

@end

@implementation ShareManager

+ (ShareManager *)sharedInstance;
{
	static dispatch_once_t once;
	static ShareManager * sharedInstance;
	dispatch_once(&once, ^{
		sharedInstance = [[self alloc] init];
		[sharedInstance setup];
	});
	
	return sharedInstance;
}

- (void)setup
{
	self.wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:kAppGroupId optionalDirectory:kWormHoldDirectory];
	[self.wormhole listenForMessageWithIdentifier:kShareMessage listener:^(id keyOrFilePath) {
		// process the one we love
		[self processOneShare:keyOrFilePath];
		
		// or we could just loop them all, to make sure we dont have any stale shares (speculating here)
		//[self processShares];
	}];
}

- (void)registerUXDelegate:(id<ShareUXDelegate>)theDelegate;
{
	self.uxDelegate = theDelegate;
}


#pragma mark - 


- (void)processShareForUX:(NSMutableDictionary *)shareDict;
{
	if ( shareDict == nil ) return;
	
	ShareObject *output = [ShareObject new];
	output.postText = [shareDict objectForKey:kShareText];
	
	for ( NSInteger counter = 0 ; counter < shareDict.count ; counter++ ) {
		NSString *theKey = [NSString stringWithFormat:@"%@%zd", kShareItemBase, counter];
		id theObject = [shareDict objectForKey:theKey];
		if ( theObject ) {
			if ( [theObject isKindOfClass:[UIImage class]] ) {
				if ( output.images ==  nil ) {
					output.images = [NSMutableArray new];
				}
				[output.images addObject:theObject];
				
			} else if ( [theObject isKindOfClass:[NSURL class]] ) {
				if ( output.urls ==  nil ) {
					output.urls = [NSMutableArray new];
				}
				[output.urls addObject:theObject];
				
			} else {
				NSLog(@"unknown type of share object: %@", theObject);
			}
		}
	}
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *basePath = paths.firstObject;
	NSString *shareDir = [basePath stringByAppendingPathComponent:@"share"];
	
	// make sure the share dir exists
	[[NSFileManager defaultManager] createDirectoryAtPath:shareDir withIntermediateDirectories:YES attributes:nil error:nil];
	
	// ok, now you have a nice object to deal with
	[output writeObjectToDirectory:shareDir];
	
	[self.uxDelegate updateForShare:output];
}

// just look for stale shares (when we come to front)
- (void)processShares
{
	for ( NSInteger counter = 0 ; counter < 100 ; counter++ ) {
		NSString *theKey = [NSString stringWithFormat:@"%@%zd", kShareBaseKey, counter];
		[self processOneShare:theKey];
	}
}

// process one by key
- (void)processOneShare:(NSString *)theKeyOrFilename
{
#if USE_USER_DEFAULTS
	NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupId];
	NSData *theShareData = [sharedUserDefaults objectForKey:theKeyOrFilename];
	if ( theShareData == nil ) {
		return;
	}
	
	NSMutableDictionary *theShare = [NSKeyedUnarchiver unarchiveObjectWithData:theShareData];
	
#else
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *groupURL = [fm containerURLForSecurityApplicationGroupIdentifier:kAppGroupId];
	NSString *filePath = [groupURL.absoluteString stringByAppendingPathComponent:theKeyOrFilename];
	NSData *theShareData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingUncached error:nil];
	NSMutableDictionary *theShare = nil;
	if ( theShareData ) {
		theShare = [NSKeyedUnarchiver unarchiveObjectWithData:theShareData];
	}
#endif
	
	if ( theShare ) {
		[self processOneShare:theShare forKey:theKeyOrFilename];
	}
}

// process & remove a fetched share
- (void)processOneShare:(NSMutableDictionary *)theShare forKey:(NSString *)theKeyToRemoveUponSuccess;
{
	if ( theShare ) {
		// do whatever we are going to do with our share
		NSLog(@"found a share (%@): %@", theKeyToRemoveUponSuccess, theShare);
		
	}
	
#if USE_USER_DEFAULTS
	// and remove it
	NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupId];
	[sharedUserDefaults removeObjectForKey:theKeyToRemoveUponSuccess];
	[sharedUserDefaults synchronize];
	
#else
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *groupURL = [fm containerURLForSecurityApplicationGroupIdentifier:kAppGroupId];
	NSString *filePath = [groupURL.absoluteString stringByAppendingPathComponent:theKeyToRemoveUponSuccess];
	[fm removeItemAtPath:filePath error:nil];
#endif
	
	[self processShareForUX:theShare];
}


@end
