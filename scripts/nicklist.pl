# This script adds a nicklist to the right of irssi
# for documentation: see http://wouter.coekaerts.be/site/irssi/nicklist

# Copyright (C) 2002-2007  Wouter Coekaerts <coekie@irssi.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

use Irssi;
use strict;
use IO::Handle; # for (auto)flush
use Fcntl; # for sysopen
use vars qw($VERSION %IRSSI);
$VERSION = '0.4.6+';
%IRSSI = (
	authors     => 'Wouter Coekaerts',
	contact     => 'coekie@irssi.org',
	name        => 'nicklist',
	description => 'draws a nicklist to another terminal, or at the right of your irssi in the same terminal',
	license     => 'GPLv2+',
	url         => 'http://wouter.coekaerts.be/irssi',
	changed     => '05/05/2007'
);

sub cmd_help {
	print ( <<EOF
Commands:
NICKLIST HELP
NICKLIST SCROLL <nr of lines>
NICKLIST SCREEN
NICKLIST FIFO
NICKLIST OFF
NICKLIST UPDATE

For help see: http://wouter.coekaerts.be/site/irssi/nicklist

in short:

1. FIFO MODE
- in irssi: /NICKLIST FIFO (only the first time, to create the fifo)
- in a shell, in a window where you want the nicklist: cat ~/.irssi/nicklistfifo
- back in irssi:
    /SET nicklist_heigth <height of nicklist>
    /SET nicklist_width <width of nicklist>
    /NICKLIST FIFO

2. SCREEN MODE
- start irssi inside screen ("screen irssi")
- /NICKLIST SCREEN
EOF
    );
}

my $prev_lines = 0;                  # number of lines in previous written nicklist
my $scroll_pos = 0;                  # scrolling position
my $cursor_line;                     # line the cursor is currently on
my ($OFF, $SCREEN, $FIFO) = (0,1,2); # modes
my $mode = $OFF;                     # current mode
my $need_redraw = 0;                 # nicklist needs redrawing
my $screen_resizing = 0;             # terminal is being resized
my $active_channel;                  # (REC)

my @nicklist=();                     # array of hashes, containing the internal nicklist of the active channel
	# nick => realnick
	# modeflag => '@', '%', '+', or other mode char
	# modepos => number representing the position in which to sort nicks with that mode
	# status => (not used yet...)
	#my ($STATUS_NORMAL, $STATUS_JOINING, $STATUS_PARTING, $STATUS_QUITING, $STATUS_KICKED, $STATUS_SPLIT) = (0,1,2,3,4,5);
	# text => text to be printed
	# cmp => text used to compare (sort) nicks


# 'cached' settings
my ($screen_prefix, $irssi_width, %prefix_mode, @prefix_status, $height, $nicklist_width, $check_friends, @prefix_friends);

sub read_settings {
	($screen_prefix = Irssi::settings_get_str('nicklist_screen_prefix')) =~ s/\\e/\033/g;

	($prefix_mode{'@'} = Irssi::settings_get_str('nicklist_prefix_mode_op')) =~ s/\\e/\033/g;
	($prefix_mode{'%'} = Irssi::settings_get_str('nicklist_prefix_mode_halfop')) =~ s/\\e/\033/g;
	($prefix_mode{'+'} = Irssi::settings_get_str('nicklist_prefix_mode_voice')) =~ s/\\e/\033/g;
	($prefix_mode{' '} = Irssi::settings_get_str('nicklist_prefix_mode_normal')) =~ s/\\e/\033/g;
	
	(my $prefix_mode_other = Irssi::settings_get_str('nicklist_prefix_mode_other')) =~ s/\\e/\033/g;
	foreach my $p (split (/ /, $prefix_mode_other)) {
		next if $p eq '';
		if ($p !~ /(.)=(.*)/) {
			Irssi::print("Could not parse nicklist_prefix_mode_other part '$p'. Expected space separated list of <mode character>=<prefix>");
			last;
		} else {
			$prefix_mode{$1} = $2;
		}
	}
	
	(my $prefix_friends = Irssi::settings_get_str('nicklist_prefix_friends')) =~ s/\\e/\033/g;
	foreach my $p (split (/ /, $prefix_friends)) {
		next if $p eq '';
		if ($p !~ /(.+?)=(.*)/) {
			Irssi::print("Could not parse nicklist_prefix_friends part '$p'. Expected space separated list of <flags>=<prefix>");
			last;
		} else {
			push @prefix_friends, {'flags' => $1, 'prefix' => $2};
		}
	}
	
	$check_friends = ($prefix_friends ne '');
	
	if ($mode != $SCREEN) {
		$height = Irssi::settings_get_int('nicklist_height');
	}
	my $new_nicklist_width = Irssi::settings_get_int('nicklist_width');
	if ($new_nicklist_width != $nicklist_width && $mode == $SCREEN) {
		sig_terminal_resized();
	}
	$nicklist_width = $new_nicklist_width;
}

