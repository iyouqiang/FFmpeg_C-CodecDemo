//
//  ViewController.m
//  Yochi_FFmpeg_AudioEncode
//
//  Created by Yochi·Kung on 2017/12/13.
//  Copyright © 2017年 gongyouqiang. All rights reserved.
//

#import "ViewController.h"
#import "FFmpegAudioEncode.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    NSString *inPath=[[NSBundle mainBundle] pathForResource:@"Test" ofType:@"pcm"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,

                                                         NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *tmpPath = [path stringByAppendingPathComponent:@"temp"];
    [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:NULL];
    NSString* outFilePath = [tmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Test.aac"]];

    [FFmpegAudioEncode ffmpegAudioEncode:inPath outFilePath:outFilePath];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end