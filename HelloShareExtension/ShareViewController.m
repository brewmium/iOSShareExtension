//
//  ShareViewController.m
//  HelloShareExtension
//
//  Created by Eric Hayes on 1/18/16.
//  Copyright © 2016 Eric Hayes. All rights reserved.
//

#import "ShareViewController.h"
@import MobileCoreServices;
#import "MMWormhole.h"
#import "ShareManager.h"

@interface ShareViewController ()

@end

@implementation ShareViewController

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}

//- (void)finalizeExtension:(NSMutableDictionary *)outputDict;
//{
//	// save what we found to the shared group
//	if ( outputDict.count > 0 ) {
//		
//#if USE_USER_DEFAULTS
//		NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupId];
//
//		// find an unused key to store the output into
//		NSInteger counter = 0;
//		NSString *theKey = nil;
//		while ( theKey == nil ) {
//			theKey = [NSString stringWithFormat:@"%@%zd", kShareBaseKey, counter];
//			if ( [sharedUserDefaults objectForKey:theKey] != nil ) {
//				// this key exists, nil it out & we'll do another
//				theKey = nil;
//				counter++;
//			}
//		}
//		
//		// finally, store it out & sync the shared defaults
//		[sharedUserDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:outputDict] forKey:theKey];
//		[sharedUserDefaults synchronize];
//#else
//		NSFileManager *fm = [NSFileManager defaultManager];
//		NSURL *groupURL = [fm containerURLForSecurityApplicationGroupIdentifier:kAppGroupId];
//		NSString *basePath = [groupURL.absoluteString stringByAppendingString:@"shares"];
//		[[NSFileManager defaultManager] createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil];
//		
//		// find an unused filename to store the output into
//		NSInteger counter = 0;
//		NSString *filePath = nil;
//		while ( filePath == nil ) {
//			filePath = [basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%zd", kShareBaseKey, counter]];
//			if ( [fm fileExistsAtPath:filePath isDirectory:nil] ) {
//				// this key exists, nil it out & we'll do another
//				filePath = nil;
//				counter++;
//			}
//		}
//		
//		NSData *asData = [NSKeyedArchiver archivedDataWithRootObject:outputDict];
//		BOOL result = [asData writeToFile:filePath atomically:YES];
//		if ( result == NO ) {
//			NSLog(@"write failed");
//		}
//		
//		NSString *theKey = [filePath lastPathComponent];
//#endif
//		
//		// now, lets use wormhole to ping our parent
//		MMWormhole *wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:kAppGroupId optionalDirectory:kWormHoldDirectory];
//		[wormhole passMessageObject:theKey identifier:kShareMessage];
//	}
//	
//	// tell the host we are done
//	[self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
//}
//
//- (void)extractShares:(NSMutableArray *)attachments intoDict:(NSMutableDictionary *)outputDict;
//{
//	if ( attachments.count > 0 ) {
//		// grab the last item, calc what we are going to call it in the output dict, and then remove it from the todo list
//		NSItemProvider *itemProvider = [attachments lastObject];
//		NSString *itemKey = [NSString stringWithFormat:@"%@%zd", kShareItemBase, attachments.count];
//		[attachments removeObject:itemProvider];
//
//		// Handle Image Type
//		if ( [itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypeImage] ) {
//			[itemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypeImage options:nil completionHandler:^(UIImage *img, NSError *error) {
//				// if we succeeded, add the item to the output
//				if ( error == nil && img ) {
//					[outputDict setObject:img forKey:itemKey];
//				}
//				
//				// and recurse
//				[self extractShares:attachments intoDict:outputDict];
//			}];
//		
//		// Handle URL Type
//		} else if ( [itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypeURL] ) {
//			[itemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
//				// if we succeeded, add the item to the output
//				if ( error == nil && url ) {
//					[outputDict setObject:url forKey:itemKey];
//				}
//				
//				// and recurse
//				[self extractShares:attachments intoDict:outputDict];
//			}];
//			
//		// We don't know this type, just ignore it
//		} else {
//			// and recurse
//			[self extractShares:attachments intoDict:outputDict];
//		}
//		
//	} else {
//		[self finalizeExtension:outputDict];
//	}
//}

- (void)didSelectPost
{
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
	
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    NSExtensionItem *inputItem = self.extensionContext.inputItems.firstObject;
	if ( inputItem == nil ) {
		[self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
		return;
	}
	
	[[ShareManager sharedInstance] processThePost:[inputItem attachments] withPostText:self.contentText closure:^(NSError *error, NSDictionary *outputDict) {
		[self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
	}];

//	NSLog(@"attachments: %@", [inputItem attachments]);
//	
//	// create the output container, and stick the context text into it
//	NSMutableDictionary *sharedItems = [NSMutableDictionary dictionaryWithCapacity:2];
//	if ( self.contentText.length > 0 ) {
//		[sharedItems setObject:self.contentText forKey:kShareText];
//	}
//	
//	// create our own mutable copy of the attachments (we will remove from them as we go along), and start the recursion
//	[self extractShares:[NSMutableArray arrayWithArray:[inputItem attachments]] intoDict:sharedItems];
}

- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}

@end
