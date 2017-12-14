//
//  ViewController.m
//  Yochi_FFmpeg_VideoEncoding
//
//  Created by Yochi·Kung on 2017/12/7.
//  Copyright © 2017年 gongyouqiang. All rights reserved.
//

#import "ViewController.h"
#import "FFmpegVideoEncoding.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    NSString* inPath = [[NSBundle mainBundle] pathForResource:@"Test" ofType:@"yuv"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                    NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *tmpPath = [path stringByAppendingPathComponent:@"temp"];
    [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:NULL];
    NSString* outFilePath = [tmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Test.h264"]];
    [FFmpegVideoEncoding ffmpegVideoEncode:inPath outFilePath:outFilePath];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
