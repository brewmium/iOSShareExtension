//
//  ShareObject.h
//  HelloShare
//
//  Created by Eric Hayes on 1/18/16.
//  Copyright © 2016 Eric Hayes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ShareObject : NSObject
@property (nonatomic, copy) NSString *postText;
@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic, strong) NSMutableArray *urls;

- (NSString *)writeObjectToDirectory:(NSString *)destinationDir;
@end
