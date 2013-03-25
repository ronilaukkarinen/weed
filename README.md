weed.theme - XChat based theme for irssi
==============

Designed to be the most beautiful irssi theme in the world.
--------------

**Weed?** Yeah, I have no idea where I got that from (no, I am not smoking). I guess I was watching the grass grow. Around 2006 or 2007 I was frustrated with all the irssi themes I had tried and decided to start designing my own. Weed was maybe fifth or sixth theme I did. When nothing pleased me, not even my own previous themes, finally the gem was born. I have not used any other irssi theme ever since.

Feel free to edit to your needs but I would be pleased if you credited or thanked me in some way! (for example /msg rolle at quakenet)

Thanks for visiting.
If you like it, follow me in twitter to know more about my projects (some of them IRC related): http://twitter.com/rolle

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

Prequisities
--------------

- Linux or unix shell
- irssi (preferably original irssi that comes with your Linux distribution, not tested on irssi for Windows)
- wget (usually with every Linux distribution)
- screen (usually with every Linux distribution)
- git (optional)
- nano/pico (you can also use vi, but the tutorial below is for nano)
- PuttyTray or any command line interface you have in your Linux box, depends are you using shell or your client PC
- Some patience and basic Linux command line knowledge

Installation
--------------

1. Make backup of your current irssi setup, if you have one, by **cp -Rv ~/.irssi ~/.irssi-backup**. If something goes wrong, you can easily restore it by quitting irssi and running **rm -rf ~/.irssi && mv ~/.irssi-backup ~/.irssi** and running irssi again.

2. Make sure you are in your home directory by typing **cd ~** and start irssi for the first time (assuming this is clean installation)
"screen irssi"
"/save (in irssi, to generate the default config)"

3. You'll see default irssi theme (blue), but get back by pressing **CTRL+A+D**, for now. Clone this repository by using command 
"git clone https://github.com/ronilaukkarinen/weed.git weed-master"

Or if you don't have permissions to install git, run following
"wget --no-check-certificate https://github.com/ronilaukkarinen/weed/archive/master.tar.gz"
"tar -xvf master.tar.gz"

5. Copy the files by running 
"cp ~/weed-master/weed.theme ~/.irssi/"
"mkdir -p ~/.irssi/scripts && cp ~/weed-master/modified-scripts/* ~/.irssi/scripts/"
"cp ~/weed-master/config ~/.irssi/"

6. Go to irssi by **screen -dr** and run
"/reload"
