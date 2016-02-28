//
//  ViewController.m
//  itune
//
//  Created by Anton Lookin on 2/22/16.
//  Copyright © 2016 geekhub. All rights reserved.
//

#import "iTuneCell.h"
#import "ViewController.h"
#import "MWPhotoBrowser.h"

@interface ViewController () <NSURLSessionDataDelegate, UITableViewDataSource, UITableViewDelegate, MWPhotoBrowserDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSession *sessionGallery;
@property (nonatomic, strong) NSArray *itunesEntries;
@property (weak, nonatomic) IBOutlet UITableView *table;

@property (strong, nonatomic) NSMutableArray* galleryPhotos;
@property (strong, nonatomic) NSArray* galleryItems;


@end

@implementation ViewController

-(void) viewDidLoad {
	[super viewDidLoad];
    
    self.navigationItem.title = @"Track list";
	
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
	configuration.HTTPMaximumConnectionsPerHost = 3;
    configuration.allowsCellularAccess = NO;
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

- (void)viewDidAppear:(BOOL)animated {
    NSIndexPath *indexPath = self.table.indexPathForSelectedRow;
    if (indexPath) {
        [self.table deselectRowAtIndexPath:indexPath animated:animated];
    }
}

#pragma mark UITableViewDataSource

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

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary* iTuneItem = [self.itunesEntries objectAtIndex:indexPath.row];
    
    self.galleryPhotos = [NSMutableArray array];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPMaximumConnectionsPerHost = 3;
    configuration.allowsCellularAccess = NO;
    [configuration setHTTPAdditionalHeaders:
        @{@"Authorization": @"Client-ID 510d3df1e146294"}
    ];
    self.sessionGallery = [NSURLSession sessionWithConfiguration:configuration
                                                        delegate:self
                                                   delegateQueue:[NSOperationQueue mainQueue]];
    NSString* galleryPathRaw = [NSString stringWithFormat:@"https://api.imgur.com/3/gallery/search/top/0?q=%@", iTuneItem[@"artistName"]];
    NSString* galleryPath = [galleryPathRaw stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURLSessionDataTask *task = [self.sessionGallery dataTaskWithURL:[NSURL URLWithString:galleryPath]
                                                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                        NSError *jsonError = nil;
                 
                                                        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data
                                                                                                                 options:0ul
                                                                                                                   error:&jsonError];
                                                        self.galleryItems = jsonData[@"data"];
                                                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                                        [self showGalleryAction];
                                                    }];
    [task resume];
    
}

#pragma mark - Actions
- (void) showGalleryAction {
    
    for (NSDictionary* object in self.galleryItems) {
        MWPhoto* photo = [MWPhoto photoWithURL:[NSURL URLWithString:object[@"link"]]];

        NSString* title = object[@"title"];
        if (object[@"title"] == (id)[NSNull null] || [object[@"title"] length] == 0 ) {
            title = @"";
        }
        NSString* descr = object[@"description"];
        if (object[@"description"] == (id)[NSNull null] || [object[@"description"] length] == 0 ) {
            descr = @"";
        }
        
        photo.caption = [NSString stringWithFormat:@"%@ %@", title, descr];
        
        [self.galleryPhotos addObject: photo];
    }
    
    MWPhotoBrowser* browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = NO; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = YES; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    browser.startOnGrid = YES; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    browser.autoPlayOnAppear = NO; // Auto-play first video
    
    [browser setCurrentPhotoIndex:1];
    
    [self.navigationController pushViewController:browser animated:YES];
}

#pragma mark - MWPhotoBrowserDelegate


- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    
    return [self.galleryPhotos count];
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.galleryPhotos.count) {
        return [self.galleryPhotos objectAtIndex:index];
    }
    
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (index < self.galleryPhotos.count) {
        return [self.galleryPhotos objectAtIndex:index];
    }
    
    return nil;
}

@end
