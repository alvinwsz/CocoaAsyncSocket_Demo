//
//  ViewController.m
//  CocoaAsyncSocket_TCP
//
//  Created by 孟遥 on 2017/4/14.
//  Copyright © 2017年 mengyao. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UITextField *messageTextField;

@property (nonatomic, strong) UIButton *sendBtn;

@end

@implementation ViewController

- (UIButton *)sendBtn
{
    if (!_sendBtn) {
        _sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _sendBtn.titleLabel.font = [UIFont systemFontOfSize:18.f weight:0.5];
        _sendBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_sendBtn setTitle:@"发送" forState:UIControlStateNormal];
        [_sendBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    }
    return _sendBtn;
}

- (UITextField *)messageTextField
{
    if (!_messageTextField) {
        _messageTextField = [[UITextField alloc]init];
        _messageTextField.placeholder = @"请输入消息内容";
        _messageTextField.textColor = [UIColor redColor];
        _messageTextField.font = [UIFont systemFontOfSize:14.f];
        _messageTextField.textAlignment = NSTextAlignmentLeft;
        _messageTextField.layer.borderColor = [UIColor redColor].CGColor;
        _messageTextField.layer.borderWidth = 1.f;
        
    }
    return _messageTextField;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initUI];
}


- (void)initUI
{
    [self.view addSubview:self.messageTextField];
    self.messageTextField.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - 200)*0.5,200, 200, 20);
    
    [self.view addSubview:self.sendBtn];
    self.sendBtn.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - 100)*0.5, 250, 80,50);
}

