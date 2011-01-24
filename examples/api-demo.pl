#!/usr/bin/perl
#
#   Finance::InteractiveBrokers::SWIG - API demonstration program
#
#   (c) 2010-2011 Jason McManus
#
#   This demonstration program shows how to use the F::IB::SWIG
#   package to work with the IB API, and receive events.
#
#   Steps:
#   ------
#   0. Set up either the IB Gateway or the TradeWorkstation interface.
#      (see the IB API documentation for details.  The API must use one
#      of these to connect to their service.
#   1. Subclass Finance::InteractiveBrokers::SWIG::EventHandler, create
#      actions for its events, and instantiate an object.
#   2. Call Finance::InteractiveBrokers::SWIG->new, and give it your
#      handler.
#   3. Call ->eConnect( $host, $port, $id ) giving it the host and
#      port of your IB Gateway or TWS server.
#   4. Set up an event loop calling ->processMessages() each time
#      through, so that your event handlers will be called.
#   5. When the event loop is through, call ->eDisconnect() to hang up
#      politely.
#

use Data::Dumper;
use strict;
use warnings;
use vars qw( $VERSION );
BEGIN {
    $VERSION = '0.01_01';
}

# Ours
use Finance::InteractiveBrokers::SWIG;
use lib '.';
use MyEventHandler;
$|=1;

###
### Variables
###

my $ibhost      = 'localhost';  # Set to your IB gateway or TWS host
my $ibport      = 4001;         # Set to your IB gateway or TWS port
my $clientId    = 42;           # Some random number as a client ID

my $wantstoexit = 0;            # Flag to check for ^C; ignore this

###
### Main
###

#
# 1. Create our event handler object to react to incoming events
#    (You can see MyEventHandler.pm in this same directory.)
#
my $handler = MyEventHandler->new();

#
# 2. Create a F::IB::SWIG object so we can make requests
#
my $ibapi = Finance::InteractiveBrokers::SWIG->new(
    handler => $handler,
);

#
# 3. Tell the API to connect to the IB Gateway or TWS host
#
print "Connecting to $ibhost:$ibport with clientID = $clientId...";

if( $ibapi->eConnect( $ibhost, $ibport, $clientId ) ) {
    print "Connected!\n";
} else {
    die "\nConnection to $ibhost:$ibport failed.";
}

#
# Let's set up a signal handler to catch ^C (SIGINT) events
#
$SIG{INT} = sub { $wantstoexit = 1; };

#
# Let's request the current time on the server
#
print "Sending request for current server time.\n";

$ibapi->reqCurrentTime();

#
# 4. MAIN EVENT LOOP; keep going in here until ^C is pressed
#
print "\nLooping to wait for server responses (^C to exit)...\n";

while( $ibapi->isConnected() and not $wantstoexit )
{
    $ibapi->processMessages();
}

#
# 5. Someone wanted to exit, let's clean up nicely.
#
$ibapi->eDisconnect() if( $ibapi->isConnected() );

#
# Bye!
#
exit( 0 );

__END__

