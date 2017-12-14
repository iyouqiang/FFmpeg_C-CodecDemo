#include <jni.h>
#include <string>
#include "android/log.h"

extern "C" {

//导入音视频头文件库
//核心库
#include "libavcodec/avcodec.h"
//封装格式处理库
#include "libavformat/avformat.h"
//工具库
#include "libavutil/imgutils.h"
//视频像素数据格式库
#include "libswscale/swscale.h"

JNIEXPORT void JNICALL Java_yochi_com_yochi_1ffmpeg_1videoencoding_MainActivity_ffmpegVideoEncode(
        JNIEnv *env, jobject jobj, jstring jinFilePath, jstring joutFilePath);

}


int flush_encoder(AVFormatContext *fmt_ctx, unsigned int stream_index) {
    int ret;
    int got_frame;
    AVPacket enc_pkt;


    if (!(fmt_ctx->streams[stream_index]->codec->codec->capabilities &
          CODEC_CAP_DELAY))
        return 0;
    while (1) {
        enc_pkt.data = NULL;
        enc_pkt.size = 0;
        av_init_packet(&enc_pkt);
        ret = avcodec_encode_video2(fmt_ctx->streams[stream_index]->codec, &enc_pkt,
                                    NULL, &got_frame);
        av_frame_free(NULL);
        if (ret < 0)
            break;
        if (!got_frame) {
            ret = 0;
            break;
        }
        __android_log_print(ANDROID_LOG_INFO, "main",
                            "Flush Encoder: Succeed to encode 1 frame!\tsize:%5d\n", enc_pkt.size);
        /* mux encoded frame */
        ret = av_write_frame(fmt_ctx, &enc_pkt);
        if (ret < 0)
            break;
    }
    return ret;
}