/*
 
  <<<<关于连接状态监听>>>>
 
 1. 普通网络监听
 
  由于即时通讯对于网络状态的判断需要较为精确 ，原生的Reachability实际上在很多时候判断并不可靠 。
  主要体现在当网络较差时，程序可能会出现连接上网络 ， 但并未实际上能够进行数据传输 。
  开始尝试着用Reachability加上一个普通的网络请求来双重判断实现更加精确的网络监听 ， 但是实际上是不可行的 。
  如果使用异步请求依然判断不精确 ， 若是同步请求 ， 对性能的消耗会很大 。
  最终采取的解决办法 ， 使用RealReachability ，对网络监听同时 ，PING服务器地址或者百度 ，网络监听问题基本上得以解决
 
 2. TCP连接状态监听：
 
 TCP的连接状态监听主要使用服务器和客户端互相发送心跳 ，彼此验证对方的连接状态 。
 规则可以自己定义 ， 当前使用的规则是 ，当客户端连接上服务器端口后 ，且成功建立SSL验证后 ，向服务器发送一个登陆的消息(login)。
 当收到服务器的登陆成功回执（loginReceipt)开启心跳定时器 ，每一秒钟向服务器发送一次心跳 ，心跳的内容以安卓端/iOS端/服务端最终协商后为准 。
 当服务端收到客户端心跳时，也给服务端发送一次心跳 。正常接收到对方的心跳时，当前连接状态为已连接状态 ，当服务端或者客户端超过3次（自定义）没有收到对方的心跳时，判断连接状态为未连接。
 
 
 
 
 <<<<关于本地缓存>>>>
 
 1. 数据库缓存 
 
 建议每个登陆用户创建一个DB ，切换用户时切换DB即可 。
 搭建一个完善IM体系 ， 每个DB至少对应3张表 。
 一张用户存储聊天列表信息，这里假如它叫chatlist ，即微信首页 ，用户存储每个群或者单人会话的最后一条信息 。来消息时更新该表，并更新内存数据源中列表信息。或者每次来消息时更新内存数据源中列表信息 ，退出程序或者退出聊天列表页时进行数据库更新。后者避免了频繁操作数据库，效率更高。
 一张用户存储每个会话中的详细聊天记录 ，这里假如它叫chatinfo。该表也是如此 ，要么接到消息立马更新数据库，要么先存入内存中，退出程序时进行数据库缓存。
 一张用于存储好友或者群列表信息 ，这里假如它叫myFriends ，每次登陆或者退出，或者修改好友备注，删除好友，设置星标好友等操作都需要更新该表。
 
 2. 沙盒缓存
 
 当发送或者接收图片、语音、文件信息时，需要对信息内容进行沙盒缓存。
 沙盒缓存的目录分层 ，个人建议是在每个用户根据自己的userID在Cache中创建文件夹，该文件夹目录下创建每个会话的文件夹。
 这样做的好处在于 ， 当你需要删除聊天列表会话或者清空聊天记录 ，或者app进行内存清理时 ，便于找到该会话的所有缓存。大致的目录结构如下
 ../Cache/userID(当前用户ID)/toUserID(某个群或者单聊对象)/...（图片，语音等缓存）
 
 
 
 <<<<聊天UI的搭建>>>>
 
 1. 聊天列表UI（微信首页）
 
 这个页面没有太多可说的 ， 一个tableView即可搞定 。需要注意的是 ，每次收到消息时，都需要将该消息置顶 。每次进入程序时，拉取chatlist表存储的每个会话的最后一条聊天记录进行展示 。
 
 2. 会话页面
 
 该页面tableView或者collectionView均可实现 ，看个人喜好 。这里是我用的是tableView . 
 根据消息类型大致分为普通消息 ，语音消息 ，图片消息 ，文件消息 ，视频消息 ，提示语消息（以上为打招呼内容，xxx已加入群，xxx撤回了一条消息等）这几种 ，固cell的注册差不多为5种类型，每种消息对应一种消息。
 视频消息和图片消息cell可以复用 。
 不建议使用过少的cell类型 ，首先是逻辑太多 ，不便于处理 。其次是效率并不高。
 
 
 <<<<发送消息>>>>
 
 1. 文本消息/表情消息
 
 直接调用咱们封装好的ChatHandler的sendMessage方法即可 ， 发送消息时 ，需要存入或者更新chatlist和chatinfo两张表。若是未连接或者发送超时 ，需要重新更新数据库存储的发送成功与否状态 ，同时更新内存数据源 ，刷新该条消息展示即可。
 若是表情消息 ，传输过程也是以文本的方式传输 ，比如一个大笑的表情 ，可以定义为[大笑] ，当然规则自己可以和安卓端web端协商，本地根据plist文件和表情包匹配进行图文混排展示即可 。
 https://github.com/coderMyy/MYCoreTextLabel ，图文混排地址 ， 如果觉得有用 ， 请star一下 ，好人一生平安
 
 
 2. 语音消息
 
 语音消息需要注意的是 ，多和安卓端或者web端沟通 ，找到一个大家都可以接受的格式 ，转码时使用同一种格式，避免某些格式其他端无法播放，个人建议Mp3格式即可。
 同时，语音也需要做相应的降噪 ，压缩等操作。
 发送语音大约有两种方式 。
 一是先对该条语音进行本地缓存 ， 然后全部内容均通过TCP传输并携带该条语音的相关信息，例如时长，大小等信息，具体的你得测试一条压缩后的语音体积有多大，若是过大，则需要进行分割然后以消息的方法时发送。接收语音时也进行拼接。同时发送或接收时，对chatinfo和chatlist表和内存数据源进行更新 ，超时或者失败再次更新。
 二是先对该条语音进行本地缓存 ， 语音内容使用http传输，传输到服务器生成相应的id ，获取该id再附带该条语音的相关信息 ，以TCP方式发送给对方，当对方收到该条消息时，先去下载该条信息，并根据该条语音的相关信息进行展示。同时发送或接收时，对chatinfo和chatlist表和内存数据源进行更新 ，超时或者失败再次更新。
 

 3. 图片消息
 
 图片消息需要注意是 ，通过拍照或者相册中选择的图片应当分成两种大小 ， 一种是压缩得非常小的状态，一种是图片本身的大小状态。 聊天页面展示的 ，仅仅是小图 ，只有点击查看时才去加载大图。这样做的目的在于提高发送和接收的效率。
 同样发送图片也有两种方式 。
 一是先对该图片进行本地缓存 ， 然后全部内容均通过TCP传输 ，并携带该图片的相关信息 ，例如图片的大小 ，名字 ，宽高比等信息 。同样如果过大也需要进行分割传输。同时发送或接收时，对chatinfo和chatlist表和内存数据源进行更新 ，超时或者失败再次更新。
 二是先对该图片进行本地缓存 ， 然后通过http传输到服务器 ，成功后发送TCP消息 ，并携带相关消息 。接收方根据你该条图片信息进行UI布局。同时发送或接收时，对chatinfo和chatlist表和内存数据源进行更新 ，超时或者失败再次更新。
 
 4. 视频消息
 
 视频消息值得注意的是 ，小的视频没有太多异议，跟图片消息的规则差不多 。只是当你从拍照或者相册中获取到视频时，第一时间要获取到视频第一帧用于展示 ，然后再发送视频的内容。大的视频 ，有个问题就是当你选择一个视频时，首先做的是缓存到本地，在那一瞬间 ，可能会出现内存峰值问题 。只要不是过大的视频 ，现在的手机硬件配置完全可以接受的。而上传采取分段式读取，这个问题并不会影响太多。
 
 视频消息我个人建议是走http上传比较好 ，因为内容一般偏大 。TCP部分仅需要传输该视频封面以及相关信息比如时长，下载地址等相关信息即可。接收方可以通过视频大小判断，如果是小视频可以接收到后默认自动下载，自动播放 ，大的视频则只展示封面，只有当用户手动点击时才去加载。具体的还是需要根据项目本身的设计而定。
 
 5. 文件消息
 
 文件方面 ，iOS端并不如安卓端那种可操作性强 ,安卓可以完全获取到用户里的所有文件，iOS则有保护机制。通常iOS端发送的文件 ，基本上仅仅局限于当前app自己缓存的一些文件 ，原理跟发送图片类似。
 
 6. 撤回消息
 
 撤回消息也是消息内容的一种类型 。例如 A给B发送了一条消息 "你好" ，服务端会对该条消息生成一个messageID ，接收方收到该条消息的messageID和发送方的该条消息messageID一致。如果发送端需要撤回该条消息 ，仅仅需要拿到该条消息messageID ，设置一下消息类型 ，发送给对方 ，当收到撤回消息的成功回执(repealReceipt)时，移除该会话的内存数据源和更新chatinfo和chatlist表 ，并加载提示类型的cell进行展示例如“你撤回了一条消息”即可。接收方收到撤回消息时 ，同样移除内存数据源 ，并对数据库进行更新 ，再加载提示类型的cell例如“张三撤回了一条消息”即可。
 
 7. 提示语消息 
 
 提示语消息通常来说是服务器做的事情更多 ，除了撤回消息是需要客户端自己做的事情并不多。
 当有人退出群 ，或者自己被群主踢掉 ，时服务端推送一条提示语消息类型，并附带内容，客户端仅仅需要做展示即可，例如“张三已经加入群聊”，“以上为打招呼内容”，“你已被踢出该群”等。
 当然 ，撤回消息也可以这样实现 ，这样提示消息类型逻辑就相当统一，不会显得很乱 。把主要逻辑交于了服务端来实现。
 
 
 <<<<消息删除>>>>
 
 这里需要注意的一点是 ，类似微信的长按消息操作 ，我采用的是UIMenuController来做的 ，实际上有一点问题 ，就是第一响应者的问题 ，想要展示该menu ，必须将该条消息的cell置为第一响应者，然后底部的键盘失去第一响应者，会降下去 。所以该长按出现menu最好还是自定义 ，根据计算相对frame进行布局较好，自定义程度也更好。
 
 消息删除大概分为删除该条消息 ，删除该会话 ，清空聊天记录几种
 删除该条消息仅仅需要移除本地数据源的消息模型 ，更新chatlist和chatinfo表即可。
 删除该会话需要移除chatlist和chatinfo该会话对应的列 ，并根据当前登录用户的userID和该会话的toUserID或者groupID移除沙盒中的缓存。
 清空聊天记录，需要更新chatlist表最后一条消息内容 ，删除chatinfo表，并删除该会话的沙盒缓存.
 
 
 <<<<消息拷贝>>>>
 
 这个不用多说 ，一两句话搞定
 
 
 <<<<消息转发>>>>
 
 拿到该条消息的模型 ，并创建新的消息 ，把内容赋值到新消息 ，然后选择人或者群发送即可。
 
 值得注意的是 ，如果是转发图片或者视频 ，本地沙盒中的缓存也应当copy一份到转发对象所对应的沙盒目录缓存中 ，不能和被转发消息的会话共用一张图或者视频 。因为比如 ：A给B发了一张图 ，A把该图转发给了C ，A移除掉A和B的会话 ，那么如果是共用一张图的话 ，A和C的会话中就再也无法找到这张图进行展示了。
 
 
 <<<<重新发送>>>>
 
 这个没有什么好说的。
 
 
 <<<<标记已读>>>>
 
 功能实现比较简单 ，仅仅需要修改数据源和数据库的该条会话的未读数（unreadCount），刷新UI即可。

 
 
 <<<<以下为大致的实现步骤>>>>
 
 文本/表情消息 ：
 
 方式一： 输入 ->发送 -> 消息加入聊天数据源 -> 更新数据库 -> 展示到聊天会话中 -> 调用TCP发送到服务器（若超时，更新聊天数据源，更新数据库 ，刷新聊天UI） ->收到服务器成功回执(normalReceipt) ->修改数据源该条消息发送状态(isSend) -> 更新数据库
 方式二： 输入 ->发送 -> 消息加入聊天数据源 -> 展示到聊天会话中 -> 调用TCP发送到服务器（若超时，更新聊天数据源，刷新聊天UI） ->收到服务器成功回执(normalReceipt) ->修改数据源该条消息发送状态(isSend) ->退出app或者页面时 ，更新数据库
 
 
 语音消息 ：（这里以http上传，TCP原理一致）
 
 方式一： 长按录制 ->压缩转格式 -> 缓存到沙盒 -> 更新数据库->展示到聊天会话中，展示转圈发送中状态 -> 调用http分段式上传(若失败，刷新UI展示) ->调用TCP发送该语音消息相关信息（若超时，刷新聊天UI） ->收到服务器成功回执 -> 修改数据源该条消息发送状态(isSend) ->修改数据源该条消息发送状态(isSend)-> 更新数据库-> 刷新聊天会话中该条消息UI
 方式二： 长按录制 ->压缩转格式 -> 缓存到沙盒 ->展示到聊天会话中，展示转圈发送中状态 -> 调用http分段式上传（若失败，更新聊天数据源，刷新UI展示） ->调用TCP发送该语音消息相关信息（若超时,更新聊天数据源，刷新聊天UI） ->收到服务器成功回执 -> 修改数据源该条消息发送状态(isSend -> 刷新聊天会话中该条消息UI - >退出程序或者页面时进行数据库更新
 
 
 图片消息 ：（两种考虑，一是展示和http上传均为同一张图 ，二是展示使用压缩更小的图，http上传使用选择的真实图片，想要做到精致，方法二更为可靠）
 
 方式一： 打开相册选择图片 ->获取图片相关信息，大小，名称等，根据用户是否选择原图，考虑是否压缩 ->缓存到沙盒 -> 更新数据库 ->展示到聊天会话中，根据上传显示进度 ->http分段式上传(若失败，更新聊天数据,更新数据库,刷新聊天UI) ->调用TCP发送该图片消息相关信息（若超时，更新聊天数据源，更新数据库,刷新聊天UI）->收到服务器成功回执 -> 修改数据源该条消息发送状态(isSend) ->更新数据库 -> 刷新聊天会话中该条消息UI
 方式二：打开相册选择图片 ->获取图片相关信息，大小，名称等，根据用户是否选择原图，考虑是否压缩 ->缓存到沙盒 ->展示到聊天会话中，根据上传显示进度 ->http分段式上传(若失败，更细聊天数据源 ，刷新聊天UI) ->调用TCP发送该图片消息相关信息（若超时，更新聊天数据源 ，刷新聊天UI）->收到服务器成功回执 -> 修改数据源该条消息发送状态(isSend) -> 刷新聊天会话中该条消息UI ->退出程序或者离开页面更新数据库
 
 视频消息： 
 
 方式一：打开相册或者开启相机录制 -> 压缩转格式 ->获取视频相关信息，第一帧图片，时长，名称，大小等信息 ->缓存到沙盒 ->更新数据库 ->第一帧图展示到聊天会话中，根据上传显示进度 ->http分段式上传(若失败，更新聊天数据,更新数据库,刷新聊天UI) ->调用TCP发送该视频消息相关信息（若超时，更新聊天数据源，更新数据库,刷新聊天UI）->收到服务器成功回执 -> 修改数据源该条消息发送状态(isSend) ->更新数据库 -> 刷新聊天会话中该条消息UI
 方式二：打开相册或者开启相机录制 ->压缩转格式 ->获取视频相关信息，第一帧图片，时长，名称，大小等信息 ->缓存到沙盒 ->第一帧图展示到聊天会话中，根据上传显示进度 ->http分段式上传(若失败，更细聊天数据源 ，刷新聊天UI) ->调用TCP发送该视频消息相关信息（若超时，更新聊天数据源 ，刷新聊天UI）->收到服务器成功回执 -> 修改数据源该条消息发送状态(isSend) -> 刷新聊天会话中该条消息UI ->退出程序或者离开页面更新数据库
 
 文件消息：
 跟上述一致 ，需要注意的是，如果要实现该功能 ，接收到的文件需要在沙盒中单独开辟缓存。比如接收到web端或者安卓端的文件
 
 
 
 
*/










@end
