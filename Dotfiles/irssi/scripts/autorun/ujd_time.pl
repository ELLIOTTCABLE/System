# This script quite simply adds UJD (http://yreality.net/UJD) timestamps to irssi.

# It provides two configuration settings: ujd_integral_digits and ujd_fractional_digits.

# You might want to modify the timeout at the bottom of this file (it’s in milliseconds)
# if this uses too much CPU for your tastes.

use Irssi;
use Irssi::TextUI;

use Time::HiRes 'time';


use vars qw($VERSION %IRSSI);

$VERSION="1";
%IRSSI = (
  authors       => 'elliottcable'
, contact       => 'ujd_time.pl@elliottcable.name'
, name          => 'ujd_time'
, description   => 'Prints the timestamp in UJD format'
, license       => 'Public Domain'
, url           => 'http://gist.github.com/1082336'
);

my $old_timestamp_format = Irssi::settings_get_str('timestamp_format');
my $timeout = undef;

sub update_ujd {
  my $integral_digits = Irssi::settings_get_int('ujd_integral_digits');
  my $fractional_digits = Irssi::settings_get_int('ujd_fractional_digits');
  my $time = time / 86400;
  
  my ($integral, $fractional) = split(/\./, sprintf("%.0${fractional_digits}f", $time));
  my $integral = $integral % (10 ** $integral_digits);
  
  my $fractional = join(' ', $fractional =~ /\d{1,3}/g);
  my $integral = reverse(join(' ', reverse($integral) =~ /\d{1,3}/g));
  
  Irssi::command("^set timestamp_format $integral ſ $fractional");
  Irssi::statusbar_items_redraw('time');

  my $timeout = int(86400000 * 10**(-$fractional_digits) / 3);
     $timeout = 10 if $timeout < 10;
  Irssi::timeout_add_once($timeout, update_ujd, undef);
}

sub script_unload {
  my ($script,$server,$witem) = @_;
  Irssi::command("^set timestamp_format $old_timestamp_format");
}

Irssi::settings_add_int('misc', 'ujd_integral_digits', 1);
Irssi::settings_add_int('misc', 'ujd_fractional_digits', 6);

Irssi::signal_add_first('command script unload', 'script_unload');
&update_ujd;
