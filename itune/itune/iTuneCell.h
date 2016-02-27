//
//  iTuneCell.h
//  itune
//
//  Created by Yuriy T on 27.02.16.
//  Copyright © 2016 geekhub. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface iTuneCell : UITableViewCell

@property (strong, nonatomic) NSString* artistName;
@property (strong, nonatomic) NSString* trackName;
@property (strong, nonatomic) NSString* previewUrl;
@property (strong, nonatomic) NSString* albomName;
@property (assign, nonatomic) BOOL isDownloaded;
@property (assign, nonatomic) BOOL isPlay;
@property (strong, nonatomic) NSString* fileName;
@property (strong, nonatomic) NSString* imageUrl;
@property (strong, nonatomic) UIImage* tmpImage;

@property (nonatomic, strong) NSURLSession *session;

@property (weak, nonatomic) IBOutlet UIImageView *trackImage;
@property (weak, nonatomic) IBOutlet UILabel *artistNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *trackNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *albomNameLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressBar;
@property (weak, nonatomic) IBOutlet UILabel *downloadStatusLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;

- (void) configureWithiTuneObject: (NSArray*) object;

@end
