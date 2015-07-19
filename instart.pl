#!/usr/bin/perl

##
#
# file: instart.pl
#
# author: lublud
#
# date: 15/07/2015
#
# brief: script installing and setting package for UNIX systems
#
##

use strict;
use warnings;

use YAML::XS qw(LoadFile);
use File::Copy;

main();

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
    my $config = LoadFile ('list_package.yml');

    return $config;

} # readConfigFile

sub update {
    my @pm = @_;

    if ("apt-get" eq $pm[0]) {
        print "Executing \`sudo $pm[0] $pm[2] && $pm[0] $pm[3]\` ...\n";
        system ("sudo $pm[0] $pm[2] && sudo $pm[0] $pm[3]");
    }
    else {
        print "Executing \`sudo $pm[0] $pm[2]\` ...\n";
        system ("sudo $pm[0] $pm[2]");
    }
} # update


sub installPackage {
    my $config = $_[0];
    my @pm = splice (@_, 1, $#_);

    my $choice = menu($config);

    my $req = $config->{package}->{$choice}->{requires};
    if ($req  ne "none") {
        print "In order to install $choice, the following package(s) need(s) ";
        print "to be installed: $req\n";
        my @requires = split (/, /, $req);
        foreach my $package (@requires) {
            print "About to execute \`sudo $pm[0] $pm[1] $package\` ...\n";
            sleep (1);
            system ("sudo $pm[0] $pm[1] $package");
        }
    }

    print "\nAbout to execute \`sudo $pm[0] $pm[1] $choice\` ...\n";
    sleep (1);
    if (! system ("sudo $pm[0] $pm[1] $choice")) {
        for (my $i = 0;
                $i < $config->{package}->{$choice}->{nbConfigFile};
                ++$i) {
            my $conf = "configFile" . $i;
            my $path = "defaultPath" . $i;

            my $configFile = $config->{package}->{$choice}->{$conf};
            my $defaultPath = $config->{package}->{$choice}->{$path};

            $configFile =~ s/~/$ENV{HOME}/;
            $defaultPath =~ s/~/$ENV{HOME}/;

            print "\nDestination for $configFile ";
            print "(default=$defaultPath): ";
            my $tmp = <STDIN>;
            chomp($tmp);
            if ("" ne $tmp) {
                $defaultPath = $tmp;
            }

            my @path = split (/\//, $defaultPath);
            my $subpath = "";
            for my $j (0 .. $#path - 1) {
                $subpath = $subpath . $path[$j] . "/";
                if (! -d $subpath) {
                    print "Creating \`$subpath\' ...\n";
                    mkdir $subpath;
                }
            }

            print "Copy \`$configFile\` to \`$defaultPath\`...\n";
            copy ($configFile, $defaultPath) or die "Copy failed: $!";

            # Append to file possible new lines
            my $add = "addLine" . $i;
            if (exists $config->{package}->{$choice}->{$add}) {
                open my $out, '>>', "$defaultPath" or die "Write failed: $!";

                my @addLine = split (/, /,
                        $config->{package}->{$choice}->{$add});
                print $out "\n";
                foreach my $line (@addLine) {
                    print $out "$line\n";
                }
            }
        }
    }

} # installPackage


sub menu {
    my $config = $_[0];

    print "\n";
    print "The following list present your packages that you can install ";
    print "along with their configuration file if there is any available\n";

    for (keys %{$config->{package}}) {
        print "\t - $_\n";
    }

    print "\nChoice (quit to quit): ";
    my $in = "";
    chomp ($in = <STDIN>);
    if ("quit" eq $in) {
        print "Thank you for using instart!\n\n";
        exit;
    }

    while (! exists $config->{package}->{$in}) {
        print "This option is not available...\nChoice: ";
        chomp ($in = <STDIN>);
        if ("quit" eq $in) {
            print "Thank you for using instart!\n\n";
            exit;
        }
    }

    return $in;

} # menu


sub main {
    my $config = readConfigFile();
    my @pm = getPackageManager();

    print " .__                 __                 __   \n";
    print " |__| ____   _______/  |______ ________/  |_ \n";
    print " |  |/    \\ /  ___/\\   __\\__  \\\\_  __ \\   __\\\n";
    print " |  |   |  \\\\___ \\  |  |  / __ \\|  | \\/|  |  \n";
    print " |__|___|  /____  > |__| (____  /__|   |__|  \n";
    print "         \\/     \\/            \\/             \n";

    print "\n###################################################################\n";
    print "# Warning: In order to use this program, you have to be a sudoer. #\n";
    print "###################################################################";

    while (1) {
        print "\n";
        print "Option available:\n";
        print "\t1 - Update && Upgrade\n\t2 - Install package\n\t3 - Quit\n\n";
        print "Choice: ";

        my $choice = <STDIN>;
        chomp ($choice);
        while ($choice ne "1" && $choice ne "2" && $choice ne "3") {
            print "Option not available...\nChoose an existing option: ";
            chomp ($choice = <STDIN>);
        }

        if ("1" eq $choice) {
            update (@pm);
        }
        elsif ("2" eq $choice) {
            installPackage($config, @pm);
        }
        else {
            print "Thank you for using instart!\n\n";
            exit;
        }
    }

} # main
