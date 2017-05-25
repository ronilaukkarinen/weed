weed - 受 XChat 启发的 irssi 主题
==============

立志成为世界上最漂亮的 irssi 主题

![weed.theme on OS X Mavericks](https://raw.githubusercontent.com/ronilaukkarinen/weed/master/screenshots/screenshot-mac.png "Screenshot")

![weed.theme on tmux](https://raw.githubusercontent.com/ronilaukkarinen/weed/master/screenshots/tmux.png "tmux")
*tmux 下的 weed*

![weed.theme solarized](https://raw.githubusercontent.com/her/weed/master/screenshots/SolarizedWeedMac.png)
*solarized 主题的 weed*

环境要求
--------------

- Linux or Unix shell
- irssi (还没在 Windows 上测试过)
- wget
- screen or tmux
- git (可选)
- solarized (可选)
- nano/pico (你也可以使用 vim 编辑, 不过本教程是在 nano 上写的)
- Mac OS X Terminal, Windows  [ExtraPuTTY](http://www.extraputty.com/) 或其他命令行 SSH
- Perl >= 5.1.4

安装
--------------

**如果依此教程破坏了你原有的 irssi 设置, 本文一概不负责**, 不过如果你认真地执行以下说明, 这个主题安装起来应该挺安全的.

1. 如果你原有设置的话, 请在命令行执行 `cp -Rv ~/.irssi ~/.irssi-backup` 备份你的当前设置. 这样一旦出错, 你可以轻松执行  `rm -rf ~/.irssi && mv ~/.irssi-backup ~/.irssi` 来恢复.
2. 执行 `cd ~` 确保你处于你的 home 目录, 假设你是第一次安装 irssi, 请通过 `screen irssi` 指令启动 irssi, 如果你更喜欢 tmux,  先执行 `tmux` 再启动 `irssi`
3. 在 irssi 中执行  `/save` 保存当前设置
4. 你将看到你的默认主题 (蓝色), 组合点击 **CTRL + A + D** 回到命令行 (tmux 下应该是 **CTRL + B, then D**) 
5. 通过 git 指令克隆仓库 `git clone https://github.com/ronilaukkarinen/weed.git weed-master` , 如果你没有安装 git 的权限, 也可以直接使用 `wget --no-check-certificate https://github.com/ronilaukkarinen/weed/archive/master.tar.gz` 下载, 通过 `tar -xvf master.tar.gz` 解压
6. 复制你想要的主题 `cp ~/weed-master/weed.theme ~/.irssi/` **或** `cp ~/weed-master/solarizedweed.theme ~/.irssi/`
7. 复制主题定制的 irssi 脚本: `mkdir -p ~/.irssi/scripts && cp ~/weed-master/scripts/* ~/.irssi/scripts/`
8. 复制主题定制的配置: `cp ~/weed-master/config ~/.irssi/`
9. 使用 screen 回到 irssi: `screen -dr` (tmux 下使用 `tmux a` ) 输入 `/reload` 重载配置.
10. 执行 `/script load awl` 获得比较高级的 window 列表
11. 修改你的 shell 设置来对颜色效果做最后的润色 (Linux 下应该如下图所示)

![Color settings in Linux](https://raw.githubusercontent.com/ronilaukkarinen/weed/master/screenshots/weed-colors-instruction.png "Color settings in Linux")

Putty 命令行只需要修改 **ANSI BLACK** 成 **25 25 25**.

**基本搞定!** 你可以连上服务器该干嘛干嘛了. 然而...

### 请注意

因为这是我修改的配置, 所以你的 nick 和 name 都会被默认配置为 **yourname**. 

1. 请修改你的 nick: `/nick something` ,  `/set user_name something`
2. 设置你的真实名字: `/set real_name Real Name`.
3. 记得  `/save` 保存你的当前配置, 避免下次进入的时候丢失配置.

### 可选改进

通过一些好用的脚本, 你可以继续改进你的主题

#### 频道人数
你可以通过 `/script load usercount.pl` 和  `/sbar awl_0 add -before awl_0 -alignment left usercount` 指令获得一个漂亮的用户数显示. 也可以自定义一个别名 `/alias usercount /sbar awl_0 add -before awl_0 -alignment left usercount`, 下次用户数不见的时候, 输入 `/usercount` 就行了.

![Usercount](https://raw.githubusercontent.com/ronilaukkarinen/weed/master/screenshots/usercount.png "Usercount")

#### 使用横幅记录上次聊到的地方

`/script load trackbar22` 能为你带来一个漂亮的长条来分割未读消息, 如果你不喜欢默认的灰色下划线, 还可以通过  `/set trackbar_string _` 和 `/set trackbar_style %r` 来修改样式.

![Trackbar](https://raw.githubusercontent.com/ronilaukkarinen/weed/master/screenshots/trackbar.png "Trackbar")

#### 状态栏的离开信息

如果你想要一个离开状态栏 (右侧的大红色块), 你可以执行 `/script load awaybar` 和 `/sbar statusbar add -after erotin -alignment right awaybar` 来添加

![Awaybar](https://raw.githubusercontent.com/ronilaukkarinen/weed/master/screenshots/awaybar.png "Awaybar")

#### 屏幕右侧的昵称列表

如果你想像 mIRC 或其他图形客户端一样, 在右侧显示频道的昵称列表, 可以这样:

##### screen 用户

`/script load nicklist`,  `/nicklist screen` (开启昵称列表). 

##### tmux 用户

`/script load tmux-nicklist-portable`. 当前版本的 tmux 名称列表没有配置选项, 默认占据窗口的 20%.

#### 为每个昵称显示不同的颜色

为昵称加上不同的颜色, 能够清晰地区分不同的用户.

加载脚本 `/script load nickcolor_expando`. 

对于 `screen` and 和非 256 色 xterm 环境, 执行 `/set neat_colors rRyYbBmMcC` 获得部分颜色支持.

对于 `tmux` 和 256 色 xterm 环境, 执行 `/neatcolor colors` , 通过 `/neatcolor colors add X30`  指令自由增加颜色. 增加颜色请参考 [文档](https://github.com/shabble/irssi-docs/wiki/Irssi-0.8.17#Verifying_the_colours).

![Nickcolor](https://raw.githubusercontent.com/ronilaukkarinen/weed/master/screenshots/nickcolor_expando.png "Nickcolor")

历史
--------------

**Weed(大麻)?** 是的, 我不知道我为什么取这个名字 (额, 我不抽大麻). 可能我当时刚好看到吧. 差不多 2006, 2007 年的时候, 我对所有的 irssi 主题感到失望, 所以我决定要自己写一个.

Weed 可能是我的第五还是第六个主题, 当时没有什么能够取悦我, 设置我之前写的主题也不行, 最终诞生了它. 从那以后我就再也没有用过其他主题了. 对于我还有其他用户来说, weed 是最好用的一个主题.

你可以根据你的需求随意改动这些脚本并发布, 不过如果你能以任何形式赞赏或感谢我, 我会非常开心的! (比如在 quakenet 上  `/msg rolle` 私信我, (我在 IRCnet 上叫 `rolle_` ), 如果不确定是不是我, 可以先  `/whois` 一下!)

If you like it, [follow me in twitter](http://twitter.com/rolle) to know more about my projects (some of them IRC related).

## 译者

我是这个 readme 的中文翻译, 我在 freenode 上叫 `memphisw`, 大家可以来告诉我你看到了这篇文章(一般我会在 #linuxba 里, 欢迎来撩).

I'm chinese translator of this readme, i'm memphisw in freenode, you can come and tell me that you've seen this instruction, i'll be happy. any welcome to join #linuxba on freenode, it'a chinese channel with programmer from tieba.baidu. have fun reading!

版本变更
--------------

In case if you want to know what was done before theme ending up in here Github.

- **4.0** *(2013-03-25)* Theme translated in english, added old changelog and tutorial in this Readme. Newer changes and versions will be in commits only.
- **3.6** *(2010-11-27)* Fixes to make theme even more readable. Query layout is now the same than the rest of the windows.
- **3.5** Readability fixes. Spaces made shorter between separator pipes and the timestamps.
- **3.05** Edited pubmsgnick, pubnick, pubmsgmenick, pubmsghinick and = "sb_awaybar";
- **3.00** Added whole new tutorial inside the theme. No changes to the theme itself.
- **2.75e** Tutorial enhanced. 
- **2.75d** Created changelog. Better hilight.
