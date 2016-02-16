//
//  ShareObject.m
//  HelloShare
//
//  Created by Eric Hayes on 1/18/16.
//  Copyright © 2016 Eric Hayes. All rights reserved.
//

#import "ShareObject.h"

@implementation ShareObject


// write the images and the json to a share folder in the App's sandbox.
- (NSString *)writeObjectToDirectory:(NSString *)destinationDir;
{
	// make a new folder to put this share in (and make sure the new folder exists)
	NSTimeInterval interval = [NSDate timeIntervalSinceReferenceDate];
	NSString *uniqueFolderName = [NSString stringWithFormat:@"share_%zd", interval];	// this should always work....
	NSString *pathToShareContents = [destinationDir stringByAppendingPathComponent:uniqueFolderName];
	[[NSFileManager defaultManager] createDirectoryAtPath:pathToShareContents withIntermediateDirectories:YES attributes:nil error:nil];

	NSMutableDictionary *futureJson = [NSMutableDictionary new];
	
	// maybe add the title
	if ( self.postText.length > 0 ) {
		[futureJson setObject:self.postText forKey:@"post_text"];
	}
	
	// add the images
	if ( self.images.count > 0 ) {
		NSMutableArray *imagesArray = [NSMutableArray new];
		NSInteger counter = 0;
		for ( UIImage *img in self.images ) {
			NSString *imagePath = [pathToShareContents stringByAppendingPathComponent:[NSString stringWithFormat:@"image_%zd.jpg", counter]];
			NSData *data = UIImageJPEGRepresentation(img, 1.0);
			if ( [data writeToFile:imagePath atomically:YES] ) {
				[imagesArray addObject:imagePath];
			}
			
			counter++;
		}
		
		[futureJson setObject:imagesArray forKey:@"images"];
	}
	
	// add the URLs
	if ( self.urls.count > 0 ) {
//		NSMutableArray *marr = [NSMutableArray arrayWithCapacity:self.urls.count];
//		for ( NSURL *url in self.urls ) {
//			NSString *str = url.absoluteString;
//			if ( str.length > 0 ) {
//				[marr addObject:str];
//			}
//		}
		[futureJson setObject:self.urls forKey:@"urls"];
	}
	
	// convert our dict to a json string
	NSError *err;
	NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:futureJson options:0 error:&err];
	NSString * jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	
	// write the json out..  you probably don't need this done
	NSString *jsonPath = [pathToShareContents stringByAppendingPathComponent:@"share.json"];
	if ( [jsonString writeToFile:jsonPath atomically:YES encoding:NSISOLatin1StringEncoding error:&err] == NO ) {
		NSLog(@"json write faled: %@", jsonString);
	}
	
	NSLog(@"json output: %@", jsonString);
	return jsonString;
}

@end
