use strict;
use vars qw($VERSION %IRSSI);
use Irssi;
use Irssi::Irc;
use feature 'switch';

# Usage:
# /script load go.pl
# If you are in #irssi you can type /go #irssi or /go irssi or even /go ir ...
# also try /go ir<tab> and /go  <tab> (that's two spaces)

$VERSION = '2.00';

%IRSSI = (
	authors     => 'nohar and eboyjr',
	contact     => 'nohar on freenode and eboyjr14@gmail.com',
	name        => 'go to window',
	description => 'Implements /go command that activates a window given a number/name/partial name. It features a nice completion.',
	license     => 'GPLv2 or later',
	changed     => '07-28-11'
);

sub signal_complete_go {
	my ($complist, $window, $word, $linestart, $want_space) = @_;
	my $channel = $window->get_active_name();
	my $k = Irssi::parse_special('$k');

	return unless ($linestart =~ /^\Q${k}\Ego/i);

	@$complist = ();
	foreach my $w (Irssi::windows) {
		my $name = $w->get_active_name();
		if ($word ne "") {
			if ($name =~ /\Q${word}\E/i) {
				push(@$complist, $name)
			}
		} else {
			push(@$complist, $name);
		}
	}
	Irssi::signal_stop();
}

sub go_ill_pick
{
	# Wow I almost ported the window_highest_activity function
	# But I didn't. Thanks to NChief in #irssi on freenode
	Irssi::command("window goto active");
}

sub go_set_active
{
	my($window) = @_;
	
	if (Irssi::active_win()->{refnum} == $window->{refnum}) {
		my $wname = $window->get_active_name();
		Irssi::active_win()->print("Window `$wname` is already active.");
		return;
	}
	
	$window->set_active();
};

sub cmd_go
{
	my($chan,$server,$witem) = @_;
	
	$chan =~ s/^\s+|\s+$//g;
	
	return go_ill_pick() if $chan eq "";
	
	# First check for windows accessed by number
	if ($chan =~ /^\d+$/) {
		my $w = Irssi::window_find_refnum($chan);
		if ($w) {
			$w->set_active();
			return;
		}
	}

	my ($alt_1st, $alt_2nd);
	
	foreach my $w (Irssi::windows) {
		my $name = $w->get_active_name();

		given ($name) {
		
			# Next check for perfect matches
			when (/^\W*\Q${chan}\E$/i) {
				go_set_active($w);
				return;
			}
			
			# Check for partial beginning matches that we can use later
			when (!$alt_1st && /^\W*\Q${chan}\E/i) {
				$alt_1st = $w;
			}
			
			# Also check for partial matches anywhere that we can use later
			when (!$alt_2nd && /\Q${chan}\E/i) {
				$alt_2nd = $w;
			}
		}
	}

	if ($alt_1st) {
		go_set_active($alt_1st);
		return;
	}

	if ($alt_2nd) {
		go_set_active($alt_2nd);
		return;
	}
	
	# If window was not found, let me know
	Irssi::active_win()->print("No window available matching `$chan`.");
}


Irssi::command_bind("go", "cmd_go");
Irssi::signal_add_first('complete word', 'signal_complete_go');
