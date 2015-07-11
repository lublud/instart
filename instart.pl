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

sub readConfigFile {
    my @array = ();
    open (CONFIGFILE, "instart.config");
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

    print " .__                 __                 __   \n";
    print " |__| ____   _______/  |______ ________/  |_ \n";
    print " |  |/    \\ /  ___/\\   __\\__  \\\\_  __ \\   __\\\n";
    print " |  |   |  \\\\___ \\  |  |  / __ \\|  | \\/|  |  \n";
    print " |__|___|  /____  > |__| (____  /__|   |__|  \n";
    print "         \\/     \\/            \\/             \n";


    print "Welcome to instart!\n\n";
    print "The following list present your packages that you can install";
    print " along with their configuration file if there is any available\n";

    for my $i (0 .. $#array) {
        print "\t$i - $array[$i]\n"
    }

    print "\nChoice: ";
    my $in = -1;
    while ($in < 0 || $in > $#array) {
        $in = <STDIN>;
        print "This option is not available...\nChoice: ";
    }

    return $in;

} # menu



sub main {
    my @array = readConfigFile();
    my $choice = menu(@array);
    print $array[$choice], "\n";

} # main

