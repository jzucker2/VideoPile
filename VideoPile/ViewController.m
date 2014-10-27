//
//  ViewController.m
//  VideoPile
//
//  Created by Jordan Zucker on 10/24/14.
//  Copyright (c) 2014 Jordan Zucker. All rights reserved.
//

#import "ViewController.h"
#import "VideoImageView.h"
#import <RedditKit/RedditKit.h>
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *topLinks;
@property (nonatomic, strong) IBOutlet VideoImageView *imageView;
@property (nonatomic, strong) UIDynamicAnimator *animator;

@end

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

- (void)setVideoThumbnail:(RKLink *)link
{
    NSString *youtubeID = [self extractYoutubeID:[link.URL absoluteString]];
    
    NSLog(@"youtubeID is %@", youtubeID);
    
    NSString *youtubeThumbnailURLString = [NSString stringWithFormat:@"http://img.youtube.com/vi/%@/1.jpg", youtubeID];
    
    NSURL *url = [NSURL URLWithString:youtubeThumbnailURLString];
    
    [_imageView setImageWithURL:url placeholderImage:nil];
    
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    visualEffectView.frame = _imageView.bounds;
    [_imageView addSubview:visualEffectView];
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
}

@end
