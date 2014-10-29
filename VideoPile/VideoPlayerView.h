//
//  VideoPlayerView.h
//  VideoPile
//
//  Created by Jordan Zucker on 10/27/14.
//  Copyright (c) 2014 Jordan Zucker. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MPMoviePlayerController, RKLink;

extern NSString* const VideoPlayerViewPassedUpvoteThreshold;
extern NSString* const VideoPlayerViewPassedDownvoteThreshold;

@interface VideoPlayerView : UIView

@property (nonatomic, weak) IBOutlet UIButton *playPauseButton;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;

- (IBAction)playPauseAction:(id)sender;

- (void)setVideo:(RKLink *)link;

- (void)pauseVideo;
- (void)playVideo;

@end
