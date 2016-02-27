//
//  ViewController.m
//  itune
//
//  Created by Anton Lookin on 2/22/16.
//  Copyright © 2016 geekhub. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "iTuneCell.h"
#import "ViewController.h"

@interface ViewController () <NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSArray *itunesEntries;
@property (weak, nonatomic) IBOutlet UITableView *table;

@end

@implementation ViewController

-(void) viewDidLoad {
	[super viewDidLoad];
	
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
	configuration.HTTPMaximumConnectionsPerHost = 3;
	self.session = [NSURLSession sessionWithConfiguration:configuration
												 delegate:self
											delegateQueue:[NSOperationQueue mainQueue]];
	
	NSURLSessionDataTask *task = [self.session dataTaskWithURL:[NSURL URLWithString:@"https://itunes.apple.com/search?term=rock&country=US&entity=song"]
											 completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
												 NSError *jsonError = nil;
												 NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data
																												 options:0ul
																												   error:&jsonError];
												 self.itunesEntries = jsonData[@"results"];
												 NSLog(@"%@", self.itunesEntries);
												 NSString *previewUrl = [self.itunesEntries lastObject][@"previewUrl"];
												 NSLog(@"%@", [previewUrl lastPathComponent]);
												 [self downloadItunesAudioPreview:previewUrl];
                                                 [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                                 [self.table reloadData];
											 }];
	[task resume];
    
    NSString *applicationSupportPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:applicationSupportPath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
    }
}

-(void) downloadItunesAudioPreview:(NSString *)previewUrl {
	NSURLSessionDownloadTask *task = [self.session downloadTaskWithURL:[NSURL URLWithString:previewUrl]];
	[task resume];
}


-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
	NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
	NSLog(@"%@ of %@", [formatter stringFromByteCount:totalBytesWritten], [formatter stringFromByteCount:totalBytesExpectedToWrite]);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error = nil;
	NSString *destinationUrl = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"];
	destinationUrl = [destinationUrl stringByAppendingPathComponent:@"2.m4a"];
	
	if (![fileManager fileExistsAtPath:destinationUrl]) {
		[fileManager moveItemAtURL:location
							 toURL:[NSURL fileURLWithPath:destinationUrl]
							 error:&error];
	} else {
		[fileManager replaceItemAtURL:[NSURL fileURLWithPath:destinationUrl]
						withItemAtURL:location
					   backupItemName:@"ololo"
							  options:0ul
					 resultingItemURL:NULL
								error:&error];
	}
	NSLog(@"%@", error);
	
//	AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] initWithNibName:nil bundle:nil];
//	AVPlayer *player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:destinationUrl]];
//	playerViewController.player = player;
//	[self presentViewController:playerViewController animated:YES completion:NULL];
	
}

#pragma mark UITableViewDataSource<NSObject>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.itunesEntries count];
//    return 1;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * identificator = @"cell";
    iTuneCell *cell = [tableView dequeueReusableCellWithIdentifier:identificator forIndexPath:indexPath];
    [cell configureWithiTuneObject:[self.itunesEntries objectAtIndex:indexPath.row]];
    
    if (!cell.isDownloaded) {
        cell.playButton.enabled = NO;
        cell.downloadButton.enabled = YES;
    } else {
        cell.playButton.enabled = YES;
        cell.downloadButton.enabled = NO;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[self.session dataTaskWithURL:[NSURL URLWithString:cell.imageUrl]
                     completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                         
            cell.trackImage.image = [UIImage imageWithData:data];
        }] resume];
    });

//    NSURLSessionDataTask *dataTask = [self.session dataTaskWithURL:[NSURL URLWithString:cell.imageUrl]
//                                             completionHandler:^(NSData *data, NSURLResponse *response,
//                                                                 NSError *error) {
//                                                 if (!error) {
//                                                     cell.tmpImage = [[UIImage alloc] initWithData:data];
//                                                     dispatch_async(dispatch_get_main_queue(), ^{
//
//                                                         cell.trackImage.image = cell.tmpImage;
//                                                     });
//                                                 } else {
//                                                     // HANDLE ERROR //
//                                                 }
//                                             }];
//    [dataTask resume];
//    
    
    return cell;
}

@end
