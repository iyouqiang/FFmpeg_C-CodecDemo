//
//  FFmpegVideoDecoding.m
//  Yochi_VideoDecoding
//
//  Created by Yochi·Kung on 2017/12/5.
//  Copyright © 2017年 gongyouqiang. All rights reserved.
//

#import "FFmpegVideoDecoding.h"

@implementation FFmpegVideoDecoding

+ (void)FFmpegVideoDecoding:(NSString *)inFilePath outFilePath:(NSString *)outFiulePath
{

    // http://blog.csdn.net/owen7500/article/details/47187513

    // iOS使用AVFoundation也可以实现
    // FFmpeg跨平台

    // 编码八部 天龙八部姊妹篇

    // 第一部 注册组件
    av_register_all();

    // 第二部 打开封装格式->打开文件
    AVFormatContext* avformat_context = avformat_alloc_context();


    const char *url = [inFilePath cStringUsingEncoding:NSUTF8StringEncoding];

    //参数一：封装格式上下文
    //作用：保存整个视频信息(解码器、编码器等等...)
    //信息：码率、帧率等...

    //参数二：视频路径

    //参数三：指定输入的格式

    //参数四：设置默认参数
    int avformat_open_input_result = avformat_open_input(&avformat_context, url, NULL, NULL);

    if(avformat_open_input_result !=0) {
        // 0 成功 其他失败

        NSLog(@"封装格式上下文打开文件, 打开文件失败");
        return;
    }

    // 第三部 查找视频流->拿到视频信息
    int avformat_find_stream_info_result = avformat_find_stream_info(avformat_context, NULL);
    if (avformat_find_stream_info_result < 0) {
        NSLog(@"查找失败");
    }

    // 第四部 查找视频解码器

    /**1、查找视频索引位置 */
    int av_stream_index = -1;
    for (int i = 0; i < avformat_context->nb_streams;i++) {

        // codec 弃用
        if (avformat_context->streams[i]->codecpar->codec_type==AVMEDIA_TYPE_VIDEO){
            av_stream_index = i;
            break;
        }
    }

    /**2、根据视频流索引，获取解码器上下文 */

    /**
     * 过时写法
     * AVCodecContext *avcodec_context = avformat_context->streams[av_stream_index]->codec;
     *
     * */

    AVCodecContext *avcodec_context =  avcodec_alloc_context3(NULL);
    if (avcodec_context == NULL)  {

        NSLog(@"Could not allocate AVCodecContext\n");
        return;
    }

    int avcodec_parameters_to_context_result = avcodec_parameters_to_context(avcodec_context, avformat_context->streams[av_stream_index]->codecpar);

    if (avcodec_parameters_to_context_result != 0) {

        // 0 成功 其他失败
        NSLog(@"获取解码器上下文失败");
        return;
    }

    /**3、根据解码器上下文，获得解码器ID，然后查找解码器 */
    AVCodec *avcodec_avcodec = avcodec_find_decoder(avcodec_context->codec_id);

    // 第五部 打开解码器
    int avcodec_open2_result = avcodec_open2(avcodec_context,avcodec_avcodec,NULL);
    if (avcodec_open2_result != 0){
        NSLog(@"打开解码器失败");
        return;
    }

    NSLog(@"解码器名称：%@",[NSString stringWithFormat:@"%s", avcodec_avcodec->name]);

    // 第六部 读取视频压缩数据->循环读取

    //1、分析av_read_frame参数
    //参数一：封装格式上下文
    //参数二：一帧压缩数据 = 一张图片
    //av_read_frame()
    //结构体大小计算：字节对齐原则
    AVPacket *packet = (AVPacket*)av_malloc(sizeof(AVPacket));

    //2、解码一帧视频压缩数据->进行解码(作用：用于解码操作)
    AVFrame *avframe_in = av_frame_alloc();

    int decode_result = 0;

    //3、注意：在这里我们不能够保证解码出来的一帧视频像素数据格式是yuv格式
    //参数一：源文件->原始视频像素数据格式宽
    //参数二：源文件->原始视频像素数据格式高
    //参数三：源文件->原始视频像素数据格式类型
    //参数四：目标文件->目标视频像素数据格式宽
    //参数五：目标文件->目标视频像素数据格式高
    //参数六：目标文件->目标视频像素数据格式类型

    struct SwsContext *swscontext = sws_getContext(avcodec_context->width,
                                            avcodec_context->height,
                                            avcodec_context->pix_fmt,
                                            avcodec_context->width,
                                            avcodec_context->height,
                                            AV_PIX_FMT_YUV420P,
                                            SWS_BICUBIC,
                                            NULL,
                                            NULL,
                                            NULL);
    //创建一个yuv420视频像素数据格式缓冲区(一帧数据)
    AVFrame* avframe_yuv420p = av_frame_alloc();

    //给缓冲区设置类型->yuv420类型
    //得到YUV420P缓冲区大小
    //参数一：视频像素数据格式类型->YUV420P格式
    //参数二：一帧视频像素数据宽 = 视频宽
    //参数三：一帧视频像素数据高 = 视频高
    //参数四：字节对齐方式->默认是1
    int buffer_size = av_image_get_buffer_size(AV_PIX_FMT_YUV420P,
                                               avcodec_context->width,
                                               avcodec_context->height,
                                               1);

    //开辟一块内存空间
    uint8_t *out_buffer = (uint8_t *)av_malloc(buffer_size);

    // 缓存区填充数据 avframe_yuv420p
    //参数一：目标->填充数据(avframe_yuv420p)
    //参数二：目标->每一行大小
    //参数三：原始数据
    //参数四：目标->格式类型
    //参数五：宽
    //参数六：高
    //参数七：字节对齐方式
    av_image_fill_arrays(avframe_yuv420p->data,
                         avframe_yuv420p->linesize,
                         out_buffer,
                         AV_PIX_FMT_YUV420P,
                         avcodec_context->width,
                         avcodec_context->height,
                         1);

    //NSLog(@"width : %d height : %f", avcodec_context->width, avcodec_context->height);
    // http://blog.csdn.net/jefry_xdz/article/details/7931018
    int y_size, u_size, v_size;
    /**

     YUV420sp与YUV420p的数据格式它们的UV排列在原理上是完全不同的。
     420p它是先把U存放完后，再存放V，也就是说UV它们是连续的。
     而420sp它是UV、UV这样交替存放的。
     有了上面的理论，我就可以准确的计算出一个YUV420在内存中存放的大小。

     width * hight =Y（总和）
     U = Y / 4
     V = Y / 4

     所以YUV420 数据在内存中的长度是 Y+ Y/4 + Y/4 = width * hight * 3 / 2，
     */
    const char *outfile = [outFiulePath cStringUsingEncoding:NSUTF8StringEncoding];

    FILE* file_yuv420p = fopen(outfile, "wb+");

    if (file_yuv420p == NULL){

        NSLog(@"输出文件打开失败");
        return;
    }

    int current_index = 0;

    while (av_read_frame(avformat_context,packet)>=0) {
        //>=:读取到了
        //<0:读取错误或者读取完毕
        //2、是否是我们的视频流
        if (packet->stream_index == av_stream_index) {

            // 第七部 视频解码->播放视频->得到视频像素数据

            avcodec_send_packet(avcodec_context, packet);

            decode_result = avcodec_receive_frame(avcodec_context, avframe_in);

            if (decode_result == 0) {

                // 在这里我们不能够保证解码出来的一帧视频像素数据格式是yuv格式
                // 视频像素数据格式很多种类型: yuv420P、yuv422p、yuv444p等等...
                // 保证：我的解码后的视频像素数据格式统一为yuv420P->通用的格式
                // 进行类型转换: 将解码出来的视频像素点数据格式->统一转类型为yuv420P

                //sws_scale作用：进行类型转换的
                //参数一：视频像素数据格式上下文
                //参数二：原来的视频像素数据格式->输入数据
                //参数三：原来的视频像素数据格式->输入画面每一行大小
                //参数四：原来的视频像素数据格式->输入画面每一行开始位置(填写：0->表示从原点开始读取)
                //参数五：原来的视频像素数据格式->输入数据行数
                //参数六：转换类型后视频像素数据格式->输出数据
                //参数七：转换类型后视频像素数据格式->输出画面每一行大小

                sws_scale(swscontext,
                          (const uint8_t *const *)avframe_in->data,
                          avframe_in->linesize,
                          0,
                          avcodec_context->height,
                          avframe_yuv420p->data,
                          avframe_yuv420p->linesize);

                //方式一：直接显示视频上面去
                //方式二：写入yuv文件格式
                //5、将yuv420p数据写入.yuv文件中
                //5.1 计算YUV大小
                //分析一下原理?
                //Y表示：亮度
                //UV表示：色度
                //有规律
                //YUV420P格式规范一：Y结构表示一个像素(一个像素对应一个Y)
                //YUV420P格式规范二：4个像素点对应一个(U和V: 4Y = U = V)
                y_size = avcodec_context->width * avcodec_context->height;
                u_size = y_size / 4;
                v_size = y_size / 4;
                //5.2 写入.yuv文件
                //首先->Y数据
                fwrite(avframe_yuv420p->data[0], 1, y_size, file_yuv420p);
                //其次->U数据
                fwrite(avframe_yuv420p->data[1], 1, u_size, file_yuv420p);
                //再其次->V数据
                fwrite(avframe_yuv420p->data[2], 1, v_size, file_yuv420p);

                current_index++;
                NSLog(@"当前界面第%d %d %d帧",avcodec_context->width , avcodec_context->height,current_index);
            }
        }

    }

    NSLog(@"解码完成");

    // 第八步 关闭解码器->解码完成
    // 重小到大释放
    av_packet_free(&packet);
    fclose(file_yuv420p);
    av_frame_free(&avframe_in);
    av_frame_free(&avframe_yuv420p);
    free(out_buffer);
    avcodec_close(avcodec_context);
    avformat_free_context(avformat_context);
}

@end
