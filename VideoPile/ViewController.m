//
//  ViewController.m
//  VideoPile
//
//  Created by Jordan Zucker on 10/24/14.
//  Copyright (c) 2014 Jordan Zucker. All rights reserved.
//

#import "ViewController.h"
#import <RedditKit/RedditKit.h>
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <HCYoutubeParser/HCYoutubeParser.h>
#import "VideoPlayerView.h"
@import MediaPlayer;

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *topLinks;
@property (nonatomic, strong) UIDynamicAnimator *animator;
//@property (nonatomic, weak) IBOutlet UIView *playerView;
//@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, weak) IBOutlet VideoPlayerView *playerView;
@property (nonatomic, weak) IBOutlet UIImageView *backgroundView;
@property (nonatomic) CGPoint originalCenter;
@property (nonatomic, strong) UIView *tintView;
@property (nonatomic, strong) UIImageView *maskImageView;
@property (nonatomic, assign) BOOL didVote;
@property (nonatomic, assign) BOOL didUpvote;
@property (nonatomic, assign) BOOL didDownvote;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    _topLinks = [[NSMutableArray alloc] init];
    
    _originalCenter = _playerView.center;
    
    _tintView = [[UIView alloc] initWithFrame:_playerView.frame];
    
//    CALayer *maskLayer = [CALayer layer];
//    maskLayer.contents = (id)[UIImage imageNamed:@"2000px-Orange_logo.svg.png"].CGImage;

    
//    _tintView.opaque = NO;
    
    //_tintView.alpha = 0.5;
    
    [_tintView setTintColor:[UIColor orangeColor]];
    
    _maskImageView = [[UIImageView alloc] initWithFrame:_playerView.frame];
    
    //[_playerView setMaskView:_tintView];
    
    [[RKClient sharedClient] signInWithUsername:@"hacksesh" password:@"hacksesh" completion:^(NSError *error) {
        if (error) {
            NSLog(@"successfully signed in");
        }
    }];
    
    __block RKSubreddit *videosSubreddit;
    
    [[RKClient sharedClient] subredditWithName:@"videos" completion:^(id object, NSError *error) {
        if (error) {
            NSLog(@"error!");
        }
        NSLog(@"object is %@", object);
        videosSubreddit = (RKSubreddit *)object;
        
        NSLog(@"videos subreddit name is %@", videosSubreddit.name);
    }];
    
//    [[RKClient sharedClient] linksInSubreddit:videosSubreddit pagination:nil completion:^(NSArray *links, RKPagination *pagination, NSError *error) {
//        NSLog(@"Links: %@", links);
//    }];
    [[RKClient sharedClient] linksInSubredditWithName:@"videos" pagination:nil completion:^(NSArray *collection, RKPagination *pagination, NSError *error) {
        NSLog(@"collection is %@", collection);
        _topLinks = [collection mutableCopy];
        //RKLink *link = (RKLink *)[collection firstObject];
        //[_playerView setVideo:link.URL];
        [self setVideo];
    }];
}

- (void)upvote
{
    [[RKClient sharedClient] upvote:[_topLinks firstObject] completion:^(NSError *error) {
        NSLog(@"upvote!");
    }];
}

- (void)downvote
{
    [[RKClient sharedClient] downvote:[_topLinks firstObject] completion:^(NSError *error) {
        NSLog(@"downvote!");
    }];
}

- (NSString *)extractYoutubeID:(NSString *)youtubeURL
{
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(?<=v(=|/))([-a-zA-Z0-9_]+)|(?<=youtu.be/)([-a-zA-Z0-9_]+)" options:NSRegularExpressionCaseInsensitive error:&error];
    NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:youtubeURL options:0 range:NSMakeRange(0, [youtubeURL length])];
    if(!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0)))
    {
        NSString *substringForFirstMatch = [youtubeURL substringWithRange:rangeOfFirstMatch];
        
        return substringForFirstMatch;
    }
    return nil;
}

