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
@import MobileCoreServices;

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
	});
	
	return sharedInstance;
}

- (void)setupToCatchShares;
{
	self.wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:kAppGroupId optionalDirectory:kWormholeDirectory];
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


- (void)finalizeExtension:(NSMutableDictionary *)outputDict closure:(ProcessShareClosure)closure;
{
	// save what we found to the shared group
	if ( outputDict.count > 0 ) {
		
#if USE_USER_DEFAULTS
		NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupId];
		
		// find an unused key to store the output into
		NSInteger counter = 0;
		NSString *theKey = nil;
		while ( theKey == nil ) {
			theKey = [NSString stringWithFormat:@"%@%zd", kShareBaseKey, counter];
			if ( [sharedUserDefaults objectForKey:theKey] != nil ) {
				// this key exists, nil it out & we'll do another
				theKey = nil;
				counter++;
			}
		}
		
		// finally, store it out & sync the shared defaults
		[sharedUserDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:outputDict] forKey:theKey];
		[sharedUserDefaults synchronize];
#else
		NSFileManager *fm = [NSFileManager defaultManager];
		NSURL *groupURL = [fm containerURLForSecurityApplicationGroupIdentifier:kAppGroupId];
		NSString *basePath = [groupURL.absoluteString stringByAppendingString:@"shares"];
		[[NSFileManager defaultManager] createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil];
		
		// find an unused filename to store the output into
		NSInteger counter = 0;
		NSString *filePath = nil;
		while ( filePath == nil ) {
			filePath = [basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%zd", kShareBaseKey, counter]];
			if ( [fm fileExistsAtPath:filePath isDirectory:nil] ) {
				// this key exists, nil it out & we'll do another
				filePath = nil;
				counter++;
			}
		}
		
		NSData *asData = [NSKeyedArchiver archivedDataWithRootObject:outputDict];
		BOOL result = [asData writeToFile:filePath atomically:YES];
		if ( result == NO ) {
			NSLog(@"write failed");
		}
		
		NSString *theKey = [filePath lastPathComponent];
#endif
		
		// now, lets use wormhole to ping our parent
		MMWormhole *wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:kAppGroupId optionalDirectory:kWormholeDirectory];
		[wormhole passMessageObject:theKey identifier:kShareMessage];
	}
	
	// tell the host we are done
	if ( closure ) {
		closure(nil, outputDict);
	}
}

- (void)extractShares:(NSMutableArray *)attachments intoDict:(NSMutableDictionary *)outputDict closure:(ProcessShareClosure)closure;
{
	if ( attachments.count > 0 ) {
		// grab the last item, calc what we are going to call it in the output dict, and then remove it from the todo list
		NSItemProvider *itemProvider = [attachments lastObject];
		NSString *itemKey = [NSString stringWithFormat:@"%@%zd", kShareItemBase, attachments.count];
		[attachments removeObject:itemProvider];
		
		// Handle Image Type
		if ( [itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypeImage] ) {
			[itemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypeImage options:nil completionHandler:^(UIImage *img, NSError *error) {
				// if we succeeded, add the item to the output
				if ( error == nil && img ) {
					[outputDict setObject:img forKey:itemKey];
				}
				
				// and recurse
				[self extractShares:attachments intoDict:outputDict closure:closure];
			}];
			
			// Handle URL Type
		} else if ( [itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypeURL] ) {
			[itemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
				// if we succeeded, add the item to the output
				if ( error == nil && url ) {
					[outputDict setObject:url forKey:itemKey];
				}
				
				// and recurse
				[self extractShares:attachments intoDict:outputDict closure:closure];
			}];
			
			// We don't know this type, just ignore it
		} else {
			// and recurse
			[self extractShares:attachments intoDict:outputDict closure:closure];
		}
		
	} else {
		[self finalizeExtension:outputDict closure:closure];
	}
}

- (void)processThePost:(NSArray *)attachments withPostText:(NSString *)postText closure:(ProcessShareClosure)closure;
{
	// create the output container, and stick the context text into it
	NSMutableDictionary *sharedItems = [NSMutableDictionary dictionaryWithCapacity:2];
	if ( postText.length > 0 ) {
		[sharedItems setObject:postText forKey:kShareText];
	}
	
	[self extractShares:[NSMutableArray arrayWithArray:attachments] intoDict:sharedItems closure:closure];
}


- (void)outputShareToFileSystemAndJson:(NSMutableDictionary *)shareDict;
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
	
	// tell our owner we have a new share
	if ( [self.uxDelegate respondsToSelector:@selector(updateForShare:)] ) {
		[self.uxDelegate updateForShare:output];
	}
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
	
	[self outputShareToFileSystemAndJson:theShare];
}


@end
