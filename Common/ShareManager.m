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
		
		NSURL *fileURL = [self makeUniqueShareFileURL];

		if ( fileURL ) {
			NSData *asData = [NSKeyedArchiver archivedDataWithRootObject:outputDict];
			BOOL result = [asData writeToURL:fileURL atomically:YES];
			if ( result == NO ) {
				NSLog(@"write failed");
			}
		}
		NSString *theKey = [fileURL lastPathComponent];
		
		if ( theKey.length > 0 ) {
			// now, lets use wormhole to ping our parent
			MMWormhole *wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:kAppGroupId optionalDirectory:kWormholeDirectory];
			[wormhole passMessageObject:theKey identifier:kShareMessage];
		}
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
	
	// make the output location
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
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

- (NSURL *)makeUniqueShareFileURL
{
	//NSURL *sharesURL = [self getSharesURL];
	
	NSInteger counter = 0;
	NSURL *fileURL = nil;
	while ( fileURL == nil ) {
		fileURL = [self getShareFileURL:[NSString stringWithFormat:@"%@%zd", kShareBaseKey, counter]];
		//fileURL = [sharesURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@%zd", kShareBaseKey, counter]];
		if ( [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:nil] ) {
			// this key exists, nil it out & we'll do another
			fileURL = nil;
			counter++;
		}
	}
	
	return fileURL;
}

- (NSURL *)getShareFileURL:(NSString *)shareKey
{
	NSURL *sharesURL = [self getSharesURL];
	NSURL *fileURL = [sharesURL URLByAppendingPathComponent:shareKey isDirectory:NO];
	return fileURL;
}

- (NSURL *)getSharesURL
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *groupURL = [fm containerURLForSecurityApplicationGroupIdentifier:kAppGroupId];
	NSURL *shareDir = [groupURL URLByAppendingPathComponent:@"shares" isDirectory:YES];
	
	NSError *err = nil;
	[fm createDirectoryAtPath:[shareDir path] withIntermediateDirectories:YES attributes:nil error:&err];
	
	return shareDir;
}

// process one by key
- (void)processOneShare:(NSString *)theKeyOrFilename
{
	NSURL *fileURL = [self getShareFileURL:theKeyOrFilename];
	NSData *theShareData = [NSData dataWithContentsOfFile:[fileURL path] options:NSDataReadingUncached error:nil];
	NSMutableDictionary *theShare = nil;
	if ( theShareData ) {
		theShare = [NSKeyedUnarchiver unarchiveObjectWithData:theShareData];
	}
	
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
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *groupURL = [fm containerURLForSecurityApplicationGroupIdentifier:kAppGroupId];
	NSString *filePath = [groupURL.absoluteString stringByAppendingPathComponent:theKeyToRemoveUponSuccess];
	[fm removeItemAtPath:filePath error:nil];
	
	[self outputShareToFileSystemAndJson:theShare];
}


@end
