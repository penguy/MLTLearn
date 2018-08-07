# MLT环境搭建需知
本文档介绍在 Mac 下搭建 [MLT Framework](https://www.mltframework.org/) 开发环境，并支持 Webvfx 插件。本文适用的环境配置如下：

+ 需要 Homebrew 软件包管理器。

# 一 安装 MLT Framework

```
$ brew install mlt
.....中间过程省略
==> Installing mlt
==> Downloading https://homebrew.bintray.com/bottles/mlt-6.4.1.el_capitan.bottle
######################################################################## 100.0%
==> Pouring mlt-6.4.1.el_capitan.bottle.tar.gz
  /usr/local/Cellar/mlt/6.4.1: 413 files, 34.2MB
```

这个过程会先安装 MLT 所依赖的组件，包括: x264, ffmpeg, frei0r, popt, libdv, libsamplerate, libogg, libvorbis, sdl, libpng, mad, sox 。整个安装过程需要几分钟。

完成后，可以查看 MLT 的版本信息。

```
$ melt --version
melt 6.4.1
Copyright (C) 2002-2016 Meltytech, LLC
<http://www.mltframework.org/>
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

注: Homebrew 安装的软件，默认在 `/usr/local/opt` 目录下。

# 二 安装 MLT 插件 WebVfx

webvfx 是一个可以通过 web技术(HTML, CSS, JavaScript, WebGL )定义的视频特效框架。MLT 可以基于 Webvfx 插件，方便快捷为视频添加丰富的效果。

WebVfx 运行需要依赖 QT 和 QtWebKit 组件。

## 2.1 QT及QtWebKit 组件安装

```
$ brew install qt --with-qtwebkit
# 这个过程比较耗时，因为需要加载源码进行编译。我实际花了两个多小时。

# 安装完成后，最后会打印如下安装信息:
We agreed to the Qt opensource license for you.
If this is unacceptable you should uninstall.

This formula is keg-only, which means it was not symlinked into /usr/local,
because Qt 5 has CMake issues when linked.

If you need to have this software first in your PATH run:
  echo 'export PATH="/usr/local/opt/qt/bin:$PATH"' >> ~/.bash_profile

For compilers to find this software you may need to set:
    LDFLAGS:  -L/usr/local/opt/qt/lib
    CPPFLAGS: -I/usr/local/opt/qt/include
For pkg-config to find this software you may need to set:
    PKG_CONFIG_PATH: /usr/local/opt/qt/lib/pkgconfig

==> Summary
  /usr/local/Cellar/qt/5.9.1: 9,128 files, 308.4MB, built in 134 minutes 35 seconds
```

根据上面的输出，设置环境变量:
```
$ export LDFLAGS=-L/usr/local/opt/qt/lib
$ export CPPFLAGS=-I/usr/local/opt/qt/include
$ export PKG_CONFIG_PATH=/usr/local/opt/qt/lib/pkgconfig
```

QT 安装完成后，可查看 qmake 命令，该命令会用于编译 webvfx 源码。

```
$ /usr/local/opt/qt/bin/qmake -v
QMake version 3.1
Using Qt version 5.9.1 in /usr/local/Cellar/qt/5.9.1/lib
```

## 2.2 Webvfx 组件安装

+ 官方介绍: http://webvfx.rectalogic.com/
+ 官网GIT: https://github.com/rectalogic/webvfx.git
+ MLT维护镜像GIT: https://github.com/mltframework/webvfx.git

```
$ cd ~/downloads/
$ git clone git://github.com/mltframework/webvfx.git
```

参考 [Webvfx Git](https://github.com/mltframework/webvfx.git) 上的编译说明:

```
In the webvfx directory run qmake -r PREFIX=/usr/local and then make install. PREFIX determines where WebVfx will be installed. If MLT is installed in a non-standard location, you may need to set the PKG_CONFIG_PATH environment variable to where its pkgconfig file lives, e.g. PKG_CONFIG_PATH=/usr/local/lib/pkgconfig.

The MLT melt command will not work with WebVfx on Windows or OS X because the Qt event loop must run on the main thread. If you set MLT_SOURCE to the root of your MLT source code directory, then a qmelt executable will be installed which behaves the same as melt but works with WebVfx on Windows or OS X. e.g. qmake -r PREFIX=/usr/local MLT_SOURCE=~/Projects/mlt.

make doxydoc to generate the documentation using Doxygen. You can also make uninstall, make clean and make distclean.
```

在 OS X 系统上，我们还需要基于 MLT 的源码，来编译一个 qmelt 可执行工具。由于 QT 的事件循环必须在主线程，在 OS X 上需使用 qmelt 命令来代替 melt 命令，才能使用 WebVfx 插件功能。

```
# 先从 Git 获取 MLT 的源码
$ cd ~/downloads/
$ git clone https://github.com/mltframework/mlt.git
$ git checkout -b tag/v6.4.1 v6.4.1        # 重点:源码版本一定要与已安装melt版本一致

# 然后进入 webvfx 目录，用 QT 的 qmake 进行编译：
$ cd webvfx
$ /usr/local/opt/qt/bin/qmake -r PREFIX=/usr/local MLT_PREFIX=/usr/local/opt/mlt MLT_SOURCE=~/downloads/mlt

# 最后编译安装
$ make
$ make install
```

安装完成后，通过以下命令可以查看 melt 的 webvfx 插件安装成功

```
$ melt -query filters | grep webvfx
  - webvfx

## 同时， OS X 下可使用 qmelt 命令代替 melt 命令
$ qmelt --version
qmelt qmelt
Copyright (C) 2002-2016 Meltytech, LLC
<http://www.mltframework.org/>
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

## 备注:

**1) 编译 Webvfx 时的 qmake 参数说明:** 