- (void)setVideo
{
    //[_topLinks removeObjectAtIndex:0];
    RKLink *link = [_topLinks firstObject];
    
    [_playerView setVideo:link.URL];
    
    [self setVideoThumbnailForBackgroundView:[_topLinks objectAtIndex:1]];
    
    _playerView.center = _originalCenter;
}

- (void)updateTopLinks
{
    [_topLinks removeObjectAtIndex:0];
}

- (void)setVideoThumbnailForBackgroundView:(RKLink *)link
{
    NSString *youtubeID = [self extractYoutubeID:[link.URL absoluteString]];
    
    NSLog(@"youtubeID is %@", youtubeID);
    
    NSString *youtubeThumbnailURLString = [NSString stringWithFormat:@"http://img.youtube.com/vi/%@/1.jpg", youtubeID];
    
    NSURL *url = [NSURL URLWithString:youtubeThumbnailURLString];
    
    [_backgroundView setImageWithURL:url placeholderImage:nil];
    
    //
    //    UIVisualEffect *blurEffect;
    //    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    //
    //    UIVisualEffectView *visualEffectView;
    //    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    //
    //    visualEffectView.frame = _imageView.bounds;
    //    [_imageView addSubview:visualEffectView];
}

- (void)setVideoThumbnail:(RKLink *)link
{
//    NSString *youtubeID = [self extractYoutubeID:[link.URL absoluteString]];
//    
//    NSLog(@"youtubeID is %@", youtubeID);
//    
//    NSString *youtubeThumbnailURLString = [NSString stringWithFormat:@"http://img.youtube.com/vi/%@/1.jpg", youtubeID];
//    
//    NSURL *url = [NSURL URLWithString:youtubeThumbnailURLString];
//    
//    [_imageView setImageWithURL:url placeholderImage:nil];
//    
//    UIVisualEffect *blurEffect;
//    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
//    
//    UIVisualEffectView *visualEffectView;
//    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
//    
//    visualEffectView.frame = _imageView.bounds;
//    [_imageView addSubview:visualEffectView];
    
    // Gets an dictionary with each available youtube url
    //NSDictionary *videos = [HCYoutubeParser h264videosWithYoutubeURL:link.URL];
    
//    // Presents a MoviePlayerController with the youtube quality medium
//    _moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:[videos objectForKey:@"medium"]]];
//    _moviePlayer.view.frame = _playerView.frame;
//    //[_moviePlayer.view setTintColor:[UIColor orangeColor]];
//    _moviePlayer.scalingMode = MPMovieScalingModeNone;
//    _moviePlayer.controlStyle = MPMovieControlStyleNone;
//    //MPMoviePlayerViewController *mp = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:[videos objectForKey:@"medium"]]];
//    //[self presentMoviePlayerViewControllerAnimated:mp];
//    [_playerView addSubview:_moviePlayer.view];
    
//    CALayer *maskLayer = [CALayer layer];
//    maskLayer.contents = (id)[UIImage imageNamed:@"2000px-Orange_logo.svg.png"].CGImage;
//    
//    maskLayer.opacity = 0.5;
//    
//    [_playerView.layer insertSublayer:maskLayer atIndex:0];
    //_playerView.layer.mask = maskLayer;

    //[_moviePlayer performSelector:@selector(play) withObject:nil afterDelay:5];
    
//    // To get a thumbnail for an image there is now a async method for that
//    [HCYoutubeParser thumbnailForYoutubeURL:url
//                              thumbnailSize:YouTubeThumbnailDefaultHighQuality
//                              completeBlock:^(UIImage *image, NSError *error) {
//                                  if (!error) {
//                                      //self.thumbailImageView.image = image;
//                                  }
//                                  else {
//                                      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
//                                      [alert show];
//                                  }
//                              }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
//    UITouch *touch = [touches anyObject];
//    CGPoint location = [touch locationInView:self.view];
//    [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
//        _imageView.center = location;
//    } completion:^(BOOL finished) {
//        NSLog(@"complete!");
//    }];
    _didDownvote = NO;
    _didUpvote = NO;
    _didVote = NO;
//    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//        <#code#>
//    } completion:^(BOOL finished) {
//        <#code#>
//    }];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
//    UITouch *touch = [touches anyObject];
//    if (touch.view == _playerView) {
//        __block CGPoint location = [touch locationInView:self.view];
//        __block CGPoint lastLocation = [touch previousLocationInView:self.view];
//        NSLog(@"touches is %@", touches);
//        
//        _didVote = NO;
//        _didDownvote = NO;
//        _didUpvote = NO;
//        
//        if (!CGAffineTransformIsIdentity(_playerView.transform)) {
//            location = CGPointApplyAffineTransform(location, _playerView.transform);
//            lastLocation = CGPointApplyAffineTransform(lastLocation, _playerView.transform);
//        }
//        
//        _playerView.frame = CGRectOffset(_playerView.frame,
//                                  (location.x - lastLocation.x),
//                                  (location.y - lastLocation.y));
//        [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//            if (_playerView.center.y > (self.view.frame.size.height * 0.75)) {
//                NSLog(@"shwinggggggggggg low");
//                _didVote = YES;
//                _didDownvote = YES;
//            } else if (_playerView.center.y < (self.view.frame.size.height * 0.25)) {
//                NSLog(@"dammmmmmmmmmmmmm high");
//                _didVote = YES;
//                _didUpvote = YES;
//            } else {
//                //_playerView.center = location;
//                //_playerView.transform = CGAffineTransformMakeTranslation(location.x-lastLocation.x, location.y-lastLocation.y);
//                if (!CGAffineTransformIsIdentity(_playerView.transform)) {
//                    location = CGPointApplyAffineTransform(location, _playerView.transform);
//                    lastLocation = CGPointApplyAffineTransform(lastLocation, _playerView.transform);
//                }
//                
//                _playerView.frame = CGRectOffset(_playerView.frame,
//                                          (location.x - lastLocation.x),
//                                          (location.y - lastLocation.y));
//            }
//        } completion:^(BOOL finished) {
//            //        if (_didVote) {
//            //            NSLog(@"didVote touchesMoved");
//            //            [UIView animateWithDuration:1.0 delay:0.1 options:UIViewAnimationOptionCurveEaseIn animations:^{
//            //                if (_didUpvote) {
//            //                    _playerView.center = CGPointMake(_playerView.center.x, -600);
//            //                } else if (_didDownvote) {
//            //                    _playerView.center = CGPointMake(_playerView.center.x, 900);
//            //                } else {
//            //                    NSLog(@"else");
//            //                }
//            //            } completion:^(BOOL finished) {
//            //                NSLog(@"finished!");
//            //                _didVote = NO;
//            //                _didUpvote = NO;
//            //                _didDownvote = NO;
//            //            }];
//            //        }
//        }];
//    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //UITouch *touch = [touches anyObject];
//    NSLog(@"touchesEnded");
//    [UIView animateWithDuration:0.5 delay:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//        if (!_didVote) {
//            NSLog(@"did not vote in touchesEnded");
//            _playerView.transform = CGAffineTransformIdentity;
//            _playerView.center = _originalCenter;
//        } else {
//            NSLog(@"didVote touchesEnded");
//            [_playerView.moviePlayer stop];
//            [UIView animateWithDuration:0.2 delay:0.1 options:UIViewAnimationOptionCurveEaseIn animations:^{
//                if (_didUpvote) {
//                    _playerView.center = CGPointMake(_playerView.center.x, -600);
//                    [self upvote];
//                } else if (_didDownvote) {
//                    _playerView.center = CGPointMake(_playerView.center.x, 900);
//                    [self downvote];
//                } else {
//                    NSLog(@"else");
//                }
//            } completion:^(BOOL finished) {
//                NSLog(@"finished!");
//                _didVote = NO;
//                _didUpvote = NO;
//                _didDownvote = NO;
//                [self updateTopLinks];
//                [self setVideo];
//            }];
//        }
//    } completion:^(BOOL finished) {
//        NSLog(@"finished!");
//    }];
    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"TOUCHES CANCELED!!!!!!!!");
}

@end
