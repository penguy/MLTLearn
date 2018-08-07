# 安装需知
本文档介绍在 Linux 下搭建 [MLT Framework](https://www.mltframework.org/) 开发环境，并支持 Webvfx 插件。本文适用的环境配置如下：

+ Linux 发行版 7 系列，如 redhat7.x86_64 , centos7.x86_64
+ 需要 curl 版本 >= 7.19.4 。
+ 需要 Git 版本 >=2.0。
+ 需要 yum 软件包管理器。

# 一 环境准备

## 1.1 检查 git 版本

因为安装 Melt framework 的大部分依赖包需要基于 git 从远程获取。git 版本需 >=2.0

```
$ git --version
git version 2.14.1.40.g8e62ba1

若版本过低，需要升级，命令如下:
$ sudo yum upgrade git
```

若没有，则执行以下命令安装 `sudo yum install git` 。

## 1.2 检查 curl 版本

因为安装 Melt framework 的部分依赖包需要 curl 支持。curl 版本 >= 7.19.4 支持重定向请求。

```
$ curl --version
curl 7.29.0 (x86_64-koji-linux-gnu) libcurl/7.29.0 NSS/3.16.2.3 Basic ECC zlib/1.2.7 libidn/1.28 libssh2/1.4.3
Protocols: dict file ftp ftps gopher http https imap imaps ldap ldaps pop3 pop3s rtsp scp sftp smtp smtps telnet tftp 
Features: AsynchDNS GSS-Negotiate IDN IPv6 Largefile NTLM NTLM_WB SSL libz
```

若没有，则执行以下命令安装 `sudo yum install curl` 。

# 二 安装基础依赖库

```
sudo yum install yasm gavl-devel libsamplerate-devel libxml2-devel ladspa-devel jack-audio-connection-kit-devel sox-devel SDL-devel gtk2-devel libexif-devel libtheora-devel libvorbis-devel libvdpau-devel libsoup-devel liboil-devel python-devel alsa-lib cmake kdelibs-devel qimageblitz-devel qjson-devel xorg-x11-util-macros pulseaudio pulseaudio-libs-devel libepoxy-devel
```

安装依赖包前，会先查找可用的安装包，(在集团环境)可能会出现部分安装包找不到，如:

```
No package yasm available.
No package jack-audio-connection-kit-devel available.
```

这些找不到的安装包，则需要手动进行源码安装。

## 2.1 手动安装 yasm

+ yasm 是用于 ffmpeg 运行的汇编环境，加快处理速度，提高性能。

```
cd ~/downloads/
sudo curl -L -O http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
sudo tar -xzvf yasm-1.3.0.tar.gz            # 解压
cd yasm-1.3.0
./configure
make
make install
yasm --version
```

## 2.2 手动安装 eigen3

eigen3 是 C++矩阵处理工具，线性算术的C++模板库,包括:vectors, matrices,开源以及相关算法。

+ 项目主页: http://eigen.tuxfamily.org/

```
cd ~/downloads/
sudo git clone https://github.com/RLovelett/eigen.git
cd eigen
git checkout branches/3.3
mkdir temp_build
cd temp_build
cmake ../
make install
```

安装成功后，库文件默认在 `/usr/local/share/eigen3` 目录。

**注意:** 配置 PKG_CONFIG_PATH 环境变量，否则后面安装组件(movit)，无法找到eigen3

```
# 建议在 /etc/profile.d 目录下创建一个脚本，如 mlt_env.sh 。下次机器重启，会自动运行
sudo vi /etc/profile.d/mlt_env.sh
# 然后在文件中添加内容
export PKG_CONFIG_PATH=/home/tops/lib/pkgconfig:/usr/lib64/pkgconfig:/usr/local/lib/pkgconfig:/usr/share/pkgconfig:/usr/local/share/pkgconfig:$PKG_CONFIG_PATH

$ source /etc/profile.d/mlt_env.sh                      # 使配置生效
$ pkg-config --cflags --libs eigen3       # 查看 eigen3 的 pkg-config 链接库信息
```

## 2.3 手动安装 jack-audio-connection-kit-devel

jack-audio-connection-kit 是音频处理套件。

```
cd ~/downloads/
sudo git clone git://github.com/jackaudio/jack2.git
sudo chmod -R 777 jack2
cd jack2
./waf configure
./waf build
sudo ./waf install

pkg-config --cflags --libs jack       # 查看 jack 的 pkg-config 链接库信息
```

# 三 安装 FFmpeg 及依赖组件

## 3.1 安装 lame 组件

lame 是高质量的 MPEG 音频编码器，官网介绍: http://lame.sourceforge.net/

```
cd ~/downloads/
sudo git clone https://github.com/rbrito/lame.git
cd lame
./configure --disable-frontend
make
sudo make install
```

## 3.2 安装 libvpx 组件

libvpx 是 google 视频格式 webm 的 编解码器。

```
cd ~/downloads/
sudo git clone https://github.com/webmproject/libvpx.git
sudo mkdir libvpx/temp_build
cd libvpx/temp_build
../configure --enable-vp8 --enable-postproc --enable-multithread --enable-runtime-cpu-detect --disable-install-docs --disable-debug-libs --disable-examples --disable-unit-tests --enable-shared
make -j4
sudo make install

pkg-config --cflags --libs vpx       # 查看 libvpx 的 pkg-config 链接库信息
```

## 3.3 安装 x265 组件

x265 是 一种高效的视频编码标准 HEVC ，文档介绍: http://x265.readthedocs.io/

```
cd ~/downloads/
sudo git clone https://github.com/videolan/x265.git
cd x265/build/linux
./make-Makefiles.bash
make -j4
sudo make install
pkg-config --cflags --libs x265       # 查看 x265 的 pkg-config 链接库信息
```

## 3.4 安装 x264 组件

x264 是ITU和MPEG联合制定的视频编码标准 ，文档介绍: https://www.videolan.org/developers/x264.html

```
cd ~/downloads/
sudo git clone git://repo.or.cz/x264.git
sudo mkdir x264/temp_build
cd x264/temp_build
../configure --disable-lavf --disable-ffms --disable-gpac --disable-asm --enable-shared
make -j4
sudo make install
x264 --version       # 查看 x264 的 版本信息
```

## 3.5 安装 FFmpeg 组件

yum install libwebp libwebp-devel

FFmpeg 是一套可以用来记录、转换数字音频、视频，并能将其转化为流的开源计算机程序。官网介绍:http://ffmpeg.org/

```
cd ~/downloads/
sudo git clone https://git.ffmpeg.org/ffmpeg.git
sudo chmod -R 777 ffmpeg
cd ffmpeg
sudo git checkout release/3.3     # 这里用3.3的分支，因为MLT用最新分支会有很多告警
./configure --enable-gpl --enable-version3 --enable-shared --enable-debug --enable-pthreads --enable-runtime-cpudetect --disable-doc --enable-libtheora --enable-libvorbis --enable-libmp3lame --enable-libx264 --enable-libx265 --enable-opengl --enable-libvpx --enable-libwebp
make -j4
sudo make install
```

如果 Git 无法访问，可以使用镜像Git: https://github.com/FFmpeg/FFmpeg.git

**注意:**

```
$ ffmpeg -version
ffmpeg: error while loading shared libraries: libavdevice.so.57: cannot open shared object file: No such file or directory
# 出现如上面的错误时，需要在 `/etc/ld.so.conf` 中添加 so 文件的路径。

$ sudo find / -name libavdevice.so      # 查找 so 文件所在位置
/usr/local/lib/libavdevice.so

$ vi /etc/ld.so.conf
在文件末位添加一行: /usr/local/lib/
$ sudo /sbin/ldconfig  # 使配置生效
```

```
ffmpeg 使用大于3.0的分支，会导致 mlt 执行时产生如下告警
[avi @ 0x7fb7f00c6da0] Using AVStream.codec to pass codec parameters to muxers is deprecated, use AVStream.codecpar instead.
[avi @ 0x7fb7f00c6da0] Using AVStream.codec to pass codec parameters to muxers is deprecated, use AVStream.codecpar instead.
```

```
如果 ffmpeg 访问 https 资源报错: 
https protocol not found, recompile FFmpeg with openssl, gnutlsor securetransport enabled
参考如下链接解决:
https://stackoverflow.com/questions/31514949/ffmpeg-over-https-fails
```

# 四 安装 movit 及依赖组件

## 4.1 安装依赖组件

```
yum install fftw-devel mesa-libEGL-devel
```

## 4.2 安装 movit 组件

movit 是3D gpu 加速特效库，基本的特效功能都有，锐化，素描，描边，模糊，色彩转换，overlay 等。介绍资料: https://movit.sesse.net/   https://git.sesse.net/?p=movit

```
cd ~/downloads/
sudo git clone https://git.sesse.net/movit/
sudo chmod -R 777 movit
cd movit
sh autogen.sh
./configure
make -j4 RANLIB= libmovit.la
sudo make install
```

# 五 安装 MLT 及依赖组件

## 5.1 安装 vid.stab 组件

vid.stab 是视频防抖的插件，官网介绍: http://public.hronopik.de/vid.stab/

```
cd ~/downloads/
sudo git clone git://github.com/georgmartius/vid.stab.git
cd vid.stab
sudo mkdir temp_build
cd temp_build
cmake ../
make
sudo make install
```

## 5.2 安装 frei0r 组件

frei0r 是一套视频滤镜效果库，官网介绍: https://frei0r.dyne.org/

```
cd ~/downloads/
sudo git clone https://github.com/dyne/frei0r.git
cd frei0r
./autogen.sh
./configure
make
sudo make install
```

## 5.3 安装 QT 组件 

(支持WebVfx插件，若用不到，可以不用安装) QT 跨平台 C++ 图形用户界面应用程序开发框架。官网介绍: https://www.qt.io/。

+ 源码包下载地址：http://download.qt.io/official_releases/qt/
+ 官网GIT: https://code.qt.io/qt/qt5.git
+ 镜像GIT: https://github.com/qt/qt5.git

先安装下面的依赖:

```
yum install alsa-lib libxcb-devel xcb-util-devel libjpeg-turbo-devel libjpeg-turbo-utils mesa-libEGL-devel mesa-dri-drivers
```

由于 Git 上的库太大，我们采用官网源码包进行编译安装。

```
cd ~/downloads/
wget http://download.qt.io/official_releases/qt/5.9/5.9.1/single/qt-everywhere-opensource-src-5.9.1.tar.xz
tar -xvJf  qt-everywhere-opensource-src-5.9.1.tar.xz
mv qt-everywhere-opensource-src-5.9.1 qt-src-5.9.1
cd qt-src-5.9.1
./configure -prefix /usr/local/Qt-5.9.1 -opensource -release -qt-xcb -nomake tests -nomake examples -confirm-license
gmake -j 4                                 # 大概两个小时
sudo gmake install
```

安装成功后的QT目录默认在 `/usr/local/Qt-<version>/` 下。执行 `qmake -v` 即可查看版本信息。

```
$ /usr/local/Qt-5.9.1/bin/qmake -v
QMake version 3.1
Using Qt version 5.9.1 in /usr/local/Qt-5.9.1/lib
```

+ 参考文档: http://doc.qt.io/qt-5.6/linux-building.html   http://wiki.qt.io/Main

## 5.4 安装 QTWebKit 组件 

(支持WebVfx插件，若用不到，可以不用安装) QT 从 5.6 版本之后不再提供 QTWebKit 组件，因此需要自己编译安装。

+ 官网GIT: https://code.qt.io/qt/qtwebkit.git
+ 镜像GIT: https://github.com/qt/qtwebkit.git

先安装下面的依赖:

```
sudo yum install gperf bison flex sqlite-devel fontconfig-devel phonon-devel perl-core libpng-devel ruby libicu-devel libxslt-devel
```

再编译源码进行安装:

```
cd ~/downloads/<QT的Git目录>       # 放到QT的Git目录，安装时需要依赖QT组件
sudo git clone https://code.qt.io/qt/qtwebkit.git
cd qtwebkit
git checkout 5.9.0
/usr/local/Qt-5.9.1/bin/qmake
make -j 4                          # 大概两个小时
make install                       # 会默认安装到 /usr/local/Qt-<version>/ 目录
```

可用测试: Tools/Scripts/run-launcher --qt

## 5.5 安装 Mlt Framework

```
cd ~/downloads/
sudo git clone https://github.com/mltframework/mlt.git
sudo chmod -R 777 mlt
cd mlt
# 如果安装了QT，则需要指定QT的路径；若没有，则不用设置 --qt-libdir 和 --qt-includedir
./configure --enable-opengl --enable-gpl --enable-gpl3 --enable-linsys --qt-libdir=/usr/local/Qt-5.9.1/lib --qt-includedir=/usr/local/Qt-5.9.1/include
make -j4
sudo make install

source setenv                                # 设置mlt环境变量
melt --version                               # 查看版本
```

若执行 `melt --version` 出现 `cannot open shared object file` 。通过执行 `/sbin/ldconfig` 可解决。

## 5.6 安装 webvfx 组件

(WebVfx插件若用不到，可以不用安装) webvfx 是一个可以通过 web技术(HTML, CSS, JavaScript, WebGL )定义的视频特效框架。

+ 官方介绍: http://webvfx.rectalogic.com/
+ 官网GIT: https://github.com/rectalogic/webvfx.git
+ MLT维护镜像GIT: https://github.com/mltframework/webvfx.git

```
cd ~/downloads/
git clone git://github.com/mltframework/webvfx.git
cd webvfx
# webvfx 需要基于 qt 的 qmake 进行编译。编译时会引用qmake所在目录的 qt 动态库
/usr/local/Qt-5.9.1/bin/qmake -r PREFIX=/usr/local    # 不指定，默认为/usr/local
make
sudo make install
```

验证 webvfx 安装成功:

```
$ melt -query filters | grep webvfx
  - webvfx
```

若 Linux 机器有连接显示设备，则可以通过如下命令运行示例 Demo:

```
cd ~/downloads/webvfx/demo/mlt
# 选择一个文件，将其中的 'consumer_sdl' 修改为 'consumer_av' 。使用前面安装的 ffmpeg
vi mlt_transition_shader_pagecurl_html
# 修改完成后，保存并执行这个脚本，即可生成一个3D转场的视频
./mlt_transition_shader_pagecurl_html
```

若 Linux 机器没有显示设备，运行时会报错 `QXcbConnection: Could not connect to display :0` 。需要安装一个支持显示的虚拟环境 XVFB ，如下节所示:

**备注**

若需要 webvfx 支持 跨域url资源访问，需要修改 `webvfx/web_content.cpp` 文件，如下所示:

```
WebPage::WebPage(QObject* parent) : QWebPage(parent) {
    mainFrame()->setScrollBarPolicy(Qt::Horizontal, Qt::ScrollBarAlwaysOff);
    mainFrame()->setScrollBarPolicy(Qt::Vertical, Qt::ScrollBarAlwaysOff);

    settings()->setAttribute(QWebSettings::LocalContentCanAccessRemoteUrls,true); // cross domain access
    settings()->setAttribute(QWebSettings::AllowRunningInsecureContent,true); // allow https
    settings()->setAttribute(QWebSettings::Accelerated2dCanvasEnabled,true);// 2D cavas accelerate

    settings()->setAttribute(QWebSettings::SiteSpecificQuirksEnabled, false);
    settings()->setAttribute(QWebSettings::AcceleratedCompositingEnabled, true);
    settings()->setAttribute(QWebSettings::WebGLEnabled, true);
}
```

参考 http://doc.qt.io/qt-5/qwebenginesettings.html

# 5.7 安装 XVFB 支持 WebVfx

XVFB(X virtual frame buffer) 是一个针对 X11 显示服务协议的虚拟环境。提供一个类似 X server 守护进程 和 设置程序运行的环境变量 DISPLAY 来提供程序运行的环境。

+ 介绍文档: https://www.x.org/releases/X11R7.7/doc/man/man1/Xvfb.1.xhtml

```
sudo yum install xorg-x11-server-Xvfb
```

安装完成后，通过启动 XVFB 虚拟显示服务，支持 webvfx 渲染。

```
cd ~/downloads/webvfx/demo/mlt
export QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb  # 配置X11服务配置目录
Xvfb :0 -screen 0 1280x1024x16 &              # 在后台启动一个虚拟显示服务
./mlt_transition_shader_pagecurl_html         # 执行脚本，生成3D转场视频
```

注: 为了开机启动 XVFB 虚拟显示服务，需要在 `/etc/rc.local` 中添加脚本，如下所示:

```
$ sudo vi /etc/rc.d/rc.local
# 在文件末尾加上下面一行开机启动 Xvfb
nohup Xvfb :0 -screen 0 1280x1024x16 >/dev/null 2>&1 &
# 保存后，确保 rc.local 具有可执行的权限
$ chmod a+x /etc/rc.d/rc.local

$ sudo vi /etc/profile.d/mlt_env.sh
# 然后在 mlt_env.sh 文件末尾添加下面环境变量
export QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb
export DISPLAY=:0
```

# 5.8 安装中文字体支持

Linux 的字体在 `/usr/share/fonts` 目录下，为了支持不同中文字体，需要手动安装。

```
$ cd /usr/share/fonts
$ wget http://video-advertise.cn-hangzhou.oss-cdn.aliyun-inc.com/fonts/ext_fonts.zip   // 可以替换自己的字体包
$ unzip ext_fonts.zip
$ rm -rf ext_fonts.zip
$ fc-cache -fv ext_fonts   // 设置字体缓存使之有效
```

字体相关命令：

```
$ fc-list            // 查看系统已经安装的字体
$ fc-list :lang=zh   // 查看系统已经安装的中文字体
$ fc-match Arial     // 查看字体对应的文件
$ locale             // 查看本地语言设置 
```

----

<center>¸.·'´˙\`'·.¸¸.·'´˙\`'·.¸¸.·'´˙\`'·.¸¸.·'´˙\`'·.¸¸.·'´˙\`'·.¸¸.·'´˙\`'·.¸我是一条漂靓的分界线¸.·'´˙\`'·.¸¸.·'´˙\`'·.¸¸.·'´˙\`'·.¸¸.·'´˙\`'·.¸¸.·'´˙\`'·.¸¸.·'´˙\`'·.¸</center>

----

# 附: 常见错误处理

## 1) 命令执行报错，提示 cannot open shared object file

```
ffmpeg: error while loading shared libraries: libavdevice.so.57: cannot open shared object file: No such file or directory
```

先查找 xxx.so 文件在什么位置，然后添加到 `/etc/ld.so.conf` 中。

```
$ sudo find / -name libavdevice.so
/usr/local/lib/libavdevice.so

sudo vi /etc/ld.so.conf
在文件末位添加一行: /usr/local/lib/
sudo /sbin/ldconfig  # 使配置生效
```

## 2) OS X 系统下编译 webvfx 时需指定 MLT_PREFIX 和 MLT_SOURCE

```
qmake -r PREFIX=/usr/local MLT_PREFIX=<mlt的安装目录> MLT_SOURCE=<mlt framework 的源码目录>
```

## 3) 报错不能使用动态库 xxx.a: could not read symbols

```
/usr/bin/ld: /usr/local/lib/libfftw3.a(lt4-problem.o): relocation R_X86_64_32 against `.rodata.str1.1' can not be used when making a shared object; recompile with -fPIC
/usr/local/lib/libfftw3.a: could not read symbols: Bad value
collect2: error: ld returned 1 exit status
make: *** [libmovit.la] Error 1
ERROR: Unable to build movit
```

因为 Linux 编译大多使用 share object，即 .so 的库文件。解决办法是在配置 `./configure` 时，加上参数 `--enable-shared` 。

## 4) 报错Qt requires C++11 support

```
/usr/local/Qt-5.9.1/include/QtCore/qbasicatomic.h:61:4: error: #error "Qt requires C++11 support"
 #  error "Qt requires C++11 support"
```

Qt5 需要 c++11 支持，设置环境变量 `export CXXFLAGS=-std=c++11`

## 5) MLT 基于SWIG编译 java JNI接口报错

当在 `./configure` 后面指定 `--swig-languages=java` 时，需要指定 Java 环境变量。
```
export JAVA_HOME=/opt/taobao/java
export PATH=${JAVA_HOME}/bin:${PATH}
export JAVA_INCLUDE="-I${JAVA_HOME}/include -I${JAVA_HOME}/include/linux"

# 然后再 make 编译。完成后，在 src/swig/java 可以找到 JNI 所需文件:
# libmlt_java.so 是所需库文件，src_swig目录下是所需头文件。
```

# 附: XVFB常用命令

```
# 启动Xvfb服务，服务号为1，屏幕 0 的深度为16，分辨率为1280x1024
# −screen 后面的 WxHxD。其中W是宽度，H是高度，D参数是 bits/pixel color depth。
$ Xvfb :1 -screen 0 1280x1024x16
$ Xvfb -ac :1 -screen 0 1280x1024x16  # -ac代表关闭xvfb的访问控制。
# 注意: D参数不能随便设置。在本机上测试，8、15、16、24、30这5个值可成功创建Xvfb进程，其中只有16、24、30三个值，Webvfx才能正常工作。配置时根据自己的环境，多做测试，选择合适的参数。

# 设置显示的服务号，和上面的服务号相同
$ export DISPLAY=:1

# 也可以直接通过 xvfb-run 命令 执行
$ xvfb-run --auto-servernum --server-args="-screen 0 1280x760x24"  <你的命令>
# 或者
$ xvfb-run -a -s '-screen 0 1280x760x24' <你的命令>

注意：尺寸会影响创建Xvfb 推荐尺寸为 1280x1024 、1600x1200，其他尺寸有肯能无法启动进行。

注意：-dpi 参数可以设置屏幕分辨率 每英寸的像素。常见取值 120, 160, 240。又称作像素密度，简称密度
nohup Xvfb :0 -screen 0 1600x1200x30 -dpi 360 >/dev/null 2>&1 &
nohup Xvfb :0 -screen 0 1600x1200x30 -dpi 240 >/dev/null 2>&1 &
nohup Xvfb :0 -screen 0 1600x1200x24 -dpi 360 >/dev/null 2>&1 &
nohup Xvfb :0 -screen 0 1600x1200x24 -dpi 240 >/dev/null 2>&1 &   #效果较好

```

# 附: 卸载 cmake 安装文件

```
cat install_manifest.txt|while read f; do sudo rm "$f"; done
```
