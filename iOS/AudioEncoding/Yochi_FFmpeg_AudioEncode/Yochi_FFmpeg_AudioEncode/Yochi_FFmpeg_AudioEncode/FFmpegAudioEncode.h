//
//  FFmpegAudioEncode.h
//  Yochi_FFmpeg_AudioEncode
//
//  Created by Yochi·Kung on 2017/12/13.
//  Copyright © 2017年 gongyouqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

//导入音视频头文件库
//核心库
#include "libavcodec/avcodec.h"
//封装格式处理库
#include "libavformat/avformat.h"
//工具库
#include "libavutil/imgutils.h"

@interface FFmpegAudioEncode : NSObject

//音频编码
+ (void)ffmpegAudioEncode:(NSString*)inFilePath outFilePath:(NSString*)outFilePath;

@end
