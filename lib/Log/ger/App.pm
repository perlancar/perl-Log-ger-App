package Log::ger::App;

# DATE
# VERSION

# IFUNBUILT
use strict;
use warnings;
# END IFUNBUILT

our %PATTERN_STYLES = (
    plain             => '%m',
    plain_nl          => '%m%n',
    script_short      => '[%r] %m%n',
    script_long       => '[%d] %m%n',
    daemon            => '[pid %P] [%d] %m%n',
    syslog            => '[pid %p] %m',
);

sub _level_from_env {
    my $prefix = shift;
    return $ENV{"${prefix}LOG_LEVEL"} if defined $ENV{"${prefix}LOG_LEVEL"};
    return 'trace' if $ENV{"${prefix}TRACE"};
    return 'debug' if $ENV{"${prefix}DEBUG"};
    return 'info'  if $ENV{"${prefix}VERBOSE"};
    return 'error' if $ENV{"${prefix}QUIET"};
    undef;
}

sub _is_daemon {
    return $main::IS_DAEMON if defined $main::IS_DAEMON;
    for (
        "App/Daemon.pm",
        "Daemon/Easy.pm",
        "Daemon/Daemonize.pm",
        "Daemon/Generic.pm",
        "Daemonise.pm",
        "Daemon/Simple.pm",
        "HTTP/Daemon.pm",
        "IO/Socket/INET/Daemon.pm",
        #"Mojo/Server/Daemon.pm", # simply loading Mojo::UserAgent will load this too
        "MooseX/Daemonize.pm",
        "Net/Daemon.pm",
        "Net/Server.pm",
        "Proc/Daemon.pm",
        "Proc/PID/File.pm",
        "Win32/Daemon/Simple.pm") {
        return 1 if $INC{$_};
    }
    0;
}

sub import {
    my ($pkg, %args) = @_;

    require Log::ger;
    require Log::ger::Util;

    my $level = Log::ger::Util::numeric_level(_level_from_env("") || 'warn');
    $Log::ger::Current_Level = $level;

    my $is_daemon = $args{daemon};
    $is_daemon = if !defined($is_daemon);

    my $progname = $args{name};
    unless (defined $progname) {
        ($progname = $0) =~ s!.+/!!;
        $progname =~ s/\.pl$//;
    }
    unless (length $progname) {
        $progname = "prog";
    }

    # configuration for Log::ger::Output::Composite
    my %conf = (
        outputs => [],
    );

    # add Screen
    unless ($is_daemon) {
        $conf{outputs}{Screen} = {};
    }

    # add File
    unless ($0 eq '-') {
        require PERLANCAR::File::HomeDir;
        my $path = $> ?
            PERLANCAR::File::HomeDir::get_my_home_dir()."/$progname.log" :
              "/var/log/$progname.log";
        $conf{outputs}{File} = {
            path => $path,
        };
    }

    # add Syslog
    if ($is_daemon) {
        $conf{outputs}{Syslog} = {
            ident => $progname,
            facility => 'daemon',
        };
    }

    require Log::ger::Plugin;
    Log::ger::Plugin->set('Composite', %conf);
}

1;
# ABSTRACT: An easy way to use Log::ger in applications

=head1 SYNOPSIS

 use Log::ger::App;


=head1 DESCRIPTION

This module sets up sensible defaults for L<Log::ger::Output::Composite> from
the environment variables.

B<Outputs:>

 Code                            Screen  File                   Syslog
 ------------------------------  ------  ----                   ------
 One-liner (-e)                  y       -                      -
 Script running as normal user   y       ~/PROGNAME.log         -
 Script running as root          y       /var/log/PROGNAME.log  -
 Daemon                          -       /var/log/PROGNAME.log  y

B<General log level:> the default is warn (like L<Log::ger>'s default). You can
set it from environment using L<LOG_LEVEL> (e.g. C<LOG_LEVEL=trace> to set level
to trace or L<LOG_LEVEL=0> to turn off logging). Alternatively, you can set to
trace using C<TRACE=1>, or debug with C<DEBUG=1>, info with C<VERBOSE=1>, error
with C<QUIET=1>.

B<Per-output level:> the default is to use general level, but you can set a
different level using I<OUTPUT_NAME>_{C<LOG_LEVEL|TRACE|DEBUG|VERBOSE|QUIET>}.


=head1 FUNCTIONS

=head2 $pkg->import(%args)

Arguments:

=over

=item * name => str

Explicitly set program name. Otherwise, default will be taken from C<$0> (after
path and '.pl' suffix is removed) or set to C<prog>.

=item * daemon => bool

Explicitly tell Log::ger::App that your application is a daemon or not.
Otherwise, Log::ger::App will try some heuristics to guess whether your
application is a daemon: from the value of C<$main::IS_DAEMON> and from the
presence of modules like L<HTTP::Daemon>, L<Proc::Daemon>, etc.

=back


=head1 ENVIRONMENT

=head2 LOG_LEVEL => str

Can be set to C<off> or numeric/string log level.

=head2 TRACE => bool

=head2 DEBUG => bool

=head2 VERBOSE => bool

=head2 QUIET => bool

=head2 SCREEN_LOG_LEVEL

=head2 SCREEN_TRACE

=head2 SCREEN_DEBUG

=head2 SCREEN_VERBOSE

=head2 SCREEN_QUIET

=head2 FILE_LOG_LEVEL

=head2 FILE_TRACE

=head2 FILE_DEBUG

=head2 FILE_VERBOSE

=head2 FILE_QUIET

=head2 SYSLOG_LOG_LEVEL

=head2 SYSLOG_TRACE

=head2 SYSLOG_DEBUG

=head2 SYSLOG_VERBOSE

=head2 SYSLOG_QUIET


=head1 SEE ALSO

L<Log::ger>
