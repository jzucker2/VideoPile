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
@property (nonatomic, weak) IBOutlet UILabel *scoreTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *scoreLabel;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDownvoteNotification:) name:VideoPlayerViewPassedDownvoteThreshold object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpvoteNotification:) name:VideoPlayerViewPassedUpvoteThreshold object:nil];
    
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    _topLinks = [[NSMutableArray alloc] init];
    
    _originalCenter = _playerView.center;
    
    _tintView = [[UIView alloc] initWithFrame:_playerView.frame];
    
    _backgroundView.userInteractionEnabled = NO;
    
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
    
    [[RKClient sharedClient] linksInSubredditWithName:@"videos" pagination:nil completion:^(NSArray *collection, RKPagination *pagination, NSError *error) {
        NSLog(@"collection is %@", collection);
        _topLinks = [collection mutableCopy];
        //RKLink *link = (RKLink *)[collection firstObject];
        //[_playerView setVideo:link.URL];
        [self setVideo];
    }];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VideoPlayerViewPassedDownvoteThreshold object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VideoPlayerViewPassedUpvoteThreshold object:nil];
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

- (void)handleUpvoteNotification:(NSNotification *)notification
{
    [self upvote];
    [self updateTopLinks];
    [self setVideo];
}

- (void)handleDownvoteNotification:(NSNotification *)notification
{
    [self downvote];
    [self updateTopLinks];
    [self setVideo];
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
    
    [_playerView pauseVideo];
    
    [_playerView setVideo:link];
    
    [self setVideoThumbnailForBackgroundView:[_topLinks objectAtIndex:1]];
    
    //_playerView.center = _originalCenter;
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
    
    _scoreLabel.text = [NSString stringWithFormat:@"%ld", link.score];
    _titleLabel.text = link.title;
    
    
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    visualEffectView.frame = _backgroundView.bounds;
    [_backgroundView addSubview:visualEffectView];
    
    [_backgroundView bringSubviewToFront:_scoreTitleLabel];
    [_backgroundView bringSubviewToFront:_titleLabel];
    [_backgroundView bringSubviewToFront:_scoreLabel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}
@end
