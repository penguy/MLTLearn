# 序言

MLT 是一个面向电视广播进行设计的多媒体处理框架。同样地，MLT也提供一套可插拔的架构以支持新的音视频源、滤镜、转场 和 播放设备的接入。

MLT 应用和服务依赖于框架提供的架构和实用功能。

框架仅提供一些抽象类， 并提供一些实用工具用于管理资源，如内存、属性、动态对象加载、服务实例化。

该文档大致被分为 3 个部分。第一部分是对MLT的基础介绍；第二部分描述如何使用MLT；最后一部分说明架构和设计，重点在与该系统如何扩展。

**所有读者**

该文档作为学习了解MLT的路线图，所有希望在 MLT 上进行开发的人员有必要阅读。包括:

`1) 该框架的维护者 2) 模块开发者 3) 应用开发者 4) 对MLT感兴趣的人`

该文档的重点在于公共接口的说明，而不是细节的实现。

做MLT客户端/服务器集成没有必要阅读该文档，请参考 libmvsp.txt 和 mvsp.txt 获取更多的细节。

# 一 基础介绍

## 1.1 基本的设计细节

MLT 采用 C 语言实现，除了标准 `C99` 和 `POSIX` 库外，框架没有其他的依赖。

MLT框架遵循一个基本的面向对象设计范式，其中大部分设计是基于 生产者/消费者(Producer/Consumer) 设计模式。

采用 逆波兰表示法(RPN) 使用 音视频特效。

框架采用中立的色彩空间，当前实现的模块基本是采用 8位(bit) 的 YUV422。理论上，这些模块能够被完全替代。

这些术语的大致意思会在文档其他部分进行说明。

## 1.2 结构与流

MLT "网络" 的整体结构 是一个从 "生产者" 到 "消费者" 的简单连接。

```
  +--------+   +--------+
  |Producer|-->|Consumer|
  +--------+   +--------+
```

一个特定的 "消费者" 向 "生产者" 请求 MLT 帧对象，并对帧对象执行某些操作，在处理完成后，关闭它。

这里使用的 "生产者/消费者" 术语常会存在一点困惑，那就是 "消费者" 可能 "生产" 某些东西。例如，`libdv` 消费者 会产出 DV，`libdv` 生产者似乎在消费 DV。然而，这种命名规则仅是针对 MLT帧的生产者和消费者 而言。

换句话说，"生产者" 生产MLT Frame对象，"消费者" 使用MLT Frame对象。

一个MLT Frame帧基本上提供一个未压缩的图像及其相关的音频样本。

过滤器(Filter) 也可以放在 "生产者" 和 "消费者" 之间：

```
+--------+   +------+   +--------+
|Producer|-->|Filter|-->|Consumer|
+--------+   +------+   +--------+
```

所有 "生产者(Producer)", "过滤器(Filter)", "过渡(Transition)" 和 "消费者(Consumer)" 统称为 "服务"。

"消费者" 与 "生产者" 或 服务 连接后的通信分为3个阶段:

+ get the frame
+ get the image
+ get the audio

MLT 采用 "惰性计算"，只有当 `get the image` 和 `get the audio` 方法被调用的时候，才会从源中获取图像和音频。

本质上，"消费者"是从它连接的服务拉数据，这意味着线程通常是放在消费者实现的地方，并且在消费者类上提供一些基础功能以确保实时吞吐量。

# 二 使用

## 2.1 入门 Hello World

在我们进入框架架构的细节之前，先看一个可使用的实例。

如下所示提供一个媒体播放器：

```
#include <stdio.h>
#include <unistd.h>
#include <framework/mlt.h>

int main( int argc, char *argv[] )
{
    // Initialise the factory
    if ( mlt_factory_init( NULL ) == 0 )
    {
        // Create the default consumer
        mlt_consumer hello = mlt_factory_consumer( NULL, NULL );

        // Create via the default producer
        mlt_producer world = mlt_factory_producer( NULL, argv[ 1 ] );

        // Connect the producer to the consumer
        mlt_consumer_connect( hello, mlt_producer_service( world ) );

        // Start the consumer
        mlt_consumer_start( hello );

        // Wait for the consumer to terminate
        while( !mlt_consumer_is_stopped( hello ) )
            sleep( 1 );

        // Close the consumer
        mlt_consumer_close( hello );

        // Close the producer
        mlt_producer_close( world );

        // Close the factory
        mlt_factory_close( );
    }
    else
    {
        // Report an error during initialisation
        fprintf( stderr, "Unable to locate factory modules\n" );
    }

    // End of program
    return 0;
}
```

这是一个简单的示例，它不提供任何设定位置功能或运行时配置选项。

任何MLT应用程序的第一步是工厂初始化，这确保了环境的配置和MLT可以运行。 该工厂的细节如下所示。

所有的服务通过工厂进行实例化，如上面的 `mlt_factory_consumer` 和 `mlt_factory_producer` 调用所示。"过滤器" 和 "过渡" 有类似的工厂。所有标准服务的细节在 `services.txt` 文件里。

