use strict;

# Constants OK, WARNING, CRITICAL, and UNKNOWN are exported by default
# See also Nagios::Plugin::Functions for a functional interface
use Nagios::Plugin;
use Time::HiRes qw(gettimeofday tv_interval);

# Constructor
# use Nagios::Plugin::Getopt to process the @ARGV command line options:
#   --verbose, --help, --usage, --timeout and --host are defined automatically.
my $np =
  Nagios::Plugin->new( usage => "Usage: %s [-v|--verbose]  [-t <timeout>] "
	  . "[-c|--critical=<threshold>] [-w|--warning=<threshold>] [-s|--string=<string>] [-r|--regex=<string>] --wget=\"<wget arguments>\"",
  );
$np->add_arg(
	spec => 'critical|c=i',
	help => 'Critical time threshold; default to 60s',
);
$np->add_arg(
	spec => 'regex|r=s',
	help => 'Search page for regex STRING',
);
$np->add_arg(
	spec => 'string|s=s',
	help => 'String to expect in the content',
);
$np->add_arg(
	spec     => 'wget=s',
	help     => 'Arguments passed to wget',
	required => 1,
);
$np->add_arg(
	spec => 'warning|w=i',
	help => 'Warning time threshold; default to 15s',
);
$np->getopts;
my $wgetopt   = $np->opts->wget;
my $start     = [gettimeofday];
my $result    = `wget -qO- $wgetopt`;
my $resultLen = length($result);
my $duration  = tv_interval($start);

if ( $np->opts->string && index( $result, $np->opts->string ) == -1 ) {
	$np->add_message( CRITICAL,
		"string \"" . $np->opts->string . "\" not found" );
}

if ( $np->opts->regex && $result !~ $np->opts->regex ) {
	$np->add_message( CRITICAL,
		"pattern \"" . $np->opts->regex . "\" not found" );
}

# Threshold methods
$np->set_thresholds(
	warning  => $np->opts->warning  || 15,
	critical => $np->opts->critical || 60,
);
my $code = $np->check_threshold($duration);
$np->add_message( $code,
	"$resultLen bytes in $duration seconds response time" );

$np->add_perfdata(
	label     => "time",
	value     => $duration,
	uom       => "s",
	threshold => $np->threshold(),
);

my ( $retCode, $message ) = $np->check_messages();
$np->nagios_exit( $retCode, $message );