//
//  FFmpegVideoEncoding.h
//  Yochi_FFmpeg_VideoEncoding
//
//  Created by Yochi·Kung on 2017/12/7.
//  Copyright © 2017年 gongyouqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

//核心库
#include "libavcodec/avcodec.h"
//封装格式处理库
#include "libavformat/avformat.h"
//工具库
#include "libavutil/imgutils.h"

@interface FFmpegVideoEncoding : NSObject
//FFmpeg视频编码
+(void)ffmpegVideoEncode:(NSString*)jinFilePath outFilePath:(NSString*)joutFilePath;

@end
