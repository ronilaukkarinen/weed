weed - XChat based theme for irssi
==============

### Designed to be the most beautiful irssi theme in the world.

![weed.theme on OS X Mavericks](https://raw.githubusercontent.com/ronilaukkarinen/weed/master/screenshots/screenshot-mac.png "Screenshot")

![weed.theme on tmux](https://raw.githubusercontent.com/ronilaukkarinen/weed/master/screenshots/tmux.png "tmux")
*weed on tmux*

Requirements
--------------

- Linux or Unix shell
- irssi (not tested on irssi for Windows)
- wget
- screen or tmux
- git (optional)
- nano/pico (you can also use vim, but the tutorial below is for nano)
- Mac OS X Terminal, [ExtraPuTTY](http://www.extraputty.com/) for Windows or any command line interface with SSH or SSH tunneling
- Perl >= 5.1.4

Installation
--------------

**I am not responsible if you break your irssi setup**, but the theme should be rather safe to install when following the instructions carefully.

1. Make backup of your current irssi setup, if you have one, by `cp -Rv ~/.irssi ~/.irssi-backup`. If something goes wrong, you can easily restore it by quitting irssi and running `rm -rf ~/.irssi && mv ~/.irssi-backup ~/.irssi` and running irssi again.
2. Make sure you are in your home directory by typing `cd ~` and start irssi for the first time (assuming this is clean installation): `screen irssi` or if you prefer tmux, run `tmux` and then `irssi`
3. In irssi, type `/save`
4. You'll see default irssi theme (blue), but get back by pressing the key combination **CTRL + A + D** (**CTRL + B, then D** in tmux), for now
5. Clone this repository by using command `git clone https://github.com/ronilaukkarinen/weed.git weed-master` or if you don't have permissions to run/install git, run following: `wget --no-check-certificate https://github.com/ronilaukkarinen/weed/archive/master.tar.gz` and unpack it using `tar -xvf master.tar.gz`
6. Copy the theme to .irssi folder by running `cp ~/weed-master/weed.theme ~/.irssi/`
7. Copy custom irssi scripts by running `mkdir -p ~/.irssi/scripts && cp ~/weed-master/scripts/* ~/.irssi/scripts/`
8. Copy the custom config by running `cp ~/weed-master/config ~/.irssi/`
9. Go back to irssi with `screen -dr` (`tmux a` in tmux) and type `/reload`.
10. Run advanced windowlist by typing `/run awl.pl`.
11. You will need to edit your colors to get the final touch (in Linux it looks like in the picture below)

![Color settings in Linux](https://raw.githubusercontent.com/ronilaukkarinen/weed/master/screenshots/weed-colors-instruction.png "Color settings in Linux")

In Putty only **ANSI BLACK** is required to be changed to **25 25 25**.

**Basically you are now done!** You can connect to servers and do whatever you like. However...

### Please note after installing

Because this is a modified config, your nick and name are **yourname** by default. 

1. Please change your nick by using `/nick something` and `/set user_name something`
2. Set your real name with `/set real_name Real Name`.
3. Remember to  `/save` and `/quit` and start `screen irssi` again to the settings to come in effect.

### Optional tweaks

You can `/run usercount.pl` and `/sbar awl_0 add -before awl_0 -alignment left usercount` and get a nice usercount on the left.

![Usercount](https://raw.githubusercontent.com/ronilaukkarinen/weed/master/screenshots/usercount.png "Usercount")

`/run trackbar.pl` gets you nice bar to separate old and new conversations. If you like it to fit feed more instead of that default grey, run `/set trackbar_string _` and `/set trackbar_style %r` to set it red.

![Trackbar](https://raw.githubusercontent.com/ronilaukkarinen/weed/master/screenshots/trackbar.png "Trackbar")

Really matter of taste, but if you'd like a weed awaybar (big red block in the right), you can add it by `/run awaybar.pl` and `/sbar statusbar add -after erotin -alignment right awaybar` commands. 

![Trackbar](https://raw.githubusercontent.com/ronilaukkarinen/weed/master/screenshots/awaybar.png "Awaybar")

Another truly optional scripts are `/run nicklist.pl` and `/nicklist screen` (enables nicklist) and `/run nickcolor.pl` (every nick in different color). Remember to run `/set nickcolor_colors 2 4 5 6 7 10 11 12 13` so you don't see others as the default green your are youself.

History
--------------

**Weed?** Yeah, I have no idea where I got that name from (no, I am not smoking). I guess I was watching the grass grow. Around 2006 or 2007 I was frustrated with all the irssi themes I had tried and decided to start designing my own.

Weed was maybe fifth or sixth theme I did. When nothing pleased me, not even my own previous themes, finally the gem was born. I have not used any other irssi theme ever since. For me and many other users weed.theme is the best irssi theme there is.

Feel free to edit to your needs but I would be pleased if you credited or thanked me in some way! (for example `/msg rolle` at quakenet or `rolle_` at IRCnet, remember to `/whois` if not sure!)

If you like it, [follow me in twitter](http://twitter.com/rolle) to know more about my projects (some of them IRC related).

Old changelog
--------------

In case if you want to know what was done before theme ending up in here Github.

- **4.0** *(2013-03-25)* Theme translated in english, added old changelog and tutorial in this Readme. Newer changes and versions will be in commits only.
- **3.6** *(2010-11-27)* Fixes to make theme even more readable. Query layout is now the same than the rest of the windows.
- **3.5** Readability fixes. Spaces made shorter between separator pipes and the timestamps.
- **3.05** Edited pubmsgnick, pubnick, pubmsgmenick, pubmsghinick and = "sb_awaybar";
- **3.00** Added whole new tutorial inside the theme. No changes to the theme itself.
- **2.75e** Tutorial enhanced. 
- **2.75d** Created changelog. Better hilight.