+ PREFIX={webvfx的安装目录，默认/usr/local}
+ MLT_PREFIX={mlt的安装目录}
+ MLT_SOURCE={mlt framework 的源码目录。注意不要指定相对路径，需要绝对路径}

**2) mlt 源码分支版本一定要与 melt --version版本一致**

经测试，在编译 webvfx 时，mlt 源码直接用 master 分支，会导致make时出现如下错误:

```
/Users/xxxxxx/downloads/mlt/src/melt/melt.c:836:23: error: use of undeclared
      identifier 'MLT_LOG_TIMINGS'
                        mlt_log_set_level( MLT_LOG_TIMINGS );
                                           ^
4 warnings and 1 error generated.
make[2]: *** [../../build/release/.obj/qmelt/melt.o] Error 1
make[1]: *** [release] Error 2
make: *** [sub-mlt-qmelt-make_first-ordered] Error 2
```

# 三 MLT 结合 WebVfx 插件使用

WebVfx 源码目录 `demo/mlt` 下已经提供有示例demo，在运行之前，我们需要做一下简单修改。

以 mlt_transition_shader_pagecurl_html 文件为例，我们需要修改如下几处:

+ 1) 将 `${VFX_MELT:-melt}` 中的 melt 修改为 qmelt。
+ 2) 将 `${VFX_CONSUMER:-consumer_av}` 中的 consumer_sdl 修改为 consumer_av。

保存，然后执行这个脚本，会在当前目录生成一个名叫 melt.mov 的 视频文件，播放视频可以看到3D翻页效果。

```
$ ./mlt_transition_shader_pagecurl_html
+-----+ +-----+ +-----+ +-----+ +-----+ +-----+ +-----+ +-----+ +-----+
|1=-10| |2= -5| |3= -2| |4= -1| |5=  0| |6=  1| |7=  2| |8=  5| |9= 10|
+-----+ +-----+ +-----+ +-----+ +-----+ +-----+ +-----+ +-----+ +-----+
+---------------------------------------------------------------------+
|               H = back 1 minute,  L = forward 1 minute              |
|                 h = previous frame,  l = next frame                 |
|           g = start of clip, j = next clip, k = previous clip       |
|                0 = restart, q = quit, space = play                  |
+---------------------------------------------------------------------+
[mov @ 0x7fb0cb872400] Using AVStream.codec to pass codec parameters to muxers is deprecated, use AVStream.codecpar instead.
Current Position:        419
```