sub update {
	read_settings();
	make_nicklist();
}

##################
##### OUTPUT #####
##################

### off ###

sub cmd_off {
	if ($mode == $SCREEN) {
		screen_stop();
	} elsif ($mode == $FIFO) {
		fifo_stop();
	}
}

### fifo ###

sub cmd_fifo_start {
	read_settings();
	my $path = Irssi::settings_get_str('nicklist_fifo_path');
	unless (-p $path) { # not a pipe
	    if (-e _) { # but a something else
	        die "$0: $path exists and is not a pipe, please remove it\n";
	    } else {
	        require POSIX;
	        POSIX::mkfifo($path, 0666) or die "can\'t mkfifo $path: $!";
		Irssi::print("Fifo created. Start reading it (\"cat $path\") and try again.");
		return;
	    }
	}
	if (!sysopen(FIFO, $path, O_WRONLY | O_NONBLOCK)) { # or die "can't write $path: $!";
		Irssi::print("Couldn\'t write to the fifo ($!). Please start reading the fifo (\"cat $path\") and try again.");
		return;
	}
	FIFO->autoflush(1);
	print FIFO "\033[2J\033[1;1H"; # erase screen & jump to 0,0
	$cursor_line = 0;
	if ($mode == $SCREEN) {
		screen_stop();
	}
	$mode = $FIFO;
	make_nicklist();
}

sub fifo_stop {
	close FIFO;
	$mode = $OFF;
	Irssi::print("Fifo closed.");
}

### screen ###

sub cmd_screen_start {
	if (!defined($ENV{'STY'})) {
		Irssi::print 'screen not detected, screen mode only works inside screen';
		return;
	}
	read_settings();
	if ($mode == $SCREEN) {return;}
	if ($mode == $FIFO) {
		fifo_stop();
	}
	$mode = $SCREEN;
	Irssi::signal_add_last('gui print text finished', \&sig_gui_print_text_finished);
	Irssi::signal_add_last('gui page scrolled', \&sig_page_scrolled);
	Irssi::signal_add('terminal resized', \&sig_terminal_resized);
	screen_size();
	make_nicklist();
}

sub screen_stop {
	$mode = $OFF;
	Irssi::signal_remove('gui print text finished', \&sig_gui_print_text_finished);
	Irssi::signal_remove('gui page scrolled', \&sig_page_scrolled);
	Irssi::signal_remove('terminal resized', \&sig_terminal_resized);
	system 'screen -x '.$ENV{'STY'}.' -X fit';
}

sub screen_size {
	if ($mode != $SCREEN) {
		return;
	}
	$screen_resizing = 1;
	# fit screen
	system 'screen -x '.$ENV{'STY'}.' -X fit';
	# we wait a second to make sure the fit command was processed
	Irssi::timeout_add_once(1000, \&screen_size_real, []);
}		