//视频编码
JNIEXPORT void JNICALL Java_yochi_com_yochi_1ffmpeg_1videoencoding_MainActivity_ffmpegVideoEncode(
        JNIEnv *env, jobject jobj, jstring jinFilePath, jstring joutFilePath) {

    /**第一步：注册组件->编码器、解码器等等…*/
    av_register_all();

    /**第二步：初始化封装格式上下文->视频编码->处理为视频压缩数据格式*/
    AVFormatContext *avformat_context = avformat_alloc_context();

    //FFmepg程序推测输出文件类型->视频压缩数据格式类型
    //得到视频压缩数据格式类型(h264、h265、mpeg2等等...)
    const char *coutFilePath = env->GetStringUTFChars(joutFilePath,NULL);
    AVOutputFormat *avoutput_format = av_guess_format(NULL,coutFilePath,NULL);

    avformat_context->oformat = avoutput_format;

    /**第三步：打开输出文件 AVIOContext是FFMPEG管理输入输出数据的结构体*/
    if (avio_open(&avformat_context->pb,coutFilePath,AVIO_FLAG_WRITE) <0 ) {

        __android_log_print(ANDROID_LOG_INFO,"main","打开输出文件失败");
        return;
    }

    /**第四步：创建输出码流->创建了一块内存空间->并不知道他是什么类型流->希望他是视频流*/
    AVStream *av_video_stream = avformat_new_stream(avformat_context,NULL);

    /**第五步：查找视频编码器*/


    //目标：设置为是一个视频编码器上下文->指定的是视频编码器
    //上下文种类：视频解码器、视频编码器、音频解码器、音频编码器

    AVCodecContext *avcodec_context = av_video_stream->codec;

//    AVCodecContext *avcodec_context =  avcodec_alloc_context3(NULL);
//
//    if (avcodec_context == NULL)  {
//
//        __android_log_print(ANDROID_LOG_INFO,"main","Could not allocate AVCodecContext\n");
//
//        return;
//    }
//
//    int avcodec_parameters_to_context_result = avcodec_parameters_to_context(avcodec_context, av_video_stream->codecpar);
//
//    if (avcodec_parameters_to_context_result != 0) {
//
//        // 0 成功 其他失败
//        __android_log_print(ANDROID_LOG_INFO,"main","获取解码器上下文失败");
//        return;
//    }

    //设置视频编码器ID
    avcodec_context->codec_id = avoutput_format->video_codec;

    avcodec_context->codec_type = AVMEDIA_TYPE_VIDEO;

    //设置读取像素数据格式->编码的是像素数据格式->视频像素数据格式->YUV420P(YUV422P、YUV444P等等...)
    avcodec_context->pix_fmt = AV_PIX_FMT_YUV420P;

    avcodec_context->width = 640;

    avcodec_context->height = 352;

    //设置帧率->表示每秒25帧
    //视频信息->帧率 : 25.000 fps
    //f表示：帧数
    //ps表示：时间(单位：每秒)
    avcodec_context->time_base.num = 1;
    avcodec_context->time_base.den = 25;

    //设置码率
    //什么是码率？
    //含义：每秒传送的比特(bit)数单位为 bps(Bit Per Second)，比特率越高，传送数据速度越快。
    //单位：bps，"b"表示数据量，"ps"表示每秒
    //目的：视频处理->视频码率

    // 什么是视频码率?
    //含义：视频码率就是数据传输时单位时间传送的数据位数，一般我们用的单位是kbps即千位每秒
    //视频码率计算如下？
    //基本的算法是：【码率】(kbps)=【视频大小 - 音频大小】(bit位) /【时间】(秒)
    //例如：Test.mov时间 = 24s，文件大小(视频+音频) = 1.73MB
    //视频大小 = 1.34MB（文件占比：77%） = 1.34MB * 1024 * 1024 * 8 = 字节大小 = 468365字节 = 468Kbps
    //音频大小 = 376KB（文件占比：21%）
    //计算出来值->码率 : 468Kbps->468000，b表示位(bit->位)

    //总结：码率越大，视频越大
    avcodec_context->bit_rate = 468000;

    //设置GOP->影响到视频质量问题->画面组->一组连续画面

    //ITU-T给这个标准命名为H.264（以前叫做H.26L），而ISO/IEC称它为MPEG-4 高级视频编码（Advanced Video Coding，AVC）,并且它将成为MPEG-4标准的第10部分。

    //MPEG格式画面类型：3种类型->分为->I帧、P帧、B帧
    //I帧->内部编码帧->原始帧(原始视频数据)
    //    完整画面->关键帧(必需的有，如果没有I，那么你无法进行编码，解码)
    //    视频第1帧->视频序列中的第一个帧始终都是I帧，因为它是关键帧
    //P帧->向前预测帧->预测前面的一帧类型，处理数据(前面->I帧、B帧)
    //    P帧数据->根据前面的一帧数据->进行处理->得到了P帧
    //B帧->前后预测帧(双向预测帧)->前面一帧和后面一帧
    //    B帧压缩率高，但是对解码性能要求较高。
    //总结：I只需要考虑自己 = 1帧，P帧考虑自己+前面一帧 = 2帧，B帧考虑自己+前后帧 = 3帧 (P帧和B帧是对I帧压缩)
    //I帧越少，视频越小->默认值->视频不一样
    avcodec_context->gop_size = 250;

    //设置量化参数
    //总结：量化系数越小，视频越是清晰
    //一般情况下都是默认值，最小量化系数默认值是10，最大量化系数默认值是51
    avcodec_context->qmin = 10;
    avcodec_context->qmax = 51;

    //设置b帧最大值->设置不需要B帧
    avcodec_context->max_b_frames = 0;

    // 查找编码器h264 （默认情况下FFmpeg没有编译进行h264库 需下载x264编译）
    AVCodec *avcodec = avcodec_find_encoder(avcodec_context->codec_id);
    if (avcodec == NULL) {
        __android_log_print(ANDROID_LOG_INFO, "main", "找不到编码器");
        return;
    }
    __android_log_print(ANDROID_LOG_INFO, "main", "编码器名称为：%s", avcodec->name);

    /**第六步：打开h264编码器*/
    AVDictionary *param = 0;
    if (avcodec_context->codec_id == AV_CODEC_ID_H264) {
        //需要查看x264源码->x264.c文件
        //第一个值：预备参数
        //key: preset
        //value: slow->慢
        //value: superfast->超快
        av_dict_set(&param, "preset", "superfast", 0);
        //第二个值：调优
        //key: tune->调优
        //value: zerolatency->零延迟
        av_dict_set(&param, "tune", "zerolatency", 0);
    }
    if (avcodec_open2(avcodec_context, avcodec, &param) < 0) {
        __android_log_print(ANDROID_LOG_INFO, "main", "打开编码器失败");
        return;
    }

    /** 第七步：写入文件头信息 */
    avformat_write_header(avformat_context, NULL);

    /** 第8步：循环编码yuv文件->视频像素数据(yuv格式)->编码->视频压缩数据(h264格式) */
    //8.1 定义一个缓冲区 作用：缓存一帧视频像素数据
    //8.1.1 获取缓冲区大小
    int buffer_size = av_image_get_buffer_size(avcodec_context->pix_fmt,
                                               avcodec_context->width,
                                               avcodec_context->height,
                                               1);
    //8.1.2 创建一个缓冲区
    int y_size = avcodec_context->width * avcodec_context->height;
    uint8_t *out_buffer = (uint8_t *) av_malloc(buffer_size);

    //8.1.3 打开输入文件
    const char *cinFilePath = env->GetStringUTFChars(jinFilePath, NULL);
    /*
　　r 打开只读文件，该文件必须存在。
　　r+ 打开可读写的文件，该文件必须存在。
　　rb+ 读写打开一个二进制文件，只允许读写数据。
　　rt+ 读写打开一个文本文件，允许读和写。
　　w 打开只写文件，若文件存在则文件长度清为0，即该文件内容会消失。若文件不存在则建立该文件。
　　w+ 打开可读写文件，若文件存在则文件长度清为零，即该文件内容会消失。若文件不存在则建立该文件。
　　a 以附加的方式打开只写文件。若文件不存在，则会建立该文件，如果文件存在，写入的数据会被加到文件尾，即文件原先的内容会被保留。（EOF符保留）
　　a+ 以附加方式打开可读写的文件。若文件不存在，则会建立该文件，如果文件存在，写入的数据会被加到文件尾后，即文件原先的内容会被保留。 （原来的EOF符不保留）
　　wb 只写打开或新建一个二进制文件；只允许写数据。
　　wb+ 读写打开或建立一个二进制文件，允许读和写。
　　wt+ 读写打开或着建立一个文本文件；允许读写。
　　at+ 读写打开一个文本文件，允许读或在文本末追加数据。
　　ab+ 读写打开一个二进制文件，允许读或在文件末追加数据。
     * */
    FILE *in_file = fopen(cinFilePath, "rb");
    if (in_file == NULL) {
        __android_log_print(ANDROID_LOG_INFO, "main", "文件不存在");
        return;
    }


    //8.2.1 开辟一块内存空间->av_frame_alloc
    AVFrame *av_frame = av_frame_alloc();
    //8.2.2 设置缓冲区和AVFrame类型保持一致->填充数据 linesize:yuv/rgb这些值
    av_image_fill_arrays(av_frame->data,
                         av_frame->linesize,
                         out_buffer,
                         avcodec_context->pix_fmt,
                         avcodec_context->width,
                         avcodec_context->height,
                         1);

    /** 第9步：视频编码处理 */
    //接收一帧视频像素数据->编码为->视频压缩数据格式
    AVPacket *av_packet = (AVPacket *) av_malloc(buffer_size);
    int i = 0;
    int result = 0;
    int current_frame_index = 1;

    while (true) {
        //从yuv文件里面读取缓冲区 读取大小：y_size * 3 / 2
        if (fread(out_buffer, 1, y_size * 3 / 2, in_file) <= 0) {
            __android_log_print(ANDROID_LOG_INFO, "main", "读取完毕...");
            break;
        } else if (feof(in_file)) {
            break;
        }

        // 将缓冲区数据->转成AVFrame类型
        //给AVFrame填充数据 void * restrict->->转成->AVFrame->ffmpeg数据类型

        //Y值 4
        av_frame->data[0] = out_buffer;
        //U值
        av_frame->data[1] = out_buffer + y_size;
        //V值 1
        av_frame->data[2] = out_buffer + y_size * 5 / 4;
        av_frame->pts = i;
        //注意时间戳
        i++;
        //总结：这样一来我们的AVFrame就有数据了

        //9.1 发送一帧视频像素数据
        avcodec_send_frame(avcodec_context, av_frame);
        //9.2 接收一帧视频像素数据->编码为->视频压缩数据格式
        result = avcodec_receive_packet(avcodec_context, av_packet);
        //9.3 判定是否编码成功
        if (result == 0) {
            //编码成功
            /**第10步：将视频压缩数据->写入到输出文件中->outFilePath*/
            av_packet->stream_index = av_video_stream->index;
            result = av_write_frame(avformat_context, av_packet);
            __android_log_print(ANDROID_LOG_INFO, "main", "当前是第%d帧", current_frame_index);
            current_frame_index++;
            //是否输出成功
            if (result < 0) {
                __android_log_print(ANDROID_LOG_INFO, "main", "输出一帧数据失败");
                return;
            }
        }
    }

    /**第11步：写入剩余帧数据->可能没有*/
    flush_encoder(avformat_context, 0);

    /**第12步：写入文件尾部信息*/
    av_write_trailer(avformat_context);

    /**第13步：释放内存*/
    avcodec_close(avcodec_context);
    av_free(av_frame);
    av_free(out_buffer);
    av_packet_free(&av_packet);
    avio_close(avformat_context->pb);
    avformat_free_context(avformat_context);
    fclose(in_file);
}

JNIEXPORT jstring JNICALL
Java_yochi_com_yochi_1ffmpeg_1videoencoding_MainActivity_stringFromJNI(
        JNIEnv *env,
        jobject /* this */) {
    std::string hello = "Hello from C++";
    return env->NewStringUTF(hello.c_str());
}