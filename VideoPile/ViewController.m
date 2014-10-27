//
//  ViewController.m
//  VideoPile
//
//  Created by Jordan Zucker on 10/24/14.
//  Copyright (c) 2014 Jordan Zucker. All rights reserved.
//

#import "ViewController.h"
#import "VideoImageView.h"
#import "PlayerView.h"
#import <RedditKit/RedditKit.h>
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
@import AVFoundation;

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *topLinks;
//@property (nonatomic, strong) IBOutlet VideoImageView *imageView;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) NSURL *videoURL;

@end

static void *AVPlayerDemoPlaybackViewControllerRateObservationContext = &AVPlayerDemoPlaybackViewControllerRateObservationContext;
static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;
static void *AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext = &AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    _topLinks = [[NSMutableArray alloc] init];
    
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
        [self setVideoThumbnail:[collection firstObject]];
        [self setCurrentVideoURL:[collection firstObject]];
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

- (void)setCurrentVideoURL:(RKLink *)link
{
    NSString *youtubeID = [self extractYoutubeID:[link.URL absoluteString]];
    
    NSLog(@"youtubeID is %@", youtubeID);
    
    NSString *youtubeThumbnailURLString = [NSString stringWithFormat:@"http://img.youtube.com/vi/%@/1.jpg", youtubeID];
    
    NSURL *url = [NSURL URLWithString:youtubeThumbnailURLString];
    
    [self setURL:url];
}

- (void)setVideoThumbnail:(RKLink *)link
{
    //NSString *youtubeID = [self extractYoutubeID:[link.URL absoluteString]];
    
    //NSLog(@"youtubeID is %@", youtubeID);
    
    //NSString *youtubeThumbnailURLString = [NSString stringWithFormat:@"http://img.youtube.com/vi/%@/1.jpg", youtubeID];
    
    //NSURL *url = [NSURL URLWithString:youtubeThumbnailURLString];
    
    //[_imageView setImageWithURL:url placeholderImage:nil];
    
    //UIVisualEffect *blurEffect;
    //blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    
    //UIVisualEffectView *visualEffectView;
    //visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    //visualEffectView.frame = _imageView.bounds;
    //[_imageView addSubview:visualEffectView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

#pragma mark - Video

+ (AVAsset*)getAVAssetFromRemoteUrl:(NSURL*)url
{
    if (!NSTemporaryDirectory())
    {
        // no tmp dir for the app (need to create one)
    }
    
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:@"temp"] URLByAppendingPathExtension:@"mp4"];
    NSLog(@"fileURL: %@", [fileURL path]);
    
    NSData *urlData = [NSData dataWithContentsOfURL:url];
    [urlData writeToURL:fileURL options:NSAtomicWrite error:nil];
    
    AVAsset *asset = [AVAsset assetWithURL:fileURL];
    return asset;
}

- (void)setURL:(NSURL*)URL
{
    if (_videoURL != URL)
    {
        _videoURL = URL;
        
        /*
         Create an asset for inspection of a resource referenced by a given URL.
         Load the values for the asset key "playable".
         */
        AVAsset *asset = [ViewController getAVAssetFromRemoteUrl:_videoURL];
        
        NSArray *requestedKeys = @[@"playable"];
        
        /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
        [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
         ^{
             dispatch_async( dispatch_get_main_queue(),
                            ^{
                                /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
                                [self prepareToPlayAsset:asset withKeys:requestedKeys];
                            });
         }];
    }
}

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVAsset *)asset withKeys:(NSArray *)requestedKeys
{
    /* Make sure that the value of each key has loaded successfully. */
    for (NSString *thisKey in requestedKeys)
    {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed)
        {
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
        /* If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation. */
    }
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable)
    {
        /* Generate an error describing the failure. */
        NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
        NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   localizedDescription, NSLocalizedDescriptionKey,
                                   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
                                   nil];
        NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
    
    /* At this point we're ready to set up for playback of the asset. */
    
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (_playerItem)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [_playerItem removeObserver:self forKeyPath:@"status"];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:_playerItem];
    }
    
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    _playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    /* Observe the player item "status" key to determine when it is ready to play. */
    [_playerItem addObserver:self
                       forKeyPath:@"status"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
    
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:_playerItem];
    
    //seekToZeroBeforePlay = NO;
    
    /* Create new player, if we don't already have one. */
    if (!_player)
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        [self setPlayer:[AVPlayer playerWithPlayerItem:_playerItem]];
        
        /* Observe the AVPlayer "currentItem" property to find out when any
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
         occur.*/
        [self.player addObserver:self
                      forKeyPath:@"currentItem"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self
                      forKeyPath:@"rate"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerDemoPlaybackViewControllerRateObservationContext];
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.player.currentItem != _playerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs
         asynchronously; observe the currentItem property to find out when the
         replacement will/did occur
         
         If needed, configure player item here (example: adding outputs, setting text style rules,
         selecting media options) before associating it with a player
         */
        [_player replaceCurrentItemWithPlayerItem:_playerItem];
        
        //[self syncPlayPauseButtons];
    }
}

/* --------------------------------------------------------------
**  Called when an asset fails to prepare for playback for any of
**  the following reasons:
**
**  1) values of asset keys did not load successfully,
**  2) the asset keys did load successfully, but the asset is not
**     playable
**  3) the item did not become ready to play.
** ----------------------------------------------------------- */

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
//    [self removePlayerTimeObserver];
//    [self syncScrubber];
//    [self disableScrubber];
//    [self disablePlayerButtons];
    
    /* Display the error. */
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                        message:[error localizedFailureReason]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

/* Called when the player item has played to its end time. */
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    /* After the movie has played to its end time, seek back to time zero
     to play it again. */
    //seekToZeroBeforePlay = YES;
}


#pragma mark - Animations

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
//    UITouch *touch = [touches anyObject];
//    CGPoint location = [touch locationInView:self.view];
//    [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
//        _imageView.center = location;
//    } completion:^(BOOL finished) {
//        NSLog(@"complete!");
//    }];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
//                         CGAffineTransform scaleTrans =
//                         CGAffineTransformMakeScale(2, 2);
//                         
//                         _boxView.transform = scaleTrans;
                         _playerView.center = location;
                     } completion:nil];
}

@end