sub screen_size_real {
	# get size (from perldoc -q size)
	my ($winsize, $row, $col, $xpixel, $ypixel);
	eval 'use Term::ReadKey; ($col, $row, $xpixel, $ypixel) = GetTerminalSize';
	#	require Term::ReadKey 'GetTerminalSize';
	#	($col, $row, $xpixel, $ypixel) = Term::ReadKey::GetTerminalSize;
	#};
	if ($@) { # no Term::ReadKey, try the ugly way
		eval {
			require 'sys/ioctl.ph';
			# without this reloading doesn't work. workaround for some unknown bug
			do 'asm/ioctls.ph';
		};
		
		# ugly way not working, let's try something uglier, the dg-hack(tm) (constant for linux only?)
		if($@) { no strict 'refs'; *TIOCGWINSZ = sub { return 0x5413 } }
		
		unless (defined &TIOCGWINSZ) {
			die "Term::ReadKey not found, and ioctl 'workaround' failed. Install the Term::ReadKey perl module to use screen mode.\n";
		}
		open(TTY, "+</dev/tty") or die "No tty: $!";
		unless (ioctl(TTY, &TIOCGWINSZ, $winsize='')) {
			die "Term::ReadKey not found, and ioctl 'workaround' failed ($!). Install the Term::ReadKey perl module to use screen mode.\n";
		}
		close(TTY);
		($row, $col, $xpixel, $ypixel) = unpack('S4', $winsize);
	}
	
	# set screen width
	$irssi_width = $col-$nicklist_width-1;
	$height = $row-1;
	
	system 'screen -x '.$ENV{'STY'}.' -X width -w ' . $irssi_width;
	# wait another second for the resizing, and then redraw.
	Irssi::timeout_add_once(1000,sub {$screen_resizing = 0; redraw()}, []);
}

sub sig_terminal_resized {
	if ($screen_resizing) {
		return;
	}
	$screen_resizing = 1;
	Irssi::timeout_add_once(1000,\&screen_size,[]);
}


### both ###

sub nicklist_write_start {
	if ($mode == $SCREEN) {
		print STDERR "\033P\033[s\033\\"; # save cursor
	}
}

sub nicklist_write_end {
	if ($mode == $SCREEN) {
		print STDERR "\033P\033[u\033\\"; # restore cursor
	}
}

sub nicklist_write_line {
	my ($line, $data) = @_;
	if ($mode == $SCREEN) {
		print STDERR "\033P\033[" . ($line+1) . ';'. ($irssi_width+1) .'H'. $screen_prefix . $data . "\033\\";
	} elsif ($mode == $FIFO) {
		$data = "\033[m$data"; # reset color
		if ($line == $cursor_line+1) {
			$data = "\n$data"; # next line
		} elsif ($line == $cursor_line) {
			$data = "\033[1G".$data; # back to beginning of line
		} else {
			$data = "\033[".($line+1).";0H".$data; # jump
		}
		$cursor_line=$line;
		print(FIFO $data) or fifo_stop();
	}
}

sub calc_prefix_friends {
	my ($nick) = @_;

	return '' unless $check_friends
		&& $nick->{'host'}
		&& is_friend($active_channel->{'server'}->{'chatnet'}, $active_channel->{'name'}, $nick->{'nick'}, $nick->{'host'});
	
	my $flags = get_flags($active_channel->{'server'}->{'chatnet'}, $active_channel->{'name'}, $nick->{'nick'}, $nick->{'host'});
	
	my $prefix;
	foreach my $prefix_friend (@prefix_friends) {
		if ($prefix_friend->{'flags'} eq 'noflag') {
			if ($flags eq '') {
				$prefix = $prefix_friend->{'prefix'};
				last;
			}
		} elsif (check_modes($flags, $prefix_friend->{'flags'})) {
			$prefix = $prefix_friend->{'prefix'};
		}
	}
	
	return $prefix ? $prefix : '';
}

