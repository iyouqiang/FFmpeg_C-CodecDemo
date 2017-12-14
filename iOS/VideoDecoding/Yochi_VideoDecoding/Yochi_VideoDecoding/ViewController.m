//
//  ViewController.m
//  Yochi_VideoDecoding
//
//  Created by Yochi·Kung on 2017/12/5.
//  Copyright © 2017年 gongyouqiang. All rights reserved.
//

#import "ViewController.h"
#import "FFmpegVideoDecoding.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    NSString * intFilePath = [[NSBundle mainBundle] pathForResource:@"Test" ofType:@"mov"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,

                                                         NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *tmpPath = [path stringByAppendingPathComponent:@"temp"];
    [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:NULL];
    NSString* tempPathFile = [tmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Test.yuv"]];
    [FFmpegVideoDecoding FFmpegVideoDecoding:intFilePath outFilePath:tempPathFile];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
