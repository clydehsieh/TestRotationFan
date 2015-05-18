//
//  ViewController.m
//  TestRotationFan
//
//  Created by Chin-Hui Hsieh  on 5/17/15.
//  Copyright (c) 2015 Chin-Hui Hsieh. All rights reserved.
//

#import "ViewController.h"
#define ALPHA 0.05
#define LOW_PASS 0.75



@interface ViewController () <AVAudioRecorderDelegate>
{
    NSTimer *levelTimer;
    double currentAngle;
    int times;
}

@property (weak, nonatomic) IBOutlet UIImageView *fan;
@property (strong,nonatomic) AVAudioRecorder *recorder;



@end

@implementation ViewController
@synthesize fan;
@synthesize recorder;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSError *error;
    
    NSArray *pathComponent = [NSArray arrayWithObjects:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], @"myAudioMemo", nil];
    NSURL  *url = [NSURL fileURLWithPathComponents:pathComponent];
    
    //set audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat:4100.0],AVSampleRateKey,
                              [NSNumber numberWithInt:kAudioFormatAppleLossless],AVFormatIDKey,
                              [NSNumber numberWithInt:1],AVNumberOfChannelsKey,
                              [NSNumber numberWithInt:AVAudioQualityMax],AVEncoderAudioQualityKey,
                              nil ];
    
    recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    
    recorder.meteringEnabled = YES;
    
    recorder.delegate = self;
    
    [recorder prepareToRecord];

    
}
 


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//過濾高頻
- (void) audioLevelTimerCallback:(NSTimer *) timer
{
    
    [recorder updateMeters];
    
    if (recorder.recording)
    {
        double peakPowerForChannel = pow(10,ALPHA *[recorder peakPowerForChannel:0]);
        double filteredLowPass;
        filteredLowPass = (ALPHA * peakPowerForChannel+ (1-ALPHA) * filteredLowPass);
        
        // 過濾掉非吹氣的聲音，自行調整範圍值
        if( filteredLowPass>0.001 && filteredLowPass<0.03){
            // 旋轉風扇
            [self rotateFan:fan
                    toAngle:(filteredLowPass-LOW_PASS)/(1-LOW_PASS)*2*M_PI];

        }
    }
}

//吹氣旋轉
-(void) rotateFan:(UIImageView *) fanImage toAngle:(float) angle
{
  
    [UIView beginAnimations:@"rotate_fan" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:5*angle/(2*M_PI)];
   
    //set point of rotation
    fanImage.center = CGPointMake(self.view.frame.size.width/2 , self.view.frame.size.height/2);
    
    currentAngle += angle;
    fanImage.transform =
    CGAffineTransformMakeRotation(currentAngle);
    [UIView commitAnimations];
}



- (IBAction)rotateFanByBtn:(id)sender
{
    if (recorder.recording) {
        [recorder stop];
        NSLog(@"STOPPED");
    }else
    {
        [recorder record];
        NSLog(@"STARTED");
        levelTimer = [NSTimer
                      scheduledTimerWithTimeInterval:0.03
                      target:self selector:@selector(audioLevelTimerCallback:) userInfo:
                      nil repeats:YES];
    }
}


@end