# recalc the text of the nicklist item
sub calc_text {
	my ($nick) = @_;
	my $tmp = $nicklist_width-3;
	(my $text = $nick->{'nick'}) =~ s/^(.{$tmp})..+$/$1\033[34m~/; # strip nick if too long
	
	my $prefix_mode = $prefix_mode{$nick->{'modeflag'}};
	if (! defined($prefix_mode) ) {
		$prefix_mode = $nick->{'modeflag'};
	}
	
	my $prefix_friends = calc_prefix_friends($nick);
	
	$nick->{'text'} =
		$prefix_mode .
		$prefix_friends .
		$text .
		(' ' x ($nicklist_width-length($nick->{'nick'})-1)) .
		"\033[m"; # reset
	$nick->{'cmp'} = $nick->{'modepos'}.lc($nick->{'nick'});
}

# redraw the given nick (nr) if it is visible
sub redraw_nick_nr {
	my ($nr) = @_;
	my $line = $nr - $scroll_pos;
	if ($line >= 0 && $line < $height) {
		nicklist_write_line($line, $nicklist[$nr]->{'text'});
	}
}

# nick was inserted, redraw area if necessary
sub draw_insert_nick_nr {
	my ($nr) = @_;
	my $line = $nr - $scroll_pos;
	if ($line < 0) { # nick is inserted above visible area
		$scroll_pos++; # 'scroll' down :)
	} elsif ($line < $height) { # line is visible
		if ($mode == $SCREEN) {
			need_redraw();
		} elsif ($mode == $FIFO) {
			my $data = "\033[m\033[L". $nicklist[$nr]->{'text'}; # reset color & insert line & write nick
			if ($line == $cursor_line) {
				$data = "\033[1G".$data; # back to beginning of line
			} else {
				$data = "\033[".($line+1).";1H".$data; # jump
			}
			$cursor_line=$line;
			print(FIFO $data) or fifo_stop();
			if ($prev_lines < $height) {
				$prev_lines++; # the nicklist has one line more
			}
		}
	}
}

sub draw_remove_nick_nr {
	my ($nr) = @_;
	my $line = $nr - $scroll_pos;
	if ($line < 0) { # nick removed above visible area
		$scroll_pos--; # 'scroll' up :)
	} elsif ($line < $height) { # line is visible
		if ($mode == $SCREEN) {
			need_redraw();
		} elsif ($mode == $FIFO) {
			#my $data = "\033[m\033[L[i$line]". $nicklist[$nr]->{'text'}; # reset color & insert line & write nick
			my $data = "\033[M"; # delete line
			if ($line != $cursor_line) {
				$data = "\033[".($line+1)."d".$data; # jump
			}
			$cursor_line=$line;
			print(FIFO $data) or fifo_stop();
			if (@nicklist-$scroll_pos >= $height) {
				redraw_nick_nr($scroll_pos+$height-1);
			}
		}
	}
}

# redraw the whole nicklist
sub redraw {
	$need_redraw = 0;
	#make_nicklist();
	nicklist_write_start();
	my $line = 0;
	### draw nicklist ###
	for (my $i=$scroll_pos;$line < $height && $i < @nicklist; $i++) {
		nicklist_write_line($line++, $nicklist[$i]->{'text'});
	}

	### clean up other lines ###
	my $real_lines = $line;
	while($line < $prev_lines) {
		nicklist_write_line($line++,' ' x $nicklist_width);
	}
	$prev_lines = $real_lines;
	nicklist_write_end();
}

# redraw (with little delay to avoid redrawing to much)
sub need_redraw {
	if(!$need_redraw) {
		$need_redraw = 1;
		Irssi::timeout_add_once(10,\&redraw,[]);
	}
}

sub sig_page_scrolled {
	$prev_lines = $height; # we'll need to redraw everything if he scrolled up
	need_redraw;
}

# redraw (with delay) if the window is visible (only in screen mode)
sub sig_gui_print_text_finished {
	if ($need_redraw) { # there's already a redraw 'queued'
		return;
	}
	my $window = @_[0];
	if ($window->{'refnum'} == Irssi::active_win->{'refnum'} || Irssi::settings_get_str('nicklist_screen_split_windows') eq '*') {
		need_redraw;
		return;
	}
	foreach my $win (split(/[ ,]/, Irssi::settings_get_str('nicklist_screen_split_windows'))) {
		if ($window->{'refnum'} == $win || $window->{'name'} eq $win) {
			need_redraw;
			return;
		}
	}
}

###################
##### FRIENDS #####
###################

# checks if $has_modes is in $need_modes, copied from trigger.pl
sub check_modes {
	my ($has_modes, $need_modes) = @_;
	my $matches;
	my $switch = 1; # if a '-' if found, will be 0 (meaning the modes should not be set)
	foreach my $need_mode (split /&/,$need_modes) {
		$matches = 0;
		foreach my $char (split //,$need_mode) {
			if ($char eq '-') {
				$switch = 0;
			} elsif ($char eq '+') {
				$switch = 1;
			} elsif ((index($has_modes,$char) != -1) == $switch) {
				$matches = 1;
				last;
			}
		}
		if (!$matches) {
			return 0;
		}
	}
	return 1;
}

# get someones flags from people.pl or friends(_shasta).pl, copied from trigger.pl
sub get_flags {
	my ($chatnet, $channel, $nick, $address) = @_;
	my $flags;
	no strict 'refs';
	if (%{ 'Irssi::Script::people::' }) {
		if ($channel) {
			$flags = (&{ 'Irssi::Script::people::find_local_flags' }($chatnet,$channel,$nick,$address));
		} else {
			$flags = (&{ 'Irssi::Script::people::find_global_flags' }($chatnet,$nick,$address));
		}
		$flags = join('',keys(%{$flags}));
	} else {
		my $shasta;
		if (%{ 'Irssi::Script::friends_shasta::' }) {
			$shasta = 'friends_shasta';
		} elsif (defined &{ 'Irssi::Script::friends::get_idx' }) {
			$shasta = 'friends';
		}
		if (!$shasta) {
			return undef;
		}
		if (defined &{ 'Irssi::Script::'.$shasta.'::get_idx' }) {
			my $idx = (&{ 'Irssi::Script::'.$shasta.'::get_idx' }($nick,$address));
			if ($idx == -1) {
				return '';
			}
			$flags = (&{ 'Irssi::Script::'.$shasta.'::get_friends_flags' }($idx,undef));
			if ($channel) {
				$flags .= (&{ 'Irssi::Script::'.$shasta.'::get_friends_flags' }($idx,$channel));
			}
		}
	}
	return $flags;
}

sub is_friend {
	my ($chatnet, $channel, $nick, $address) = @_;
	no strict 'refs';
	if (%{ 'Irssi::Script::people::' }) {
		return (() != &{'Irssi::Script::people::find_users'}($chatnet, $nick, $address));
		my $flags;
		if ($channel) {
			$flags = (&{ 'Irssi::Script::people::find_local_flags' }($chatnet,$channel,$nick,$address));
		} else {
			$flags = (&{ 'Irssi::Script::people::find_global_flags' }($chatnet,$nick,$address));
		}
		return ($flags ne ''); # TODO: test this
	} else {
		my $shasta;
		if (%{ 'Irssi::Script::friends_shasta::' }) {
			$shasta = 'friends_shasta';
		} elsif (defined &{ 'Irssi::Script::friends::get_idx' }) {
			$shasta = 'friends';
		}
		if (!$shasta) {
			return undef;
		}
		my $get_idx_func="Irssi::Script::".$shasta."::get_idx";
		if (defined &{$get_idx_func}) {
			my $idx = (&$get_idx_func($nick,$address));
			return ($idx != -1);
		}
		return -1;
	}
}	

####################
##### NICKLIST #####
####################

# returns the position of the given nick(as string) in the (internal) nicklist
sub find_nick {
	my ($nick) = @_;
	for (my $i=0;$i < @nicklist; $i++) {
		if ($nicklist[$i]->{'nick'} eq $nick) {
			return $i;
		}
	}
	return -1;
}

# find position where nick should be inserted into the list
sub find_insert_pos {
	my ($cmp)= @_;
	for (my $i=0;$i < @nicklist; $i++) {
		if ($nicklist[$i]->{'cmp'} gt $cmp) {
			return $i;
		}
	}
	return scalar(@nicklist); #last
}

# make the (internal) nicklist (@nicklist)
sub make_nicklist {
	@nicklist = ();
	$scroll_pos = 0;

	### get & check channel ###
	my $channel = Irssi::active_win->{active};

	if (!$channel || (ref($channel) ne 'Irssi::Irc::Channel' && ref($channel) ne 'Irssi::Silc::Channel') || $channel->{'type'} ne 'CHANNEL' || ($channel->{chat_type} ne 'SILC' && !$channel->{'names_got'}) ) {
		$active_channel = undef;
		# no nicklist
	} else {
		$active_channel = $channel;
		### make nicklist ###
		foreach my $nick ($channel->nicks()) {
			my $thisnick = {'nick' => $nick->{'nick'}};
			recalc_nick($thisnick, $nick);
			push @nicklist, $thisnick;
		}
		@nicklist = sort {$a->{'cmp'} cmp $b->{'cmp'}} @nicklist;
	}
	need_redraw();
}

# insert nick(as hash) into nicklist
# pre: cmp has to be calculated
sub insert_nick {
	my ($nick) = @_;
	my $nr = find_insert_pos($nick->{'cmp'});
	splice @nicklist, $nr, 0, $nick;
	draw_insert_nick_nr($nr);
}

# remove nick(as nr) from nicklist
sub remove_nick {
	my ($nr) = @_;
	splice @nicklist, $nr, 1;
	draw_remove_nick_nr($nr);
}

# update the mode and cmp of a nick, based on a nickrec from irssi
sub recalc_nick {
	my ($nick, $nickrec) = @_;
	if (! $nickrec) {
		$nickrec = $active_channel->nick_find($nick->{'nick'});
	}
	
	my $nickflags = $active_channel->{'server'}->get_nick_flags() . ' ';
	
	my $flag = (
		$nickrec->{'op'} ? '@' :
		$nickrec->{'halfop'} ? '%' :
		$nickrec->{'voice'} ? '+' :
		' '
	);
	
	if ($nickrec->{'other'} && index($nickflags, $nick->{'other'}) < index($nickflags, $flag)) {
		$flag = chr($nickrec->{'other'});
	}
	
	$nick->{'modepos'} = index($nickflags, $flag);
	$nick->{'modeflag'} = $flag;
	
	$nick->{'host'} = $nickrec->{'host'};
	calc_text($nick);
}

###################
##### ACTIONS #####
###################

# scroll the nicklist, arg = number of lines to scroll, positive = down, negative = up
sub cmd_scroll {
	if (!$active_channel) { # not a channel active
		return;
	}
	my @nicks=Irssi::active_win->{active}->nicks;
	my $nick_count = scalar(@nicks)+0;
	my $channel = Irssi::active_win->{active};
	if (!$channel || $channel->{type} ne 'CHANNEL' || !$channel->{names_got} || $nick_count <= Irssi::settings_get_int('nicklist_height')) {
		return;
	}
	$scroll_pos += @_[0];

	if ($scroll_pos > $nick_count - $height) {
		$scroll_pos = $nick_count - $height;
	}
	if ($scroll_pos <= 0) {
		$scroll_pos = 0;
	}
	need_redraw();
}

sub is_active_channel {
	my ($server,$channel) = @_; # (channel as string)
	return ($server && $server->{'tag'} eq $active_channel->{'server'}->{'tag'} && $server->channel_find($channel) && $active_channel && $server->channel_find($channel)->{'name'} eq $active_channel->{'name'});
}

sub sig_channel_wholist { # this is actualy a little late, when the names are received would be better
	my ($channel) = @_;
	if (Irssi::active_win->{'active'} && Irssi::active_win->{'active'}->{'name'} eq $channel->{'name'}) { # the channel joined is active
		make_nicklist
	}
}

sub sig_join {
	my ($server,$channel,$nick,$address) = @_;
	if (!is_active_channel($server,$channel)) {
		return;
	}
	my $newnick = {'nick' => $nick};
	recalc_nick($newnick);
	insert_nick($newnick);
}

sub sig_kick {
	my ($server, $channel, $nick, $kicker, $address, $reason) = @_;
	if (!is_active_channel($server,$channel)) {
		return;
	}
	my $nr = find_nick($nick);
	if ($nr == -1) {
		Irssi::print("nicklist warning: $nick was kicked from $channel, but not found in nicklist");
	} else {
		remove_nick($nr);
	}
}

sub sig_part {
	my ($server,$channel,$nick,$address, $reason) = @_;
	if (!is_active_channel($server,$channel)) {
		return;
	}
	my $nr = find_nick($nick);
	if ($nr == -1) {
		Irssi::print("nicklist warning: $nick has parted $channel, but was not found in nicklist");
	} else {
		remove_nick($nr);
	}

}

sub sig_quit {
	my ($server,$nick,$address, $reason) = @_;
	if ($server->{'tag'} ne $active_channel->{'server'}->{'tag'}) {
		return;
	}
	my $nr = find_nick($nick);
	if ($nr != -1) {
		remove_nick($nr);
	}
}

sub sig_nick {
	my ($server, $newnick, $oldnick, $address) = @_;
	if ($server->{'tag'} ne $active_channel->{'server'}->{'tag'}) {
		return;
	}
	my $nr = find_nick($oldnick);
	if ($nr != -1) { # if nick was found (nickchange is in current channel)
		my $nick = $nicklist[$nr];
		remove_nick($nr);
		$nick->{'nick'} = $newnick;
		calc_text($nick);
		insert_nick($nick);
	}
}

sub sig_mode {
	my ($channel, $nick, $setby, $mode, $type) = @_; # (nick and channel as rec)
	if ($channel->{'server'}->{'tag'} ne $active_channel->{'server'}->{'tag'} || $channel->{'name'} ne $active_channel->{'name'}) {
		return;
	}
	my $nr = find_nick($nick->{'nick'});
	if ($nr == -1) {
		Irssi::print("nicklist warning: $nick->{'nick'} had mode set on $channel->{'name'}, but was not found in nicklist");
	} else {
		my $nicklist_item = $nicklist[$nr];
		remove_nick($nr);
		recalc_nick($nicklist_item, $nick);
		insert_nick($nicklist_item);
	}
}

##### command binds #####
Irssi::command_bind 'nicklist' => sub {
    my ( $data, $server, $item ) = @_;
    $data =~ s/\s+$//g;
    Irssi::command_runsub ('nicklist', $data, $server, $item ) ;
};
Irssi::signal_add_first 'default command nicklist' => sub {
	# gets triggered if called with unknown subcommand
	cmd_help();
};
Irssi::command_bind('nicklist update',\&update);
Irssi::command_bind('nicklist help',\&cmd_help);
Irssi::command_bind('nicklist scroll',\&cmd_scroll);
Irssi::command_bind('nicklist fifo',\&cmd_fifo_start);
Irssi::command_bind('nicklist screen',\&cmd_screen_start);
Irssi::command_bind('nicklist screensize',\&screen_size);
Irssi::command_bind('nicklist off',\&cmd_off);

##### signals #####
Irssi::signal_add_last('window item changed', \&make_nicklist);
Irssi::signal_add_last('window changed', \&make_nicklist);
Irssi::signal_add_last('channel wholist', \&sig_channel_wholist);
Irssi::signal_add_first('message join', \&sig_join); # first, to be before ignores
Irssi::signal_add_first('message part', \&sig_part);
Irssi::signal_add_first('message kick', \&sig_kick);
Irssi::signal_add_first('message quit', \&sig_quit);
Irssi::signal_add_first('message nick', \&sig_nick);
Irssi::signal_add_first('message own_nick', \&sig_nick);
Irssi::signal_add_first('nick mode changed', \&sig_mode);

Irssi::signal_add('setup changed', \&read_settings);

##### settings #####
Irssi::settings_add_str('nicklist', 'nicklist_screen_prefix', '\e[m ');
Irssi::settings_add_str('nicklist', 'nicklist_prefix_mode_op', '\e[32m@\e[39m');
Irssi::settings_add_str('nicklist', 'nicklist_prefix_mode_halfop', '\e[34m%\e[39m');
Irssi::settings_add_str('nicklist', 'nicklist_prefix_mode_voice', '\e[33m+\e[39m');
Irssi::settings_add_str('nicklist', 'nicklist_prefix_mode_normal', ' ');
Irssi::settings_add_str('nicklist', 'nicklist_prefix_mode_other', '&=\e[31m&\e[39m ~=\e[35m~\e[39m');
Irssi::settings_add_str('nicklist', 'nicklist_prefix_friends', 'o=\e[32m v=\e[33m noflag=\e[1m');

Irssi::settings_add_int('nicklist', 'nicklist_width',11);
Irssi::settings_add_int('nicklist', 'nicklist_height',24);
Irssi::settings_add_str('nicklist', 'nicklist_fifo_path', Irssi::get_irssi_dir . '/nicklistfifo');
Irssi::settings_add_str('nicklist', 'nicklist_screen_split_windows', '');
Irssi::settings_add_str('nicklist', 'nicklist_automode', '');

read_settings();
if (uc(Irssi::settings_get_str('nicklist_automode')) eq 'SCREEN') {
	cmd_screen_start();
} elsif (uc(Irssi::settings_get_str('nicklist_automode')) eq 'FIFO') {
	cmd_fifo_start();
}
