#!/usr/bin/perl

##
#
# file: instart.pl
#
# author: lublud
#
# date: 11/07/2015
#
##

use strict;
use warnings;

main();
getPackageManager();

sub getPackageManager {
    if ($^O eq "linux") {
        my @pm = ();

        do{
			if (-x qx(find /usr/bin -name  $_ | tr -d "\n")) {
                push (@pm, $_);
                last;
            }
        } for qw/apt-get pacman/;

		if (-1 == $#pm) {
			print "System not supported!\nExit program...\n";
			exit;
		}
        
        if ($pm[0] eq "apt-get") {
            push (@pm, "install");
            push (@pm, "update");
            push (@pm, "upgrade");
        }
        elsif ($pm[0] eq "pacman") {
            push (@pm, "-S");
            push (@pm, "-Syu");
        }
        
        return @pm;
    }
} # getPackageManager


sub readConfigFile {
    my @array = ();

    open (CONFIGFILE, "<instart.config")
		or die "Config file missing!\nExit program...\n";

    while (my $line = <CONFIGFILE>) {
        if ($line =~ m/[\w-]*:/) {
            push (@array, split (/:\n/, $line));
        }
    }

    close (CONFIGFILE);

    return @array;

} # readConfigFile

sub menu {
    my @array = @_;

    print "The following list present your packages that you can install ";
    print "along with their configuration file if there is any available\n";

    for my $i (0 .. $#array) {
		my $tmp = $i + 1;
        print "\t$tmp - $array[$i]\n"
    }

    print "\nChoice (0 to quit): ";
    my $in = <STDIN>;
    while ($in < 0 || $in > $#array) {
        $in = <STDIN>;
        print "This option is not available...\nChoice: ";
    }

	if (0 == $in) {
		exit;
	}

    return $in - 1;

} # menu



sub main {

    my @array = readConfigFile();
    my @pm = getPackageManager();

    print " .__                 __                 __   \n";
    print " |__| ____   _______/  |______ ________/  |_ \n";
    print " |  |/    \\ /  ___/\\   __\\__  \\\\_  __ \\   __\\\n";
    print " |  |   |  \\\\___ \\  |  |  / __ \\|  | \\/|  |  \n";
    print " |__|___|  /____  > |__| (____  /__|   |__|  \n";
    print "         \\/     \\/            \\/             \n";

	while (1) {
		print "\n";
		my $choice = menu(@array);

		print "About to execute \"sudo $pm[0] $pm[1] $array[$choice]\" ...\n";
		my $rep = "no";
		while (1) {
			print "Do you want to continue ";
			print "(your password might be requested)? (yes/no) ";
			chomp ($rep = <STDIN>);
			if ("yes" eq $rep) {
				qx (sudo $pm[0] $pm[1] $array[$choice]);
				last;
			}
			elsif ("no" eq $rep) {
				last;
			}
		}
	}

} # main
