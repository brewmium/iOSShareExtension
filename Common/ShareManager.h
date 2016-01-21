//
//  ShareManager.h
//  HelloShare
//
//  Created by Eric Hayes on 1/19/16.
//  Copyright © 2016 Eric Hayes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShareObject.h"

#define USE_USER_DEFAULTS (1)
#define kAppGroupId @"group.brewmium.reactnative.share"
#define kWormholeDirectory @"wormhole"
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

+ (ShareManager *)sharedInstance;
- (void)setupToCatchShares;
- (void)registerUXDelegate:(id<ShareUXDelegate>)theDelegate;

- (void)processThePost:(NSArray *)attachments withPostText:(NSString *)postContent closure:(ProcessShareClosure)closure;


@end
