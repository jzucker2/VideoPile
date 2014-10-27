//
//  ViewController.h
//  VideoPile
//
//  Created by Jordan Zucker on 10/24/14.
//  Copyright (c) 2014 Jordan Zucker. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PlayerView, AVPlayer, AVPlayerItem;

@interface ViewController : UIViewController

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, weak) IBOutlet PlayerView *playerView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;


@end

