//
//  iTuneCell.m
//  itune
//
//  Created by Yuriy T on 27.02.16.
//  Copyright © 2016 geekhub. All rights reserved.
//

#import "iTuneCell.h"
#import "AVFoundation/AVFoundation.h"

@interface iTuneCell() <NSURLSessionDelegate, NSURLSessionDownloadDelegate, AVAudioPlayerDelegate>

@property (strong, nonatomic) AVAudioPlayer* player;
@property (strong, nonatomic) NSTimer* timer;

@property (strong, nonatomic) NSMutableArray* galleryPhotos;
@property (strong, nonatomic) NSArray* galleryItems;

@end

@implementation iTuneCell

- (void)awakeFromNib {
    // Initialization code
}

- (void) configureWithiTuneObject: (NSDictionary*) object {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPMaximumConnectionsPerHost = 3;
    self.session = [NSURLSession sessionWithConfiguration:configuration
                                                 delegate:self
                                            delegateQueue:[NSOperationQueue mainQueue]];
    
    self.isPlay = NO;
    self.artistNameLabel.text = object[@"artistName"];
    self.trackNameLabel.text = object[@"trackName"];
    self.previewUrl = object[@"previewUrl"];
    self.albomNameLabel.text = object[@"collectionName"];
    self.imageUrl = object[@"artworkUrl100"];
    self.isDownloaded = [self checkOnDownloadedTrack:[self.previewUrl lastPathComponent]];
    self.fileName = [self.previewUrl lastPathComponent];
}

- (bool) checkOnDownloadedTrack: (NSString *) trackName {
    
    NSString *trackPath = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
                                        stringByAppendingPathComponent:@"Application Support"]
                                        stringByAppendingPathComponent:trackName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:trackPath]) {
        
        return YES;
    }
    
    return NO;
}

- (void) initPlayer {
    
    if (self.isDownloaded) {
        NSString *trackPath = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
                                stringByAppendingPathComponent:@"Application Support"]
                               stringByAppendingPathComponent:self.fileName];
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:trackPath] error:nil];
        self.player.delegate = self;
    }
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Actions
- (IBAction)playAction:(UIButton *)sender {
    
    if (!self.player) {
        [self initPlayer];
    }
    
    self.isPlay = !self.isPlay;
    if (self.isPlay) {
        [self.playButton setTitle:@"Pause" forState:UIControlStateNormal];
        [self.player play];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:.5f target:self selector:@selector(updateElapsedTime) userInfo:nil repeats:YES];
    } else {
        [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
        [self.player pause];
        [self.timer invalidate];
        self.timer = nil;
    }
    
}
- (IBAction)downloadAction:(UIButton *)sender {
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithURL:[NSURL URLWithString:self.previewUrl]];
    [task resume];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

#pragma mark - Player progress bar

- (void)updateElapsedTime{
    if (self.player) {
        [self.downloadProgressBar setProgress:[self.player currentTime] / [self.player duration]];
        [self.downloadStatusLabel setText:[NSString stringWithFormat:@"%@", [self formatTime:[self.player currentTime]]]];
    }
}

- (NSString*)formatTime:(float)time {
    int minutes = time / 60;
    int seconds = (int)time % 60;
    return [NSString stringWithFormat:@"%@%d:%@%d", minutes / 10 ? [NSString stringWithFormat:@"%d", minutes / 10] : @"", minutes % 10, [NSString stringWithFormat:@"%d", seconds / 10], seconds % 10];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *destinationUrl = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"];
    destinationUrl = [destinationUrl stringByAppendingPathComponent:[self.previewUrl lastPathComponent]];
    
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
    self.isDownloaded = YES;
    self.playButton.enabled = YES;
    self.downloadButton.enabled = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self initPlayer];
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
    
    [self.downloadProgressBar setProgress:(double)totalBytesWritten / (double)totalBytesExpectedToWrite];
    self.downloadStatusLabel.text = [NSString stringWithFormat:@" %@ of %@", [formatter stringFromByteCount:totalBytesWritten], [formatter stringFromByteCount:totalBytesExpectedToWrite]];
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    self.isPlay = NO;
    [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    [self.timer invalidate];
    self.timer = nil;
}

@end
