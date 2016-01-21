//
//  ShareManager.h
//  HelloShare
//
//  Created by Eric Hayes on 1/19/16.
//  Copyright © 2016 Eric Hayes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShareObject.h"

#define kAppGroupId @"group.brewmium.reactnative.share"
#define kWormholeDirectory @"wormhole"
#define kSharesDirectorys @"shares"
#define kShareMessage @"share"
#define kShareBaseKey @"share_"
#define kShareText @"share_text"
#define kShareItemBase	@"share_item_"

@protocol ShareUXDelegate <NSObject>
@required
- (void)updateForShare:(ShareObject *)theShare;
@end

typedef void (^ProcessShareClosure)(NSError *error, NSDictionary *shareObject);

@interface ShareManager : NSObject

@property (nonatomic, strong) id<ShareUXDelegate> uxDelegate;	// prototype use only!!! this will cause a retain issue, don't update your UX like this!

// initialie the singleton
+ (ShareManager *)sharedInstance;

//
// Parent App Methods
//

// if you are the parent App, you can start listening for your extension & process those shares
- (void)setupToCatchShares;

// Notify the Parent App of new shares. Really for prototype use only!!! this can/WILL cause a retain issues, don't update your UX like this!
- (void)registerUXDelegate:(id<ShareUXDelegate>)theDelegate;

// loop any stale shares and process them
- (void)processShares;

//
// Extension Methods
//

// called by the extension to process a share.
- (void)processThePost:(NSArray *)attachments withPostText:(NSString *)postContent closure:(ProcessShareClosure)closure;


@end
