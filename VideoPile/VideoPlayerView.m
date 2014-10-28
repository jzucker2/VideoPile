//
//  VideoPlayerView.m
//  VideoPile
//
//  Created by Jordan Zucker on 10/27/14.
//  Copyright (c) 2014 Jordan Zucker. All rights reserved.
//

#import "VideoPlayerView.h"
#import <HCYoutubeParser/HCYoutubeParser.h>
@import MediaPlayer;

@implementation VideoPlayerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)setVideo:(NSURL *)url
{
    // Gets an dictionary with each available youtube url
    NSDictionary *videos = [HCYoutubeParser h264videosWithYoutubeURL:url];
    
    if (!_moviePlayer) {
        // Presents a MoviePlayerController with the youtube quality medium
        _moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:[videos objectForKey:@"medium"]]];
        _moviePlayer.view.frame = self.frame;
        //[_moviePlayer.view setTintColor:[UIColor orangeColor]];
        _moviePlayer.scalingMode = MPMovieScalingModeNone;
        _moviePlayer.controlStyle = MPMovieControlStyleNone;
        //MPMoviePlayerViewController *mp = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:[videos objectForKey:@"medium"]]];
        //[self presentMoviePlayerViewControllerAnimated:mp];
        [self addSubview:_moviePlayer.view];
    } else {
        _moviePlayer.contentURL = [NSURL URLWithString:[videos objectForKey:@"medium"]];
    }
    
    //_moviePlayer.view.tintColor = [UIColor redColor];
    
    [self bringSubviewToFront:_playPauseButton];
        
    //    CALayer *maskLayer = [CALayer layer];
    //    maskLayer.contents = (id)[UIImage imageNamed:@"2000px-Orange_logo.svg.png"].CGImage;
    //
    //    maskLayer.opacity = 0.5;
    //
    //    [_playerView.layer insertSublayer:maskLayer atIndex:0];
    //_playerView.layer.mask = maskLayer;
    
    [_moviePlayer performSelector:@selector(play) withObject:nil afterDelay:2];
}

- (IBAction)playPauseAction:(id)sender
{
    
}

@end
