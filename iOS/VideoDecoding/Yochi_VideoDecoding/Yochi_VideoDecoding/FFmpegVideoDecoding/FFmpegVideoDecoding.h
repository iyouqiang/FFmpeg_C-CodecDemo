//
//  FFmpegVideoDecoding.h
//  Yochi_VideoDecoding
//
//  Created by Yochi·Kung on 2017/12/5.
//  Copyright © 2017年 gongyouqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>
#include <libavutil/imgutils.h>
#include <libswscale/swscale.h>

@interface FFmpegVideoDecoding : NSObject

+ (void)FFmpegVideoDecoding:(NSString *)inFilePath outFilePath:(NSString *)outFiulePath;

@end
