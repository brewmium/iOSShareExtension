//
//  ViewController.m
//  HelloShare
//
//  Created by Eric Hayes on 1/18/16.
//  Copyright © 2016 Eric Hayes. All rights reserved.
//

#import "ViewController.h"
#import "ShareViewController.h"
#import "ShareManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	[[ShareManager sharedInstance] registerUXDelegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Really Dumbed down UX update


- (void)updateForShare:(ShareObject *)theShare;
{
	self.postText.text = theShare.postText.length == 0 ? @"no post text supplied" : theShare.postText;
	
	// clear out the display
	self.firstImage.image = nil;
	self.lastImage.image = nil;
	self.urlLabel.text = @"";
	
	if ( theShare.images.count > 0 ) {
		self.firstImage.image = [theShare.images firstObject];;
	}
	
	if ( theShare.images.count > 1 ) {
		self.lastImage.image = [theShare.images lastObject];;
	}
	
	if ( theShare.urls.count > 0 ) {
		self.urlLabel.text = [theShare.urls firstObject];
	}
}


@end
