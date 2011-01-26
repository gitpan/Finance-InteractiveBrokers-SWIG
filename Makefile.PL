#
#   Finance::InteractiveBrokers::SWIG - Perl makefile maker
#
#   (c) 2010-2011 Jason McManus
#

use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec ();
use Config ();
use Carp qw( croak confess );
$|=1;

use vars qw( $VERSION $TRUE $FALSE );
BEGIN {
	$VERSION = '0.02';
}

*TRUE    = \1;
*FALSE   = \0;

my $min_SWIG_version = '1.3.36';

# Check for F::IB::API
eval {
	require Finance::InteractiveBrokers::API;
};
croak( '*' x 76 . "\n" .
	   '  Cannot find Finance::InteractiveBrokers::API, required for this' .
       " build.\n  Please install it from CPAN before continuing.\n" .
	   '*' x 76 . "\n " )
	if( $@ );

##########################################################################
### Collect some configuration information from the user
##########################################################################

print <<"EOM";

==========================================================================
      Welcome to the Perl Finance::InteractiveBrokers::SWIG package
==========================================================================

We need to gather some information before continuing the build process.

This module is very complex, and thus you should consult the documentation
before using it.

Press ENTER at any prompt to accept the [default] value.
EOM


###########################
### Find the swig binary
###########################

print <<"EOM";

---------------------------------------
               SWIG:
---------------------------------------

This build requires SWIG (the Simplified Wrapper and Interface Generator)
for building the connection to the IB libraries.

If it is not installed, you can get it at: http://www.swig.org/

EOM

# Find and verify if location of SWIG binary
my $SWIG_PATH = prompt( "Enter the full path to your 'swig' executable:\n",
					    find_bin( 'swig' ) );

# Skip installation running under CPANTesters and no SWIG
if( $ENV{AUTOMATED_TESTING} and not $SWIG_PATH )
{
	print "\nA working installation of SWIG is required for this module.\n\n";
	print "Thanks anyway, testers!\n\n";
	exit( 0 );
}

# Check SWIG version >= $min_SWIG_version
die "\nYour SWIG will NOT work; please (re)install a version newer than $min_SWIG_version.\n "
	unless check_swig_version( $SWIG_PATH );


###########################
### Find the API files
###########################

print <<"EOM";

---------------------------------------
  InteractiveBrokers API Source Code:
---------------------------------------

To build this module, you must have the InteractiveBrokers API source code
somewhere on your system.

We're going to try to locate it.

EOM

my( $LIBPATH, $IB_BUILD_PATH );

print " * Checking the IB_LIBRARY_PATH and IB_BUILD_PATH envvars... ";

if( ( $LIBPATH = found_api( $ENV{IB_BUILD_PATH} ) ) or
	( $LIBPATH = found_api( $ENV{IB_LIBRARY_PATH} ) ) )
{
	print "Found it!\n";
}
else
{
	# Next, try to find it via ibapi-config
	print "Nope.\n\n * Trying 'ibapi-config --path'... ";
	undef $LIBPATH;
	if( my $ibapiconfig = find_bin( 'ibapi-config' ) )
	{
		$LIBPATH = `$ibapiconfig --path`;
		chomp $LIBPATH;
	}
	if( found_api( $LIBPATH ) )
	{
		print "Found it!\n";
	}
	else
	{
		# Next, try to find it via Alien::InteractiveBrokers
		print "Nope.\n\n * Checking if we can use Alien::InteractiveBrokers... ";
		undef $LIBPATH;
		eval {
			require Alien::InteractiveBrokers;
			$LIBPATH = Alien::InteractiveBrokers::path();
		};
		if( found_api( $LIBPATH ) )
		{
			print "Yep!\n";
		}
		else
		{
			print "Nope.\n";
			undef $LIBPATH;
		}
	}
}

if( $LIBPATH )
{
    my $api_ver_num = get_api_version( $LIBPATH );
    print <<"EOM";

We have found the IB API source (version $api_ver_num) in:
  $LIBPATH

You may change locations now if you need to (otherwise just press ENTER).

EOM
}

my $NEWLIBPATH = prompt( "Enter the path to the IB source code:\n", 
                         $LIBPATH );

if( ( $NEWLIBPATH ne $LIBPATH ) and
    ( ! found_api( $NEWLIBPATH ) ) )
{
    print <<"EOM";

Could not find the IB source code in $NEWLIBPATH !
This package requires the header files provided by InteractiveBrokers.
Please read this module's documentation for more information.

EOM
    die "Cannot continue without IB source code..";
}
else
{
    # Check if we can use that API version
    can_use_api_version( get_api_version( $NEWLIBPATH ) );

    print <<"EOM";

IB_BUILD_PATH has been set to '$NEWLIBPATH'.

EOM
    # Now set the env to whatever they entered
    $IB_BUILD_PATH = $NEWLIBPATH
}


##########################################################################
### Build the Makefile
##########################################################################

#$Verbose = 1;
WriteMakefile(
    NAME                => 'Finance::InteractiveBrokers::SWIG',
    AUTHOR              => q{Jason McManus <infidel AT cpan.org>},
    VERSION_FROM        => 'lib/Finance/InteractiveBrokers/SWIG.pm',
    ABSTRACT_FROM       => 'lib/Finance/InteractiveBrokers/SWIG.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'                        => 0,
        'Finance::InteractiveBrokers::API'  => 0,
    },
    BUILD_REQUIRES => {
        'Finance::InteractiveBrokers::API'  => 0,
        # Catch CPANTesters and install the IB libs
        # XXX: Nah, this won't work, already too late for 'make dist'
        #$ENV{AUTOMATED_TESTING} ? (
        #   'Alien::InteractiveBrokers'     => 0,
        #) : (),
        'Alien::InteractiveBrokers'         => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES =>
      'Finance-InteractiveBrokers-SWIG-* *.old IBAPI.pm IBAPI.so IBAPI_wrap.cxx'
    },
);

