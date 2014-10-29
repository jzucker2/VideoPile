//
//  AVPlayerView.m
//  VideoPile
//
//  Created by Jordan Zucker on 10/29/14.
//  Copyright (c) 2014 Jordan Zucker. All rights reserved.
//

#import "AVPlayerView.h"

@import AVFoundation;

@implementation AVPlayerView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayer *)player
{
    return [(AVPlayerLayer*)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player
{
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

/* Specifies how the video is displayed within a player layer’s bounds.
	(AVLayerVideoGravityResizeAspect is default) */
- (void)setVideoFillMode:(NSString *)fillMode
{
    AVPlayerLayer *playerLayer = (AVPlayerLayer*)[self layer];
    playerLayer.videoGravity = fillMode;
}

- (void)pause
{
    if (self.player) {
        [self.player pause];
    }
}

- (void)play
{
    if (self.player) {
        [self.player play];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
