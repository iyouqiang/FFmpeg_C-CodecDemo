//
//  Yochi_FFmpeg_AudioDecoding.m
//  Yochi_FFmpeg_AudioDecoding
//
//  Created by Yochi·Kung on 2017/12/13.
//  Copyright © 2017年 gongyouqiang. All rights reserved.
//

#import "Yochi_FFmpeg_AudioDecoding.h"

@implementation Yochi_FFmpeg_AudioDecoding

+ (void)ffmpeg_AudioDecodinginFile:(NSString *)inFile outFile:(NSString*)outFile
{
    /**第一步：组册组件*/
    av_register_all();

    /** 第二步：打开封装格式->打开文件 */
    //作用：保存整个视频信息(解码器、编码器等等...)
    //信息：码率、帧率等...
    AVFormatContext* avformat_context = avformat_alloc_context();

    const char *url = [inFile UTF8String];

    int avformat_open_input_result = avformat_open_input(&avformat_context, url, NULL, NULL);

    if (avformat_open_input_result != 0){

        NSLog(@"打开文件失败");
        return;
    }

    NSLog(@"打开文件成功");

    /** 第三步：拿到视频基本信息 */
    int avformat_find_stream_info_result = avformat_find_stream_info(avformat_context, NULL);
    if (avformat_find_stream_info_result < 0){

        NSLog(@"查找失败");
        return;
    }

    /** 第四步查找音频解码器 */
    //第一点：查找音频流索引位置
    int av_stream_index = -1;
    for (int i = 0; i < avformat_context->nb_streams; ++i) {
        //判断是否是音频流
        if (avformat_context->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO){
            //AVMEDIA_TYPE_AUDIO->表示音频类型
            av_stream_index = i;
            break;
        }
    }

    //第二点：获取音频解码器上下文
    AVCodecContext * avcodec_context = avformat_context->streams[av_stream_index]->codec;

    //第三点：获得音频解码器
    AVCodec *avcodec = avcodec_find_decoder(avcodec_context->codec_id);
    if (avcodec == NULL){

        NSLog(@"查找音频解码器失败");
        return;
    }

    /**第五步：打开音频解码器*/
    int avcodec_open2_result = avcodec_open2(avcodec_context, avcodec, NULL);
    if (avcodec_open2_result != 0){

        NSLog(@"打开音频解码器失败");
        return;
    }

    /**第六步：读取音频压缩数据->循环读取*/

    //创建音频压缩数据帧->acc格式、mp3格式
    AVPacket* avpacket = (AVPacket*)av_malloc(sizeof(AVPacket));

    //创建音频采样数据帧
    AVFrame* avframe = av_frame_alloc();

    // 确保解码为pcm我们需要转换为pcm格式
    SwrContext* swr_context = swr_alloc();

    /**输出*/
    //立体声 输出声道布局类型(立体声、环绕声、机器人等等...)
    int64_t out_ch_layout = AV_CH_LAYOUT_STEREO;

    //输出采样精度->编码 例如：采样精度8位 = 1字节，采样精度16位 = 2字节
    //int out_sample_fmt = AV_SAMPLE_FMT_S16;
    enum AVSampleFormat out_sample_fmt = AV_SAMPLE_FMT_S16;//avcodec_context->sample_fmt;

    //输出采样率(44100HZ)
    int out_sample_rate = avcodec_context->sample_rate;

    /**输入*/
    //输入声道布局类型
    int64_t in_ch_layout = av_get_default_channel_layout(avcodec_context->channels);

    //输入采样精度
    enum AVSampleFormat in_sample_fmt = avcodec_context->sample_fmt;

    //输入采样率
    int in_sample_rate = avcodec_context->sample_rate;

    //log日志->从那里开始统计
    int log_offset = 0;

    //音频采样上下文->开辟了一块内存空间->pcm、MP3格式等...
    swr_alloc_set_opts(swr_context,
                       out_ch_layout,
                       out_sample_fmt,
                       out_sample_rate,
                       in_ch_layout,
                       in_sample_fmt,
                       in_sample_rate,
                       log_offset, NULL);

    //初始化音频采样数据上下文
    swr_init(swr_context);

    //缓冲区大小 = 采样率(44100HZ) * 采样精度(16位 = 2字节)
    int MAX_AUDIO_SIZE = 44100 * 2;
    uint8_t *out_buffer = (uint8_t *)av_malloc(MAX_AUDIO_SIZE);

    //输出声道数量 上面设置为立体声
    int out_nb_channels = av_get_channel_layout_nb_channels(out_ch_layout);

    int audio_decode_result = 0;

    //打开文件
    const char *coutFilePath = [outFile UTF8String];
    FILE* out_file_pcm = fopen(coutFilePath, "wb");
    if (out_file_pcm == NULL){

        NSLog(@"打开音频输出文件失败");
        return;
    }

    int current_index = 0;

    //计算：4分钟一首歌曲 = 240ms = 4MB
    //现在音频时间：24ms->pcm格式->8.48MB
    //如果是一首4分钟歌曲->pcm格式->85MB

    // 循环读取一份音频压缩数据
    while (av_read_frame(avformat_context,avpacket) >=0) {

        //判定是否是音频流
        if (avpacket->stream_index==av_stream_index) {

            /** 第七步音频解码 */
            //1、发送一帧音频压缩数据包->音频压缩数据帧
            avcodec_send_packet(avcodec_context, avpacket);
            //2、解码一帧音频压缩数据包->得到->一帧音频采样数据->音频采样数据帧
            audio_decode_result = avcodec_receive_frame(avcodec_context, avframe);

            // 解码成功
            if (audio_decode_result == 0) {

                //3、类型转换(音频采样数据格式有很多种类型)
                //我希望我们的音频采样数据格式->pcm格式->保证格式统一->输出PCM格式文件
                //swr_convert:表示音频采样数据类型格式转换器
                //参数一：音频采样数据上下文
                //参数二：输出音频采样数据
                //参数三：输出音频采样数据->大小
                //参数四：输入音频采样数据
                //参数五：输入音频采样数据->大小
                swr_convert(swr_context,
                            &out_buffer,
                            MAX_AUDIO_SIZE,
                            (const uint8_t **)avframe->data,
                            avframe->nb_samples);

                //4、获取缓冲区实际存储大小
                //参数一：行大小
                //参数二：输出声道数量
                //参数三：输入大小
                int nb_samples = avframe->nb_samples;
                //参数四：输出音频采样数据格式
                //参数五：字节对齐方式
                int out_buffer_size = av_samples_get_buffer_size(NULL,
                                                                 out_nb_channels,
                                                                 nb_samples,
                                                                 out_sample_fmt,
                                                                 1);

                //5、写入文件(你知道要写多少吗？)
                fwrite(out_buffer, 1, out_buffer_size, out_file_pcm);
                current_index++;
                NSLog(@"当前音频解码第%d帧", current_index);

            }
        }
    }

    NSLog(@"解码完成");

    /** 第八步：释放内存资源，关闭音频解码器 */
    fclose(out_file_pcm);

    av_packet_free(&avpacket);

    swr_free(&swr_context);

    av_free(out_buffer);

    av_frame_free(&avframe);

    avcodec_close(avcodec_context);

    avformat_close_input(&avformat_context);

}

@end
