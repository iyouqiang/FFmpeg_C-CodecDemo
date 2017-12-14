package yochi.com.yochi_videodecoding;

import android.os.Environment;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.widget.TextView;
import java.io.File;
import java.io.IOException;

public class MainActivity extends AppCompatActivity {

    // Used to load the 'native-lib' library on application startup.
    static {
        System.loadLibrary("native-lib");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        String rootPath = Environment.getExternalStorageDirectory()
                .getAbsolutePath();

        String inFilePath  = rootPath.concat("/YochiFFmpeg/Test.mov");
        String outFilePath = rootPath.concat("/YochiFFmpeg/Test.yuv");

        //文件不存在我创建一个文件
        File file = new File(outFilePath);
        if (file.exists()){
            Log.i("日志：","存在");
        }else {
            try {
                file.createNewFile();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        Log.i("infilePath", inFilePath);
        Log.i("outFilePath", outFilePath);

        ffmpegVideoDecode(inFilePath, outFilePath);

        stringFromJNI();
    }

    /**
     * A native method that is implemented by the 'native-lib' native library,
     * which is packaged with this application.
     */
    public native String stringFromJNI();

    public native void ffmpegVideoDecode(String inFilePath, String outFilePath);
}
