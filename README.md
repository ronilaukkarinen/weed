weed - XChat based theme for irssi
==============

[![Irssi](https://img.shields.io/badge/tested%20with%20irssi-0.8.21-green.svg?style=flat-square)](https://github.com/ronilaukkarinen/weed) 
[![GitHub contributors](https://img.shields.io/github/contributors/ronilaukkarinen/weed.svg?style=flat-square)](https://github.com/ronilaukkarinen/weed/graphs/contributors) 
[![Twitter Follow](https://img.shields.io/twitter/follow/rolle.svg?style=social&label=Follow)](https://twitter.com/rolle)

### Designed to be the most beautiful irssi theme in the world.

Weed is a very unique irssi theme for those who just don't like the default blue or the themes available.

#### README in other languages

- [中文版本](https://github.com/ronilaukkarinen/weed/blob/master/README_CN.md) (thanks to [@steve-jokes](https://github.com/steve-jokes))

## Table of contents

1. [Screenshots](#screenshots)
2. [History](#screenshots)
3. [Requirements](#requirements)
4. [Installation](#installation)
    1. [Please note after installing](#please-note-after-installing)
    2. [Optional tweaks](#optional-tweaks)
5. [Old changelog](#old-changelog)
6. [Contributing and troubleshooting](#contributing-and-troubleshooting)

## Screenshots

![weed.theme on OS X Mavericks](https://i.imgur.com/2Pvr607.png "Screenshot")

![weed.theme on tmux](https://i.imgur.com/pdtYQfQ.png "tmux")
*weed on tmux*

![weed.theme solarized](https://i.imgur.com/Qs9HFIM.png)
*weed solarized* (thanks to [@her](https://github.com/her))

## History

**Weed?** Yeah, I have no idea where I got that name from (no, I am not smoking). I guess I was watching the grass grow. Around 2006 or 2007 I was frustrated with all the irssi themes I had tried and decided to start designing my own.

Weed was maybe fifth or sixth theme I did. When nothing pleased me, not even my own previous themes, finally the gem was born. I have not used any other irssi theme ever since. For me and many other users weed.theme is the best irssi theme there is.

Feel free to edit to your needs but I would be pleased if you credited or thanked me in some way! (for example `/msg rolle` at quakenet or `rolle_` at IRCnet, remember to `/whois` if not sure!)

If you like it, [follow me in twitter](http://twitter.com/rolle) to know more about my projects (some of them IRC related).

## Requirements

- Linux or Unix shell
- irssi (not tested on irssi for Windows)
- wget
- screen or tmux
- git (optional)
- solarized (optional)
- nano/pico (you can also use vim, but the tutorial below is for nano)
- Mac OS X Terminal, [ExtraPuTTY](http://www.extraputty.com/) for Windows or any command line interface with SSH or SSH tunneling
- Perl >= 5.1.4

## Installation

**I am not responsible if you break your irssi setup**, but the theme should be rather safe to install when following the instructions carefully.

1. Make backup of your current irssi setup, if you have one, by `cp -Rv ~/.irssi ~/.irssi-backup`. If something goes wrong, you can easily restore it by quitting irssi and running `rm -rf ~/.irssi && mv ~/.irssi-backup ~/.irssi` and running irssi again.
2. Make sure you are in your home directory by typing `cd ~` and start irssi for the first time (assuming this is clean installation): `screen irssi` or if you prefer tmux, run `tmux` and then `irssi`
3. In irssi, type `/save`
4. You'll see default irssi theme (blue), but get back by pressing the key combination **CTRL + A + D** (**CTRL + B, then D** in tmux), for now
5. Clone this repository by using command `git clone https://github.com/ronilaukkarinen/weed.git weed-master` or if you don't have permissions to run/install git, run following: `wget --no-check-certificate https://github.com/ronilaukkarinen/weed/archive/master.tar.gz` and unpack it using `tar -xvf master.tar.gz`
6. Copy your theme of choice to .irssi folder by running `cp ~/weed-master/weed.theme ~/.irssi/` **or** `cp ~/weed-master/solarizedweed.theme ~/.irssi/`
7. Copy custom irssi scripts by running `mkdir -p ~/.irssi/scripts && cp ~/weed-master/scripts/* ~/.irssi/scripts/`
8. Copy the custom config by running `cp ~/weed-master/config ~/.irssi/`
9. Go back to irssi with `screen -dr` (`tmux a` in tmux) and type `/reload`.
10. Run advanced windowlist by typing `/script load awl`.
11. You will need to edit your colors to get the final touch (in Linux it looks like in the picture below)

![Color settings in Linux](https://i.imgur.com/6kz6jIQ.png "Color settings in Linux")

In Putty only **ANSI BLACK** is required to be changed to **25 25 25**.

**Basically you are now done!** You can connect to servers and do whatever you like. However...

### Please note after installing

Because this is a modified config, your nick and name are **yourname** by default. 

1. Please change your nick by using `/nick something` and `/set user_name something`
2. Set your real name with `/set real_name Real Name`.
3. Remember to  `/save` and `/quit` and start `screen irssi` / `tmux` again to the settings to come in effect.

### Optional tweaks

Overall theme can be tweaked with useful scripts.

#### User count on channels
You can `/script load usercount.pl` and `/sbar awl_0 add -before awl_0 -alignment left usercount` and get a nice usercount on the left. You can add alias for this by `/alias usercount /sbar awl_0 add -before awl_0 -alignment left usercount` so next time usercount is missing, just type `/usercount`.

![Usercount](https://i.imgur.com/Vt1qWMi.png "Usercount")

#### Track last read conversation with trackbar

`/script load trackbar22` gets you nice bar to separate old and new conversations. If you like it to fit feed more instead of that default grey, run `/set trackbar_string _` and `/set trackbar_style %r` to set it red.

![Trackbar](https://i.imgur.com/JgkIAYX.png "Trackbar")

#### Away state in status bar

If you'd like a weed awaybar (big red block in the right), you can add it by `/script load awaybar` and `/sbar statusbar add -after erotin -alignment right awaybar` commands.

![Awaybar](https://i.imgur.com/s3U5ewT.png "Awaybar")

#### Nicklist on the right side of the screen

If you prefer seeing nicks on the right side like in mIRC or other GUI clients, do this:

##### For screen

`/script load nicklist` and `/nicklist screen` (enables nicklist). 

##### For tmux

`/script load tmux-nicklist-portable`. Currently tmux version of nicklist doesn't have any configuration and is by default 20% width of the window.

#### Each nick in different colors

To make nicks to distinct more from each other, nickcolor comes pretty handy.

`/script load nickcolor_expando`. For `screen` and non-xterm-256color, run `/set neat_colors X30rRX61X6CX3CyX1DcCBX3HX2AbMX3AX42X6M`. For `tmux` and xterm-256color you are good to go and you can see colors with `/neatcolor colors` and add or remove them with `/neatcolor colors add X30` (adds orangish). If you are interested more in 256 colors in irssi, please [read the docs](https://github.com/shabble/irssi-docs/wiki/Irssi-0.8.17#Verifying_the_colours).

![Nickcolor](https://i.imgur.com/vSymKmP.png "Nickcolor")

## Contributing and troubleshooting

If you have ideas about the theme or spot an issue, please let us know. If you have trouble setting the theme up, read this readme carefully again or [open an issue](https://github.com/ronilaukkarinen/weed/issues).
