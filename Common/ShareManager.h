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
#define kWormHoldDirectory @"wormhole"
#define kShareMessage @"share"
#define kShareBaseKey @"share_"
#define kShareText @"share_text"
#define kShareItemBase	@"share_item_"

@protocol ShareUXDelegate <NSObject>
@required
- (void)updateForShare:(ShareObject *)theShare;
@end


@interface ShareManager : NSObject

@property (nonatomic, strong) id<ShareUXDelegate> uxDelegate;	// prototype use only!!! this will cause a retain issue, don't update your UX like this!

+ (ShareManager *)sharedInstance;
- (void)registerUXDelegate:(id<ShareUXDelegate>)theDelegate;


@end
