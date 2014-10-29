//
//  AVPlayerView.h
//  VideoPile
//
//  Created by Jordan Zucker on 10/29/14.
//  Copyright (c) 2014 Jordan Zucker. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVPlayer;

@interface AVPlayerView : UIView

@property (nonatomic, strong) AVPlayer *player;

- (void)setPlayer:(AVPlayer *)player;
- (void)setVideoFillMode:(NSString *)fillMode;
- (void)pause;
- (void)play;

@end
