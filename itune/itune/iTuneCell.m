//
//  iTuneCell.m
//  itune
//
//  Created by Yuriy T on 27.02.16.
//  Copyright © 2016 geekhub. All rights reserved.
//

#import "iTuneCell.h"

@interface iTuneCell() <NSURLSessionDelegate, NSURLSessionTaskDelegate>





@end

@implementation iTuneCell

- (void)awakeFromNib {
    // Initialization code
}

- (void) configureWithiTuneObject: (NSDictionary*) object {
    
    self.artistNameLabel.text = object[@"artistName"];
    self.trackNameLabel.text = object[@"trackName"];
    self.previewUrl = object[@"previewUrl"];
    self.albomNameLabel.text = object[@"collectionName"];
    self.imageUrl = object[@"artworkUrl100"];
    self.isDownloaded = [self checkOnDownloadedTrack:[self.previewUrl lastPathComponent]];
    
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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Actions
- (IBAction)playAction:(UIButton *)sender {
    
    NSLog(@"dsadas");
}
- (IBAction)downloadAction:(UIButton *)sender {
}
- (IBAction)galleryAction:(UIButton *)sender {
}


@end
