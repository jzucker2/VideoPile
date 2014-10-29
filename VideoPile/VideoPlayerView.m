//
//  VideoPlayerView.m
//  VideoPile
//
//  Created by Jordan Zucker on 10/27/14.
//  Copyright (c) 2014 Jordan Zucker. All rights reserved.
//

#import "VideoPlayerView.h"
#import <HCYoutubeParser/HCYoutubeParser.h>
#import <RedditKit/RedditKit.h>
//#import "AVPlayerView.h"
@import MediaPlayer;
@import AVFoundation;

/* Asset keys */
NSString * const kTracksKey = @"tracks";
NSString * const kPlayableKey = @"playable";

/* PlayerItem keys */
NSString * const kStatusKey         = @"status";
NSString * const kCurrentItemKey	= @"currentItem";

// The lower the upper vote ratio, the lower on the screen it takes for an upvote (default 0.10)
#define UPPER_VOTE_THRESHOLD_FACTOR     0.10
// The higher the lower vote ratio, the higher on the screen it takes for a vote to register (default 0.55)
#define LOWER_VOTE_THRESHOLD_FACTOR     0.55

@interface VideoPlayerView ()

@property (nonatomic) CGRect originalFrame;
@property (nonatomic, strong) NSURL *redditURL;
@property (nonatomic, strong) RKLink *redditLink;
@property (nonatomic, assign) BOOL isPausedState;
@property (nonatomic, strong) UIVisualEffectView *blurEffectView;
@property (nonatomic, assign) BOOL startedMoving;
@property (nonatomic, assign) NSTimeInterval lastTouchesBeganTimestamp;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *scoreLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, weak) IBOutlet UILabel *scoreTitleLabel;
@property (nonatomic, strong) AVPlayerItem *playerItem;

@end

NSString* const VideoPlayerViewPassedUpvoteThreshold = @"VideoPlayerViewPassedUpvoteThreshold";
NSString* const VideoPlayerViewPassedDownvoteThreshold = @"VideoPlayerViewPassedDownvoteThreshold";

static void *AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext = &AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext;
static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;

@implementation VideoPlayerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)playVideo
{
    [self setState:NO];
    [self.player play];
}

- (void)pauseVideo
{
    [self setState:YES];
    [self.player pause];
}

- (void)setVideo:(RKLink *)link
{
    if (_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    _redditLink = link;
    _redditURL = link.URL;
    
    // Gets an dictionary with each available youtube url
    NSDictionary *videos = [HCYoutubeParser h264videosWithYoutubeURL:_redditURL];
    
    NSURL *youtubeURL = [NSURL URLWithString:[videos objectForKey:@"medium"]];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:youtubeURL options:nil];
    
    NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
    
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
     ^{
         dispatch_async( dispatch_get_main_queue(),
                        ^{
                            [self prepareToPlayAsset:asset withKeys:requestedKeys];
                        });
     }];
//    // Gets an dictionary with each available youtube url
//    NSDictionary *videos = [HCYoutubeParser h264videosWithYoutubeURL:_redditURL];
//    
//    if (!self.player) {
//        // Presents a MoviePlayerController with the youtube quality medium
//        NSURL *youtubeURL = [NSURL URLWithString:[videos objectForKey:@"medium"]];
//        self.player = ;
//        _moviePlayer.view.frame = self.frame;
//        //[_moviePlayer.view setTintColor:[UIColor orangeColor]];
//        _moviePlayer.scalingMode = MPMovieScalingModeNone;
//        _moviePlayer.controlStyle = MPMovieControlStyleNone;
//        _moviePlayer.repeatMode = MPMovieRepeatModeOne;
//        //MPMoviePlayerViewController *mp = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:[videos objectForKey:@"medium"]]];
//        //[self presentMoviePlayerViewControllerAnimated:mp];
//        [self addSubview:_moviePlayer.view];
//    } else {
//        _moviePlayer.contentURL = [NSURL URLWithString:[videos objectForKey:@"medium"]];
//        self.frame = _originalFrame;
//    }
    
    if (!_blurEffectView) {
        UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        _blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        
        _blurEffectView.frame = self.bounds;
    }
    
    _isPausedState = YES;
    _startedMoving = NO;
    
    _titleLabel.text = _redditLink.title;
    _timeLabel.text = [_dateFormatter stringFromDate:_redditLink.created];
    _scoreLabel.text = [NSString stringWithFormat:@"%ld", (long)_redditLink.score];
    
    [self.superview bringSubviewToFront:self];
    [self bringSubviewToFront:_moviePlayer.view];
    [self setState:YES];
    
    //_moviePlayer.view.tintColor = [UIColor redColor];
    
    //[self bringSubviewToFront:_playPauseButton];
        
    //    CALayer *maskLayer = [CALayer layer];
    //    maskLayer.contents = (id)[UIImage imageNamed:@"2000px-Orange_logo.svg.png"].CGImage;
    //
    //    maskLayer.opacity = 0.5;
    //
    //    [_playerView.layer insertSublayer:maskLayer atIndex:0];
    //_playerView.layer.mask = maskLayer;
    
    //[_moviePlayer performSelector:@selector(play) withObject:nil afterDelay:2];
}

- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys {
    for (NSString *thisKey in requestedKeys) {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed) {
            return;
        }
    }
    
    if (!asset.playable) {
        return;
    }
    
    if (_playerItem) {
        [_playerItem removeObserver:self forKeyPath:kStatusKey];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:_playerItem];
    }
    
    _playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [_playerItem addObserver:self
                      forKeyPath:kStatusKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
    
    if (!self.player) {
        [self setPlayer:[AVPlayer playerWithPlayerItem:_playerItem]];
        [self.player addObserver:self
                      forKeyPath:kCurrentItemKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext];
    }
    
    if (self.player.currentItem != _playerItem) {
        [self.player replaceCurrentItemWithPlayerItem:_playerItem];
    }
}

#pragma mark - Key Value Observing

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context {
    if (context == AVPlayerDemoPlaybackViewControllerStatusObservationContext) {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (status == AVPlayerStatusReadyToPlay) {
            //[self.player play];
        }
    } else if (context == AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext) {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        if (newPlayerItem) {
            [self setPlayer:self.player];
            [self setVideoFillMode:AVLayerVideoGravityResizeAspect];
        }
    } else {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}

- (IBAction)playPauseAction:(id)sender
{
    if ((_moviePlayer.playbackState == MPMoviePlaybackStatePaused) || (_moviePlayer.playbackState == MPMoviePlaybackStateStopped)) {
        [self playVideo];
    } else if (_moviePlayer.playbackState == MPMoviePlaybackStatePlaying) {
        [self pauseVideo];
    }
}

- (void)setState:(BOOL)shouldPause
{
    _isPausedState = shouldPause;
    if (_isPausedState && !(_blurEffectView.superview == self)) {
        [self addSubview:_blurEffectView];
        [_titleLabel setHidden:NO];
        [self bringSubviewToFront:_titleLabel];
        [_scoreLabel setHidden:NO];
        [self bringSubviewToFront:_scoreLabel];
        [_timeLabel setHidden:NO];
        [self bringSubviewToFront:_timeLabel];
        [_scoreTitleLabel setHidden:NO];
        [self bringSubviewToFront:_scoreTitleLabel];
    } else if (!_isPausedState && (_blurEffectView.superview == self)) {
        [_blurEffectView removeFromSuperview];
        [_titleLabel setHidden:YES];
        [_scoreLabel setHidden:YES];
        [_timeLabel setHidden:YES];
        [_scoreTitleLabel setHidden:YES];
    } else {
        NSLog(@"How did play pause get here?????");
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    _lastTouchesBeganTimestamp = touch.timestamp;
    __block CGPoint location = [touch locationInView:self];
    __block CGPoint previous = [touch previousLocationInView:self];
    
    //NSLog(@"_originalFrame is %@", NSStringFromCGRect(_originalFrame));
    
    if (CGRectIsEmpty(_originalFrame)) {
        _originalFrame = self.frame;
    }
    
    if (!CGAffineTransformIsIdentity(self.transform)) {
        location = CGPointApplyAffineTransform(location, self.transform);
        previous = CGPointApplyAffineTransform(previous, self.transform);
    }
    
    //    self.frame = CGRectOffset(self.frame,
    //                              (location.x - previous.x),
    //                              (location.y - previous.y));
    
//    [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//        self.transform = CGAffineTransformMakeScale(0.6, 0.6);
//    } completion:^(BOOL finished) {
//        //NSLog(@"finished!");
//        [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
////            self.frame = CGRectOffset(self.frame,
////                                      (location.x - previous.x),
////                                      (location.y - previous.y));
//        } completion:^(BOOL finished) {
//            //NSLog(@"finished!");
//        }];
//    }];
    if (touch.tapCount == 1) {
        NSLog(@"play pause!");
        [self performSelector:@selector(togglePlayPause) withObject:nil afterDelay:0.2];
        //[self togglePlayPause];
    }
}

- (void)togglePlayPause
{
    if (!_startedMoving) {
        NSLog(@"PLAY PAUSE!");
        if ((_moviePlayer.playbackState == MPMoviePlaybackStatePaused) || (_moviePlayer.playbackState == MPMoviePlaybackStateStopped)) {
            [self playVideo];
        } else if (_moviePlayer.playbackState == MPMoviePlaybackStatePlaying) {
            [self pauseVideo];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    __block CGPoint location = [touch locationInView:self];
    __block CGPoint previous = [touch previousLocationInView:self];
    
    CGAffineTransform translateTransformTest = CGAffineTransformMakeTranslation(location.x-previous.x, location.y-previous.y);
    
    //CGAffineTransform translateTransform = CGAffineTransformTranslate(self.transform, location.x-previous.x, location.y-previous.y);
    
//    if (!CGAffineTransformIsIdentity(self.transform)) {
//        location = CGPointApplyAffineTransform(location, self.transform);
//        previous = CGPointApplyAffineTransform(previous, self.transform);
//    }
    
//    self.frame = CGRectOffset(self.frame,
//                              (location.x - previous.x),
//                              (location.y - previous.y));
    
    NSLog(@"----------------");
    NSLog(@"_lastTouchesBeganTimestamp %f", _lastTouchesBeganTimestamp);
    NSLog(@"touch.timestamp %f", touch.timestamp);
    NSLog(@"----------------");
    
    
    if (!_startedMoving) {
        [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.transform = CGAffineTransformMakeScale(0.6, 0.6);
        } completion:^(BOOL finished) {
            _startedMoving = YES;
            [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//                self.frame = CGRectOffset(self.frame,
//                                          (location.x - previous.x),
//                                          (location.y - previous.y));
                self.center = CGPointApplyAffineTransform(self.center, translateTransformTest);
            } completion:^(BOOL finished) {
                //NSLog(@"finished!");
            }];
        }];
    } else {
        [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//            self.frame = CGRectOffset(self.frame,
//                                      (location.x - previous.x),
//                                      (location.y - previous.y));
            self.center = CGPointApplyAffineTransform(self.center, translateTransformTest);
        } completion:^(BOOL finished) {
            //NSLog(@"finished!");
        }];
    }
    
//    [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
////        self.frame = CGRectOffset(self.frame,
////                                  (location.x - previous.x),
////                                  (location.y - previous.y));
//        self.center = CGPointApplyAffineTransform(self.center, translateTransformTest);
//    } completion:^(BOOL finished) {
//        //NSLog(@"finished!");
//    }];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
//    UITouch *touch = [touches anyObject];
//    __block CGPoint location = [touch locationInView:self];
//    __block CGPoint previous = [touch previousLocationInView:self];
    
//    if (!CGAffineTransformIsIdentity(self.transform)) {
//        location = CGPointApplyAffineTransform(location, self.transform);
//        previous = CGPointApplyAffineTransform(previous, self.transform);
//    }
    
//    if (self.frame.origin.y > (self.superview.frame.size.height * .25)) {
//        NSLog(@"one way");
//    } else if (self.frame.origin.y < (self.superview.frame.size.height * .75)) {
//        NSLog(@"other way");
//    }
    _startedMoving = NO;
    _lastTouchesBeganTimestamp = 0;
    
    __block BOOL didUpvote = NO;
    __block BOOL didDownvote = NO;
    __block CGRect finalFrame;
    if (self.frame.origin.y < (-self.superview.frame.size.height * UPPER_VOTE_THRESHOLD_FACTOR)) {
        NSLog(@"up");
        finalFrame = CGRectOffset(self.frame, 0, -400);
        didUpvote = YES;
    } else if (self.frame.origin.y > (self.superview.frame.size.height * LOWER_VOTE_THRESHOLD_FACTOR)) {
        NSLog(@"down");
        didDownvote = YES;
        finalFrame = CGRectOffset(self.frame, 0, 400);
    } else {
        finalFrame = _originalFrame;
    }
    
    [UIView animateWithDuration:0.2 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.transform = CGAffineTransformIdentity;
        self.frame = finalFrame;
    } completion:^(BOOL finished) {
        NSDictionary *userInfo = @{@"redditURL" : _redditURL};
        if (didUpvote) {
            [self pauseVideo];
            [[NSNotificationCenter defaultCenter] postNotificationName:VideoPlayerViewPassedUpvoteThreshold object:self userInfo:userInfo];
        } else if (didDownvote) {
            [self pauseVideo];
            [[NSNotificationCenter defaultCenter] postNotificationName:VideoPlayerViewPassedDownvoteThreshold object:self userInfo:userInfo];
        }
        didDownvote = NO;
        didUpvote = NO;
        //NSLog(@"finished!");
        // would be cool if it resized after moving as opposed to while moving
//        [UIView animateWithDuration:0.2 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//            self.transform = CGAffineTransformIdentity;
//        } completion:^(BOOL finished) {
//            //NSLog(@"finished");
//        }];
    }];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    _lastTouchesBeganTimestamp = 0;
    _startedMoving = NO;
    UITouch *touch = [touches anyObject];
    __block CGPoint location = [touch locationInView:self];
    __block CGPoint previous = [touch previousLocationInView:self];
    
    if (!CGAffineTransformIsIdentity(self.transform)) {
        location = CGPointApplyAffineTransform(location, self.transform);
        previous = CGPointApplyAffineTransform(previous, self.transform);
    }
    
    [UIView animateWithDuration:0.2 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.transform = CGAffineTransformIdentity;
        self.frame = _originalFrame;
    } completion:^(BOOL finished) {
        //NSLog(@"finished!");
    }];
}

@end
