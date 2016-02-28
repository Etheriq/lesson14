//
//  ViewController.m
//  itune
//
//  Created by Anton Lookin on 2/22/16.
//  Copyright © 2016 geekhub. All rights reserved.
//

#import "iTuneCell.h"
#import "ViewController.h"

@interface ViewController () <NSURLSessionDataDelegate, UITableViewDataSource>

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

#pragma mark UITableViewDataSource<NSObject>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.itunesEntries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * identificator = @"cell";
    iTuneCell *cell = [tableView dequeueReusableCellWithIdentifier:identificator forIndexPath:indexPath];
    [cell configureWithiTuneObject:[self.itunesEntries objectAtIndex:indexPath.row]];
    
    if (!cell.isDownloaded) {
        cell.playButton.enabled = NO;
        cell.downloadButton.enabled = YES;
        [cell.downloadProgressBar setProgress:.0f];
        cell.downloadStatusLabel.text = [NSString stringWithFormat:@"0 of 0"];
    } else {
        cell.playButton.enabled = YES;
        cell.downloadButton.enabled = NO;
        [cell.downloadProgressBar setProgress:1.0f];
        cell.downloadStatusLabel.text = [NSString stringWithFormat:@"Downloaded."];
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
