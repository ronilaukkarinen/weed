# based on the nicklist.pl script
################################################################################
#                               tmux_nicklist.pl                               
# This script integrates tmux and irssi to display a list of nicks in a       
# vertical right pane with 20% width. Right now theres no configuration
# or setup, simply initialize the script with irssi and by default you
# will get the nicklist for every channel(customize by altering 
# the regex in '$channel_pattern'.
#
# It supports mouse scrolling and the following keys:
# k/up arrow: up one line
# j/down arrow: down one line
# pageup: up 20 lines
# pagedown: down 20 lines
# gg: go to top
# G: go to bottom
#
# For better integration, unrecognized sequences will be sent to irssi and
# its pane will be focused.
################################################################################

use strict;
use IO::Handle;
use IO::Select;
use POSIX;
use File::Temp qw/ :mktemp  /;
use File::Basename;
use vars qw($VERSION %IRSSI);
$VERSION = '0.0.0';
%IRSSI = (
  authors     => 'Thiago de Arruda',
  contact     => 'tpadilha84@gmail.com',
  name        => 'tmux-nicklist',
  description => 'displays a list of nicks in a separate tmux pane',
  license     => 'WTFPL',
);

if ($#ARGV == -1) {
require Irssi;

my $enabled = 0;
my $script_path = __FILE__;
my $tmpdir;
my $fifo_path; 
# my $channel_pattern = '^&bitlbee$';
my $channel_pattern = '^.+$';

sub enable_nicklist {
  return if ($enabled);
  $tmpdir = mkdtemp "/tmp/nicklist-XXXXXXXX";
  $fifo_path = "$tmpdir/fifo";
  POSIX::mkfifo($fifo_path, 0600) or die "can\'t mkfifo $fifo_path: $!";
  my $cmd = "perl $script_path $fifo_path $ENV{'TMUX_PANE'}";
  system('tmux', 'split-window', '-dh', '-p', '20', $cmd);
  # The next system call will block until the other pane has opened the pipe
  # for reading, so synchronization is not an issue here.
  open (FIFO, "> $fifo_path") or die "can't open $fifo_path: $!";
  FIFO->autoflush(1);
  $enabled = 1;
}

sub disable_nicklist {
  return unless ($enabled);
  print(FIFO "EXIT\n");
  close FIFO;
  unlink $fifo_path;
  rmdir $tmpdir;
  $enabled = 0;
}

sub reset_nicklist {
  my $active = Irssi::active_win();
  my $channel = $active->{active};

  if ((!$channel ||
      (ref($channel) ne 'Irssi::Irc::Channel' && ref($channel) ne
        'Irssi::Silc::Channel') || $channel->{'type'} ne 'CHANNEL' ||
      ($channel->{chat_type} ne 'SILC' && !$channel->{'names_got'})) ||
    ($channel->{'name'} !~ /$channel_pattern/ )) {
    disable_nicklist;
  } else {
    enable_nicklist;
    print(FIFO "BEGIN\n");
    foreach my $nick (sort {(($a->{'op'}?'1':$a->{'halfop'}?'2':$a->{'voice'}?'3':'4').lc($a->{'nick'}))
      cmp (($b->{'op'}?'1':$b->{'halfop'}?'2':$b->{'voice'}?'3':'4').lc($b->{'nick'}))} $channel->nicks()) {
      print(FIFO "NICK");
      if ($nick->{'op'}) {
        print(FIFO "\e[32m\@$nick->{'nick'}\e[39m");
      } elsif ($nick->{'halfop'}) {
        print(FIFO "\e[34m%$nick->{'nick'}\e[39m");
      } elsif ($nick->{'voice'}) {
        print(FIFO "\e[33m+$nick->{'nick'}\e[39m");
      } else {
        print(FIFO " $nick->{'nick'}");
      }
      print(FIFO "\n");
    }
    print(FIFO "END\n");
  }
}

sub switch_channel {
  print(FIFO "SWITCH_CHANNEL\n");
  reset_nicklist;
}

Irssi::signal_add_last('window item changed', \&switch_channel);
Irssi::signal_add_last('window changed', \&switch_channel);
Irssi::signal_add_last('channel wholist', \&reset_nicklist);
# first, to be before ignores
Irssi::signal_add_first('message join', \&reset_nicklist);
Irssi::signal_add_first('message part', \&reset_nicklist);
Irssi::signal_add_first('message kick', \&reset_nicklist);
Irssi::signal_add_first('message quit', \&reset_nicklist);
Irssi::signal_add_first('message nick', \&reset_nicklist);
Irssi::signal_add_first('message own_nick', \&reset_nicklist);
Irssi::signal_add_first('nick mode changed', \&reset_nicklist);
Irssi::signal_add('gui exit', \&disable_nicklist);

} else {
require 'sys/ioctl.ph';
# open STDERR, '>', "$ENV{'HOME'}/.nickbar-errors.log";
my $fifo_path = $ARGV[0];
my $irssi_pane = $ARGV[1];
# array to store the current channel nicknames
my @nicknames = ();

# helper functions for manipulating the terminal
# escape sequences taken from
# http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/x361.html
sub clear_screen { print "\e[2J"; }
sub save_cursor { print "\e[s"; }
sub restore_cursor { print "\e[u"; }
sub enable_mouse { print "\e[?1000h"; }
# recognized sequences
my $MOUSE_SCROLL_DOWN="\e[Ma";
my $MOUSE_SCROLL_UP="\e[M`";
my $ARROW_DOWN="\e[B";
my $ARROW_UP="\e[A";
my $UP="k";
my $DOWN="j";
my $PAGE_DOWN="\e[6~";
my $PAGE_UP="\e[5~";
my $GO_TOP="gg";
my $GO_BOTTOM="G";

my $current_line = 0;
my $sequence = '';

sub term_row_count {
  # from http://stackoverflow.com/questions/4286158/how-do-i-get-width-and-height-of-my-terminal-with-ioctl
  my $terminal_size;
  ioctl(STDOUT, TIOCGWINSZ() , $terminal_size);
  my ($rows, $cols, $xpix, $ypix) = unpack 'S4', $terminal_size;
  return $rows;
}

sub redraw {
  my $rows = term_row_count;
  my $last_nick_idx = $#nicknames;
  my $last_idx = $current_line + $rows;
  # normalize last visible index
  if ($last_idx > ($last_nick_idx)) {
    $last_idx = $last_nick_idx;
  }
  # redraw visible nicks
  restore_cursor;
  clear_screen;
  for (my $idx = $current_line; $idx <= $last_idx; $idx++) {
    print "$nicknames[$idx]\n";
  }
}

sub move_down {
  $sequence = '';
  my $count = $_[0];
  my $nickcount = $#nicknames;
  my $rows = term_row_count;
  return if ($nickcount <= $rows);
  if ($count == -1) {
    $current_line = $nickcount - $rows - 1;
    redraw;
    return;
  }
  my $visible = $nickcount - $current_line - $count;
  if ($visible > $rows) {
    $current_line += $count;
    redraw;
  } elsif (($visible + $count) > $rows) {
    # scroll the maximum we can
    $current_line = $nickcount - $rows - 1;
    redraw;
  }
}

sub move_up {
  $sequence = '';
  my $count = $_[0];
  if ($count == -1) {
    $current_line = 0;
    redraw;
    return;
  }
  return if ($current_line == 0);
  if (($current_line - $count) >= 0) {
    $current_line -= $count;
    redraw;
  }
}

$SIG{INT} = 'IGNORE';

# setup terminal so we can listen for individual key presses without echo
my ($term, $oterm, $echo, $noecho, $fd_stdin);
$fd_stdin = fileno(STDIN);
$term = POSIX::Termios->new();
$term->getattr($fd_stdin);
$oterm = $term->getlflag();
$echo = ECHO | ECHOK | ICANON;
$noecho = $oterm & ~$echo;
$term->setlflag($noecho);
$term->setcc(VTIME, 1);
$term->setattr($fd_stdin, TCSANOW);

# open named pipe and setup the 'select' wrapper object for listening on both
# fds(fifo and sdtin)
open (FIFO, "< $fifo_path") or die "can't open $fifo_path: $!";
my $fifo = \*FIFO;
my $stdin = \*STDIN;
my $select = IO::Select->new();
my @ready;
$select->add($fifo);
$select->add($stdin);

save_cursor;
enable_mouse;
system('tput', 'civis');
MAIN: {
  while (@ready = $select->can_read) {
    foreach my $fd (@ready) {
      if ($fd == $fifo) {
        while (<$fifo>) {
          my $line = $_;
          if ($line =~ /^BEGIN/) {
            @nicknames = ();
          } elsif ($line =~ /^SWITCH_CHANNEL/) {
            $current_line = 0;
          } elsif ($line =~ /^NICK(.+)$/) {
            push @nicknames, $1;
          } elsif ($line =~ /^END$/) {
            redraw;
            last; 
          } elsif ($line =~ /^EXIT$/) {
            last MAIN;
          }
        }
      } else {
        my $key = '';
        sysread(STDIN, $key, 1);
        $sequence .= $key;
        if ($MOUSE_SCROLL_DOWN =~ /^\Q$sequence\E/) {
          if ($MOUSE_SCROLL_DOWN eq $sequence) {
            move_down 3; 
            # mouse scroll has two more bytes that I dont use here
            # so consume them now to avoid sending unwanted bytes to
            # irssi
            sysread(STDIN, $key, 2);
          }
        } elsif ($MOUSE_SCROLL_UP =~ /^\Q$sequence\E/) {
          if ($MOUSE_SCROLL_UP eq $sequence) {
            move_up 3; 
            sysread(STDIN, $key, 2);
          }
        } elsif ($ARROW_DOWN =~ /^\Q$sequence\E/) {
          move_down 1 if ($ARROW_DOWN eq $sequence);
        } elsif ($ARROW_UP =~ /^\Q$sequence\E/) {
          move_up 1 if ($ARROW_UP eq $sequence);
        } elsif ($DOWN =~ /^\Q$sequence\E/) {
          move_down 1 if ($DOWN eq $sequence);
        } elsif ($UP =~ /^\Q$sequence\E/) {
          move_up 1 if ($UP eq $sequence);
        } elsif ($PAGE_DOWN =~ /^\Q$sequence\E/) {
          move_down 20 if ($PAGE_DOWN eq $sequence);
        } elsif ($PAGE_UP =~ /^\Q$sequence\E/) {
          move_up 20 if ($PAGE_UP eq $sequence);
        } elsif ($GO_BOTTOM =~ /^\Q$sequence\E/) {
          move_down -1 if ($GO_BOTTOM eq $sequence);
        } elsif ($GO_TOP =~ /^\Q$sequence\E/) {
          move_up -1 if ($GO_TOP eq $sequence);
        } else {
          # Unrecognized sequences will be send to irssi and its pane
          # will be focused
          system('tmux', 'send-keys', '-l', '-t', $irssi_pane, $sequence);
          system('tmux', 'select-pane', '-t', $irssi_pane);
          $sequence = '';
        }
      }
    }
  }
}

close FIFO;

}
