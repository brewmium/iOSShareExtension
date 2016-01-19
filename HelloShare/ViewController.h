//
//  ViewController.h
//  HelloShare
//
//  Created by Eric Hayes on 1/18/16.
//  Copyright © 2016 Eric Hayes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShareManager.h"

@interface ViewController : UIViewController <ShareUXDelegate>
@property (weak, nonatomic) IBOutlet UILabel *postText;
@property (weak, nonatomic) IBOutlet UIImageView *firstImage;
@property (weak, nonatomic) IBOutlet UIImageView *lastImage;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;

@end

