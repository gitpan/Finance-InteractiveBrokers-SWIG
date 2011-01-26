package MyEventHandler;
#
#   Finance::InteractiveBrokers::SWIG - Demonstration event handler subclass
#
#   Copyright (c) 2010-2011 Jason McManus
#
#   To use this module:
#
#     Insert your code into the event handler subroutine skeletons.  These
#     will be triggered upon receiving the responses from the IB server,
#     at the appropriate times, according to their API documentation.
#
#     Fill them to do whatever you need to do to react to the event, e.g.
#     store data into a database, set a flag, execute a trade, etc.
#
#   NOTE: You /should/ double-check to make sure that all of the events
#     subroutines exist for the version of the API you compiled against.
#
#     You can get a list of events by typing:
#       
#       perl -MFinance::InteractiveBrokers::SWIG::EventHandler -e'print Finance::InteractiveBrokers::SWIG::EventHandler::override'
#
#     at your shell prompt.
#
#     Since IB updates its API regularly, if you compile against a newer
#     version, it's possible that some events may not be caught below, at
#     which point you will receive an exception that looks like:
#
#       Finance::InteractiveBrokers::SWIG::EventHandler::EVENTNAME method
#          must be overridden
#        at line ....
#

use Carp qw( croak confess );
use strict;
use warnings;
use vars qw( $VERSION );
BEGIN {
    $VERSION = '0.02';
}

# Ours
use base qw( Finance::InteractiveBrokers::SWIG::EventHandler );

###
### Event handlers
###
### These will be called by Finance::InteractiveBrokers::SWIG when it
### receives the specified event from the server.  They will be called
### with their arguments in the same order as in the IB API documentation.
###
### Only a few methods are filled in for you, but this class will
### operate as a proper handler, and simply discard the events sent to
### the empty subs.  It is up to you to fill them in.
###
### Please see the InteractiveBrokers API documentation regarding EWrapper
### for a full description and list of arguments for each method.
###

#
# Connection and Server
#
sub winError
{
    my( $str, $lastError ) = @_;

    print "Client Error $lastError: $str\n";

    return;
}

sub error
{
    my( $id, $errorCode, $errorString ) = @_;

    print "RequestID $id has given server error $errorCode: $errorString\n";

    return;
}

sub connectionClosed
{
    print "Connection closed.\n";

    return;
}

sub currentTime
{
    my( $time ) = @_;

    printf "Current time on IB server is: %s\n", scalar gmtime( $time );

    return;
}

#
# Market Data
#
sub tickPrice
{}
sub tickSize
{}
sub tickOptionComputation
{}
sub tickGeneric
{}
sub tickString
{}
sub tickEFP
{}
sub tickSnapshotEnd
{}

#
# Orders
#
sub orderStatus
{}
sub openOrder
{}
sub nextValidId
{}

#
# Account and Portfolio
#
sub updateAccountValue
{}
sub updatePortfolio
{}
sub updateAccountTime
{}

#
# News Bulletins
#
sub updateNewsBulletin
{}

#
# Contract Details
#
sub contractDetails
{}
sub contractDetailsEnd
{}
sub bondContractDetails
{}

#
# Executions
#
sub execDetails
{}
sub execDetailsEnd
{}

#
# Market Depth
#
sub updateMktDepth
{}
sub updateMktDepthL2
{}

#
# Financial Advisors
#
sub managedAccounts
{}
sub receiveFA
{}

# 
# Historical Data
#
sub historicalData
{}

#
# Market Scanners
#
sub scannerParameters
{}
sub scannerData
{}
sub scannerDataEnd
{}

#
# Real Time Bars
#
sub realtimeBar
{}

#
# Fundamental Data
#
sub fundamentalData
{}

#
# This has something to do with RFQs
#
sub deltaNeutralValidation
{}

#
# These are in the headers, but not documented in the IB API docs.
#
sub openOrderEnd
{}
sub accountDownloadEnd
{}

1;

__END__
