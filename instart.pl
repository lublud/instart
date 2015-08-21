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

sub distribSpecific {
    my $config = $_[0];
    my $package = $_[1];
    my $distrib = $config->{package}->{$package}->{distrib}->{name};
    print $distrib;
    if (index (qx (cat /etc/*-release), $distrib) != -1) {
        chomp(my $execommand = $config->{package}->{$package}->{distrib}->{command});
        my @exec = split (/; /, $execommand);

        foreach my $command (@exec) {
            print "\nAbout to execute \`$command\` ...\n";
            print "Do you want to continue? (yes/no) ";
            my $tmp = <STDIN>;
            chomp ($tmp);
            if ("yes" eq $tmp) {
                system ($command);
            }
        }
    }

} # distribSpecific


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


sub execute {
    my $config = $_[0];
    my $package = $_[1];
    my @pm = splice (@_, 2, $#_);

    print "\nAbout to execute \`sudo $pm[0] $pm[1] $package\` ...\n";
    sleep (1);
    if (! system ("sudo $pm[0] $pm[1] $package")) {
        for (my $i = 0;
                $i < $config->{package}->{$package}->{nbConfigFile};
                ++$i) {
            my $conf = "configFile" . $i;
            my $path = "defaultPath" . $i;

            my $configFile = $config->{package}->{$package}->{$conf};
            my $defaultPath = $config->{package}->{$package}->{$path};

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
            copy ($configFile, $defaultPath) or die "Copy failed: $!\n";

# Append to file possible new lines
            my $add = "addLine" . $i;
            if (exists $config->{package}->{$package}->{$add}) {
                open my $out, '>>', "$defaultPath" or die "Write failed: $!\n";

                my @addLine = split (/, /,
                        $config->{package}->{$package}->{$add});
                print $out "\n";
                foreach my $line (@addLine) {
                    print $out "$line\n";
                }
            }
        }

        if (exists $config->{package}->{$package}->{execute}) {
            chomp(my $execommand = $config->{package}->{$package}->{execute});
            my @exec = split (/; /, $execommand);
            foreach my $command (@exec) {
                print "\nAbout to execute \`$command\` ...\n";
                print "Do you want to continue? (yes/no) ";
                my $tmp = <STDIN>;
                chomp ($tmp);
                if ("yes" eq $tmp) {
                    system ($command);
                }
            }
        }
        if (exists $config->{package}->{$package}->{warning}) {
            print "Warning: ";
            print "$config->{package}->{$package}->{warning}";
        }
    }
} # execute


sub installPackage {
    my $config = $_[0];
    my @pm = splice (@_, 1, $#_);

    my $choice = menu($config);

    distribSpecific ($config, $choice);

    my $req = $config->{package}->{$choice}->{requires};
    if ($req  ne "none") {
        print "In order to install $choice, the following package(s) need(s) ";
        print "to be installed: $req\n";
        my @requires = split (/, /, $req);
        foreach my $package (@requires) {
            if (exists $config->{package}) {
                execute ($config, $package, @pm);
            }
            else {
                system ("sudo $pm[0] $pm[1] $package");
            }
        }
    }

    execute ($config, $choice, @pm);

} # installPackage

sub configShell {
    my @pm = @_;

    print "\n";
    print "Shell available:\n";
    print "\t1 - bash\n\t2 - oh-my-zsh\n\n";
    print "Choice: ";

    my $choice = <STDIN>;
    chomp ($choice);
    while ($choice ne "1" && $choice ne "2") {
        print "Option not available...\nChoose an existing option: ";
        chomp ($choice = <STDIN>);
    }

    my $directory = "";
    my $dest = $ENV{HOME} . "/";
    if ("1" eq $choice) {
        $directory = "./bash"; 
        $dest = $dest . ".";
    }
    else {
        $directory = "./zsh";
        $dest = $dest . ".oh-my-zsh/custom/";

        print "Installing Zsh...\n";
        system ("sudo $pm[0] $pm[1] zsh");
        system ("chsh -s /usr/bin/zsh");

        print "Downloading and installing oh-my-zsh...\n";
        system ("sh -c \"\$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)\"")
    }

    my @dir = <"$directory/*">;
    foreach my $file (@dir) {
        my @filename = split (/\//, $file);
        my $tmp = $dest . $filename[$#filename];
        print "Copy \`$file\` to \`$tmp\`...\n";
        copy ($file, $tmp) or die "Copy failed: $!\n";
    }

} # configShell


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
        print "\t1 - Update && Upgrade\n\t2 - Install package\n\t3 - shell ";
        print "\n\t4 - Quit\n\n";

        print "Choice: ";

        my $choice = <STDIN>;
        chomp ($choice);
        while ($choice ne "1" && $choice ne "2" &&
                $choice ne "3" && $choice ne "4") {
            print "Option not available...\nChoose an existing option: ";
            chomp ($choice = <STDIN>);
        }

        if ("1" eq $choice) {
            update (@pm);
        }
        elsif ("2" eq $choice) {
            installPackage($config, @pm);
        }
        elsif ("3" eq $choice) {
            configShell(@pm);
        }
        else {
            print "Thank you for using instart!\n\n";
            exit;
        }
    }

} # main