这里的默认请求是一种特殊情况，即使用 NULL，表示我们使用默认 "生产者" 和 "消费者"。

默认的生产者是 "loader"，该生产者匹配文件名以定位要使用的服务，并将“基准过滤器”（如缩放器，去隔行器，重新取样器和字段规范器）附加到加载的内容，这些过滤器确保消费者获得它所需要的内容。

默认的消费者是 "sdl"，loader和sdl的结合就是一个媒体播放器。

在这个例子中，我们连接生产者，再启动消费者。然后我们等待消费者停止（这种情况就是用户关闭SDL窗口的操作），最后在退出应用程序之前关闭消费者，生产者和工厂。

请注意，消费者是线程化的，在启动之后以及停止或关闭消费者之前总是需要等待某种事件。

另请注意，您可以按如下方式覆盖默认值：

```
MLT_CONSUMER=xml ./hello file.avi
# 这将通过 标准输出 创建一个XML文档。
```

```
MLT_CONSUMER=xml MLT_PRODUCER=avformat ./hello file.avi
# 这将直接使用 avformat生产者 播放视频，因此它将绕过规范化功能。
```

```
MLT_CONSUMER=libdv ./hello file.avi > /dev/dv1394
# 如果幸运的话，这可能会立即将file.avi实时转换为DV，并将其播送到您的DV设备。
```

## 2.2 工厂

如上 "Hello World" 示例所示，工厂创建服务对象。

框架本身不提供服务，服务都以插件结构的形式提供。插件以 "模块" 的形式组织，模块可以提供许多不同类型的服务。

工厂被初始化后，就可以使用所有已配置的服务。

`mlt_factory_prefix()` 返回已安装模块目录位置的路径。 这可以在 `mlt_factory_init` 调用时指定，或者可以通过 `MLT_REPOSITORY` 环境变量指定。在没有配置这些时，它将默认为 `<安装目录>/shared/mlt/modules` 。

`mlt_environment()` 提供对 `name=value` 键值对集合的只读访问权限，如下表所示:

```
Name                 Description                           Values
MLT_NORMALISATION    The normalisation of the system       PAL or NTSC
MLT_PRODUCER         The default producer                  "loader" or other
MLT_CONSUMER         The default consumer                  "sdl" or other
MLT_TEST_CARD        The default test card producer        any producer
```

这些值根据同名环境变量进行初始化。

如上所示，可以使用 'default normalizing' 生产者创建一个生产者，也可以通过名称加载它们。 过滤器和过渡始终按名称加载，而没有 "默认" 的概念。

## 2.3 服务的属性

所有服务都有自己的属性集合，可以对其进行修改以影响其行为。

为了设置服务的属性，我们需要获取与之关联的属性对象。 对于生产者，可以通过这样调用：

```
mlt_properties properties = mlt_producer_properties( producer );
```

所有服务都有与之相关的类似方法。

一旦获取到，可以直接在此对象上设置和获取属性，例如：

```
mlt_properties_set( properties, "name", "value" );
```

对属性对象的更完整说明会在下面给出。

## 2.4 播放列表

到目前为止，我们已经展示了一个简单的生产者/消费者配置，接下来是在播放列表中组织生产者。

让我们假设我们要调整Hello World示例，并希望将一些文件进行顺序播放，即：

```
hello 1.avi 2.avi .... *.avi
```

我们将创建一个名为 `create_playlist` 的新函数，而不是直接调用 `mlt_factory_producer` 。 此函数负责创建播放列表，创建每个生产者并添加到播放列表。

```
mlt_producer create_playlist( int argc, char **argv )
{
    // We're creating a playlist here
    mlt_playlist playlist = mlt_playlist_init( );

    // We need the playlist properties to ensure clean up
    mlt_properties properties = mlt_playlist_properties( playlist );

    // Loop through each of the arguments
    int i = 0;
    for ( i = 1; i < argc; i ++ )
    {
        // Create the producer
        mlt_producer producer = mlt_factory_producer( NULL, argv[ i ] );

        // Add it to the playlist
        mlt_playlist_append( playlist, producer );

        // Close the producer (see below)
        mlt_producer_close( producer );
    }

    // Return the playlist as a producer
    return mlt_playlist_producer( playlist );
}
```

请注意，我们在添加生产者就关闭它。实际上，我们做的是关闭对它的引用。播放列表在添加和插入生产者时会创建对它的引用，并且当播放列表被销毁时会关闭对它的引用。(备注: 这个引用功能是在 mlt 0.1.2 中引入的，它完全兼容早期的机制 - 对播放列表对象属性的注册引用 以及 销毁。)



另请注意，如果添加同一生产者的多个实例，播放列表将创建多个对它的引用。

现在我们需要做的就是在 `main` 函数中将这些行:

```
// Create a normalised producer
       mlt_producer world = mlt_factory_producer( NULL, argv[ 1 ] );
```

用如下代替:

```
// Create a playlist
       mlt_producer world = create_playlist( argc, argv );
```

这样我们就有办法播放多个片段了。

## 2.5 过滤器