print <<"EOM";

You may now continue the build by typing:

    make
    make test
    make install

Please consult the documentation via:

    perldoc Finance::InteractiveBrokers::SWIG

EOM

##########################################################################
### Utility subs
##########################################################################

# Parse the path separator out of the trash that Config.pm outputs
sub get_path_sep
{
	my( $garbage ) = Config::config_re( qr/path_sep/ );

	my( $path_sep ) = ( $garbage =~ m/path_sep\=\'(.*)\'/ );

	return( $path_sep );
}

# Find the specified $fname in all dirs in $ENV{PATH}
sub find_bin
{
	my( $fname ) = @_;

	my $path_sep = get_path_sep() || ':';

	my @bindirs = split( $path_sep, $ENV{PATH} );

	my $binpath = '';
	for my $dir ( @bindirs )
	{
		my $testpath = File::Spec->catfile( $dir, $fname );
		$binpath = $testpath, last
			if( -f $testpath );
	}

	return( $binpath );
}

# Get the SWIG version number from the executable
sub check_swig_version
{
	my( $swig ) = @_;

    unless( -x $swig )
    {
        print "\n'$swig' not found or not executable.  SWIG is required for" .
              " this build.\n";
        return( $FALSE );
    }
	my $output = `$swig -version`;

	my( $ver ) = ( $output =~ m/SWIG Version (.*)/m );
	chomp $ver;

	print "\nSWIG version is $ver; this is " .
		  ( $ver ge $min_SWIG_version ? '' : 'NOT ' ) .
		  ">= $min_SWIG_version.\n";

	return( $ver ge $min_SWIG_version ? $TRUE : $FALSE );
}

# Check a few needed files in the IBJts path to see if it's sane
sub found_api
{
	my( $path ) = @_;
	return unless( $path );

	my $result = undef;
	if( -e $path )
	{
	  # Check some files to make sure we're kinda complete
      for my $file (
		'cpp',
		File::Spec->catdir(  'cpp', 'Shared' ),
		File::Spec->catfile( 'cpp', 'Shared', 'EWrapper.h' ),
		File::Spec->catdir(  'cpp', 'PosixSocketClient' ),
        File::Spec->catfile( 'cpp', 'PosixSocketClient', 'EClientSocketBase.cpp' ),
        File::Spec->catfile( 'cpp', 'PosixSocketClient', 'EPosixClientSocket.cpp' )
		)
      {
		return unless( -e File::Spec->catfile( $path, $file ) );
      }
      $result = $path;
	}

	return $result;
}

# Get the IB API version number from the source code distribution
sub get_api_version
{
	my( $path ) = @_;
	return unless( $path );

	my $verfile = File::Spec->catfile( $path, 'API_VersionNum.txt' );
	open my $fd, '<', $verfile or
		return;
	my $contents = do { local $/; <$fd> };
	close( $fd );

	my( $vernum ) = ( $contents =~ m/API_Version=([\d.]*)/mi );

	return( $vernum );
}

# Check with F::IB::API to see if we can work with $VERSION
sub can_use_api_version
{
	my( $api_version ) = @_;

	require Finance::InteractiveBrokers::API;
	my @ok_vers = Finance::InteractiveBrokers::API->api_versions();

	die "\nSorry, this module cannot use found API version $api_version\n" .
	    	"Usable vers are: @ok_vers\n "
		unless( grep { $api_version } @ok_vers );

	print "\nGood, API version $api_version is usable with this module.\n";

	return;
}


##########################################################################
### Tweak the Makefile output
##########################################################################

package MY;

sub top_targets {
	my $postamble;

	# I don't think we can get around much of this with File::Spec->catfile
    my $S        = $^O eq 'MSWin32' ? '\\' : '/';
	my $base_dir = File::Spec->catdir( 'Finance', 'InteractiveBrokers', 'SWIG');
	my $lib_dir  = "\$(INST_LIB)${S}$base_dir";
	my $auto_dir = "\$(INST_ARCHLIB)${S}" .
				   		File::Spec->catdir( 'auto', $base_dir, 'IBAPI' );
	my $perm_dir = $ExtUtils::MakeMaker::VERSION >= 6.52 ? '$(PERM_DIR)' :'755';
	my $api_ver  = main::get_api_version( $IB_BUILD_PATH );
	my $build_time = time();

	# Build the Makefile postamble
	$postamble = <<"POSTAMBLE";
all :: pure_all manifypods
	\$(NOECHO) \$(NOOP)

pure_all :: config pm_to_blib swig
	\$(NOECHO) \$(NOOP)

subdirs :: \$(MYEXTLIB)
	\$(NOECHO) \$(NOOP)

config :: \$(FIRST_MAKEFILE) blibdirs
	\$(NOECHO) \$(NOOP)

help :
	perldoc ExtUtils::MakeMaker

swig :: IBAPI.\$(DLEXT)

IBAPI.\$(DLEXT) :: IBAPI-$api_ver.i IBAPI-$api_ver.cxx IBAPI-$api_ver.h
	\$(MAKE) -ef Makefile.swig "SWIG=$SWIG_PATH" "IB_BUILD_PATH=$IB_BUILD_PATH" "IB_API_VERSION=$api_ver" "BUILD_TIME=$build_time"
	\$(MKPATH) "$lib_dir" "$auto_dir"
	\$(CHMOD) $perm_dir "$auto_dir"
	\$(CP) IBAPI.pm "$lib_dir"${S}
	\$(CP) IBAPI.\$(DLEXT) "$auto_dir"${S}
POSTAMBLE

	return $postamble;
}

# END
