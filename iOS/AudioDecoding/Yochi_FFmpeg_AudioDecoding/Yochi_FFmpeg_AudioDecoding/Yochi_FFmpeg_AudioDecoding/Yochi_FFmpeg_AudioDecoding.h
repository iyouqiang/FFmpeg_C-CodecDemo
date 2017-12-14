//
//  Yochi_FFmpeg_AudioDecoding.h
//  Yochi_FFmpeg_AudioDecoding
//
//  Created by Yochi·Kung on 2017/12/13.
//  Copyright © 2017年 gongyouqiang. All rights reserved.
//

#import <Foundation/Foundation.h>


//核心库
#include "libavcodec/avcodec.h"
//封装格式处理库
#include "libavformat/avformat.h"
//工具库
#include "libavutil/imgutils.h"
//音频采样数据格式库
#include "libswresample/swresample.h"

@interface Yochi_FFmpeg_AudioDecoding : NSObject

+ (void)ffmpeg_AudioDecodinginFile:(NSString *)inFile outFile:(NSString*)outFile;

@end