更多的 WebVfx 介绍请参考官网: [http://webvfx.rectalogic.com/](http://webvfx.rectalogic.com/) 。

----

<center>¸.·'´˙\`'·.¸¸.·'´˙\`'·.¸¸.·'´˙\`'·.¸¸.·'´˙\`'·.¸我是一条漂靓的分界线¸.·'´˙\`'·.¸¸.·'´˙\`'·.¸¸.·'´˙\`'·.¸¸.·'´˙\`'·.¸</center>

----

# 附: 快速生成 MLT 的 JNI 接口类

在 mlt 的源码中，基于 swig 可以快速生成 java jni 接口类。

首先，安装 swig 。

```
$ brew install swig
```

然后，确保设置如下环境变量。如果有，可以跳过:

```
export JAVA_HOME=<你的 java 安装目录>
export PATH=${JAVA_HOME}/bin:${PATH}
export JAVA_INCLUDE="-I${JAVA_HOME}/include -I${JAVA_HOME}/include/darwin"
# CXXFLAGS是重点，不加会报错: ld: symbol(s) not found for architecture x86_64
export CXXFLAGS="-std=c++11 -lmlt"
```

接着，进入之前下载的 mlt 源码目录，编译出 jni 接口类:

```
$ cd ~/downloads/mlt
$ ./configure --enable-gpl --enable-gpl3 --enable-linsys --swig-languages=java --qt-libdir＝/usr/local/opt/qt/lib --qt-includedir＝/usr/local/opt/qt/include
$ make
```

编译 make 完成后，在 src/swig/java 可以找到 JNI 所需文件:

```
src_swig              # java 头文件所在的文件夹
libmlt_java.so        # 头文件所对应的库文件，mac 上需要把后缀修改为 .jnilib
# 注: Play.java 提供了 java jni 示例代码，可以参考如何调用
```

最后，把 libmlt_java.jnilib 复制到 `System.getProperty("java.library.path")` 所在目录，即可调用。

# 附: SWIG 手动生成 MLT 的 JNI 接口类

```
$ export JAVA_HOME=<你的 java 安装目录>
$ export CXXFLAGS="-std=c++11 -lmlt"
$ ln -sf ../mlt.i
$ mkdir -p src_swig/org/mltframework
$ swig -c++ -I../../mlt++ -I../.. -java -outdir src_swig/org/mltframework -package org.mltframework mlt.i
$ g++ -fPIC -D_GNU_SOURCE ${CXXFLAGS} -c -rdynamic -pthread -I../.. mlt_wrap.cxx $JAVA_INCLUDE

# mac 平台打包生成动态库文件 libxxx.jnilib
$ g++ ${CXXFLAGS} -dynamiclib mlt_wrap.o -L../../mlt++ -lmlt++ -o libmlt_java.jnilib

# linux 平台打包生成动态库文件 libxxx.so
$ g++ ${CXXFLAGS} -shared mlt_wrap.o -L../../mlt++ -lmlt++ -o libmlt_java.so
```

# 附: 常见错误处理

## 1) qmelt 执行时，若html资源包含https告警

```
qt.network.ssl: Error receiving trust for a CA certificate
qt.network.ssl: Error receiving trust for a CA certificate
```

SSL warnings不是错误，https连接会继续工作。若要防止该告警消息，需添加环境变量即可解决。

```
export QT_LOGGING_RULES=qt.network.ssl.warning=false
```

参考: https://bugreports.qt.io/browse/QTBUG-43173

## 2) melt 执行时 avformat 报错 Symbol not found

```
mlt_repository_init: failed to dlopen /usr/local/Cellar/mlt/6.4.1/lib/mlt/libmltavformat.dylib
  (dlopen(/usr/local/Cellar/mlt/6.4.1/lib/mlt/libmltavformat.dylib, 2): Symbol not found: _av_frame_set_color_range
  Referenced from: /usr/local/Cellar/mlt/6.4.1/lib/mlt/libmltavformat.dylib
  Expected in: /usr/local/opt/ffmpeg/lib/libavcodec.57.dylib
 in /usr/local/Cellar/mlt/6.4.1/lib/mlt/libmltavformat.dylib)
```

可能 ffmpeg 版本太高，下载低版本安装即可。

```
$ curl -O http://ffmpeg.org/releases/ffmpeg-3.3.3.tar.bz2
$ tar -jxvf ffmpeg-3.3.3.tar.bz2
$ ./configure --prefix=/usr/local/Cellar/ffmpeg/3.3.3 --enable-shared --enable-pthreads --enable-version3 --enable-hardcoded-tables --enable-avresample --cc=clang --host-cflags= --host-ldflags= --enable-gpl --enable-libmp3lame --enable-libvpx --enable-libwebp --enable-libx264 --enable-libxvid --enable-opencl --enable-videotoolbox --disable-lzma
$ make
$ make install
```

--prefix 指定到 brew 软件安装目录，然后可以通过 brew 切换版本。

```
$ brew switch ffmpeg 3.3.3
```

另外: 可以直接下载 mac 低版本 FFmpeg 二进制包。然后解压到 /usr/local/Cellar/ 目录。

https://homebrew.bintray.com/bottles/ffmpeg-3.3.3.el_capitan.bottle

不过，这种方法安装，不能扩展功能，比如 --enable-libvpx --enable-libwebp 等。


## 3) Mac 安装 vid.stab

vid.stab 是视频防抖的插件，官网介绍: http://public.hronopik.de/vid.stab/

```
cd ~/downloads/
sudo git clone git://github.com/georgmartius/vid.stab.git
cd vid.stab
sudo mkdir temp_build
cd temp_build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/Cellar/vidstab/1.1.0 ../
make
sudo make install
```

若出现错误: `clang: error: unsupported option '-fopenmp'` 则表示 mac 原生 clang 不支持 OpenMP。

解决办法:

```
# 确保重新安装 llvm : brew install llvm
export PATH="/usr/local/opt/llvm/bin:$PATH"
export CC=/usr/local/opt/llvm/bin/clang
export CXX=/usr/local/opt/llvm/bin/clang++
export LIBRARY_PATH="/usr/local/opt/llvm/lib:$LIBRARY_PATH"
export LD_LIBRARY_PATH="/usr/local/opt/llvm/lib:$LD_LIBRARY_PATH"
```

参考资料: https://clang-omp.github.io/
