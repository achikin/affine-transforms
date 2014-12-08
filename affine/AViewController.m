//
//  AViewController.m
//  affine
//
//  Created by Anton Chikin on 8/24/14.
//  Copyright (c) 2014 chikin. All rights reserved.
//

#import "AViewController.h"
#import <AVFoundation/AVFoundation.h>
@interface AViewController ()
@property CGFloat angle;
@property CGPoint prevPosition;
@property (nonatomic,strong) AVAudioPlayer *player;
@property CGFloat currentScale;
@end

@implementation AViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void) willEnterForeground {
    [self reset];
}

- (void) viewWillAppear:(BOOL) animated {
    [self reset];
}

//subview is a superview for textview
//pay attention how I rotate textview by changing sublayerTransformation property later on
- (void) setupSubview {
    self.angle = 0.0f;
    self.subview.backgroundColor = [UIColor clearColor];
    //change anchor point to rotate around the bottom of the view, not center
    self.subview.layer.anchorPoint = CGPointMake(0.5f, 1.0f);
    //reset view position, that has changed after changing anchor
    //tldr reset frame.origin.y to 0
    CGRect frame = self.subview.frame;
    frame.origin = CGPointMake(frame.origin.x, 0);
    self.subview.frame = frame;
    //reset view rotation to 0 degrees
    [self rotateViewToAngle:self.angle];
}

- (void) setupTextView {
    //Let textview resize to fit it's content
    self.textview.scrollEnabled = YES;
    [self.textview sizeToFit];
    self.textview.scrollEnabled = NO;
    
    self.textview.backgroundColor = [UIColor clearColor];
    //move text view below the bottom edge of the screen
    self.textview.frame = CGRectMake(self.textview.frame.origin.x, self.subview.frame.size.height, self.textview.frame.size.width, self.textview.frame.size.height);
}

- (void) beginTextViewAnimation {
    //this animation moves textview from the bottom of the screen to the top of the screen
    //simulating slow scrolling effect
    //for some reasons scrollview screws up it contents when I try to animate contentOffset
    CGSize tvsize = self.textview.frame.size;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:50.0f];
    self.textview.frame = CGRectMake(self.textview.frame.origin.x, -self.textview.frame.size.height, tvsize.width, tvsize.height);
    [UIView commitAnimations];
}

- (void) startMusic {
    NSString *mp3Path = [[NSBundle mainBundle]
                         pathForResource:@"8df58425d25401" ofType:@"mp3"];
    NSURL *music = [NSURL fileURLWithPath:mp3Path];
    NSError *error;
    
    self.player = [[AVAudioPlayer alloc]
                   initWithContentsOfURL:music error:&error];
    [self.player prepareToPlay];
    [self.player play];
}

- (void) setupImageView {
    //Imageview scales and translates during user interaction simultaiousely
    //Here I place it above the top edge of the screen and scale x10 to shrink later
    self.currentScale = 10.0f;
    self.imageView.transform = CGAffineTransformMakeScale(self.currentScale, self.currentScale);
    self.imageView.frame = CGRectMake(self.imageView.frame.origin.x, -self.imageView.frame.size.height, self.imageView.frame.size.width, self.imageView.frame.size.height);
}

- (void) reset {
    [self setupSubview];
    [self setupTextView];
    [self setupImageView];
    [self startMusic];
    [self beginTextViewAnimation];
}

- (CGFloat) acceleration {
    return 0.8f;
}
- (CGFloat) speed {
    return 0.1f;
}

- (void) rotateViewToAngle:(CGFloat) angle {
    //The core of the whole sample
    //m34 == -1/D where D is distance from camera to rotating object
    CATransform3D rotationAndPerspectiveTransform = CATransform3DIdentity;
    rotationAndPerspectiveTransform.m34 = 1.0 / -200;
    rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, angle * M_PI / 180.0f, 1.0f, 0.0f, 0.0f);
    self.subview.layer.sublayerTransform = rotationAndPerspectiveTransform;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.prevPosition = [[touches anyObject] locationInView:self.view];
    NSLog(@"Touches begun");
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    CGPoint pos = [[touches anyObject] locationInView:self.view];
    CGFloat ydiff = pos.y - self.prevPosition.y;
    NSLog(@"%f", ydiff);
    NSLog(@"%f", self.angle);
    if (self.angle + ydiff*self.acceleration*self.speed < -10.0f) {
        return;
    }
    self.currentScale-=ydiff/(3/self.speed);
    if (self.currentScale <= 0.7f) {
        self.currentScale = 0.7f;
    } else {
        self.prevPosition = pos;
        self.angle = self.angle + ydiff*self.acceleration*self.speed;
        [self rotateViewToAngle:self.angle];
        
        self.imageView.transform = CGAffineTransformMakeScale(self.currentScale, self.currentScale);
        self.imageView.frame = CGRectMake(self.imageView.frame.origin.x, self.imageView.frame.origin.y + ydiff*30*self.speed, self.imageView.frame.size.width, self.imageView.frame.size.height);
    }
}

@end
