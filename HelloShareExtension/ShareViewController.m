//
//  ShareViewController.m
//  HelloShareExtension
//
//  Created by Eric Hayes on 1/18/16.
//  Copyright © 2016 Eric Hayes. All rights reserved.
//

#import "ShareViewController.h"
#import "ShareManager.h"

@interface ShareViewController ()

@end

@implementation ShareViewController

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}
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
}

- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}

@end
