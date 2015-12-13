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

        my $packageManager = readPackageManager();

        for (keys %{$packageManager}) {
            if (-x qx(find /usr/bin -name  $_ | tr -d "\n")) {
                push (@pm, $_);
                last;
            }
        }

        if (-1 == $#pm) {
            print "System not supported!\nExit program...\n";
            exit;
        }

        push (@pm, @{$packageManager->{$pm[0]}});

        return @pm;
    }
    else {
        print "System not supported!\nExit program...\n";
        exit;
    }
} # getPackageManager


sub distribSpecific {
    my $packageList = $_[0];
    my $package = $_[1];

    for (my $i = 0;
        $i < $packageList->{package}->{$package}->{distrib}->{nbDistrib};
        ++$i) {
        my $name = "name" . $i;
        my $distrib = $packageList->{package}->{$package}->{distrib}->{$name};
        my $commandDist = "command-" . $distrib;

        if (index (qx (cat /etc/*-release), $distrib) != -1) {
            chomp(my $execommand = $packageList->{package}->{$package}->{distrib}->{$commandDist});
            my @exec = split (/; /, $execommand);

            foreach my $command (@exec) {
                system ($command);
            }
        }
    }

} # distribSpecific


sub readPackageList {
    return LoadFile ('list_package.yml');
} # readPackageList


sub readVimPlugins {
    return LoadFile ('vim_plugins.yml');
} # readVimPlugins 


sub readPackageManager {
    return LoadFile ('package_manager.yml');
} # readPackageManager

sub readListPython {
    return LoadFile ('list_python.yml');
} # readListPython


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
    my $packageList = $_[0];
    my $package = $_[1];
    my @pm = splice (@_, 2, $#_);
        
    if (exists $packageList->{package}->{$package}->{distrib}) {
        distribSpecific ($packageList, $package);
    }

    print "\nAbout to execute \`sudo $pm[0] $pm[1] $package\` ...\n";
    sleep (1);
    if (! system ("sudo $pm[0] $pm[1] $package")) {
        for (my $i = 0;
                $i < $packageList->{package}->{$package}->{nbConfigFile};
                ++$i) {
            my $conf = "configFile" . $i;
            my $path = "defaultPath" . $i;

            my $packageListFile = $packageList->{package}->{$package}->{$conf};
            my $defaultPath = $packageList->{package}->{$package}->{$path};

            $packageListFile =~ s/~/$ENV{HOME}/;
            $defaultPath =~ s/~/$ENV{HOME}/;

            print "\nDestination for $packageListFile ";
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

            print "Copy \`$packageListFile\` to \`$defaultPath\`...\n";
            copy ($packageListFile, $defaultPath) or die "Copy failed: $!\n";

# Append to file possible new lines
            my $add = "addLine" . $i;
            if (exists $packageList->{package}->{$package}->{$add}) {
                open my $out, '>>', "$defaultPath" or die "Write failed: $!\n";

                my @addLine = split (/, /,
                        $packageList->{package}->{$package}->{$add});
                print $out "\n";
                foreach my $line (@addLine) {
                    print $out "$line\n";
                }
            }
        }

        if (exists $packageList->{package}->{$package}->{execute}) {
            chomp(my $execommand = $packageList->{package}->{$package}->{execute});
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
        if (exists $packageList->{package}->{$package}->{warning}) {
            print "Warning: ";
            print "$packageList->{package}->{$package}->{warning}";
        }
    }
} # execute


sub installPackage {
    my $packageList = $_[0];
    my @pm = splice (@_, 1, $#_);

    my @listpackage = menuPackage($packageList);
    if ($listpackage[0] eq "cancel") {
        return;
    }

    foreach my $choice (@listpackage) {

        my $req = $packageList->{package}->{$choice}->{requires};
        if ($req  ne "none") {
            print "In order to install $choice, the following package(s) need(s) ";
            print "to be installed: $req\n";
            my @requires = split (/, /, $req);
            foreach my $package (@requires) {
                if (exists $packageList->{package}) {
                    execute ($packageList, $package, @pm);
                }
                else {
                    system ("sudo $pm[0] $pm[1] $package");
                }
            }
        }

        execute ($packageList, $choice, @pm);
    }

} # installPackage

sub configShell {
    my @pm = @_;

    print "\n";
    print "Shell available:\n";
    print "\t1 - bash\n\t2 - oh-my-zsh\n\t3 - cancel\n\n";
    print "Choice: ";

    my $choice = <STDIN>;
    chomp ($choice);
    while ($choice ne "1" && $choice ne "2" && $choice ne "3") {
        print "Option not available...\nChoose an existing option: ";
        chomp ($choice = <STDIN>);
    }

    my $directory = "";
    my $dest = $ENV{HOME} . "/";
    if ("1" eq $choice) {
        $directory = "./bash"; 
        $dest = $dest . ".";
    }
    elsif ("2" eq $choice) {
        $directory = "./zsh";
        $dest = $dest . ".oh-my-zsh/custom/";

        print "Installing Zsh...\n";
        system ("sudo $pm[0] $pm[1] zsh");
        system ("chsh -s /usr/bin/zsh");

        print "Downloading and installing oh-my-zsh...\n";
        system ("sh -c \"\$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)\"")
    }
    else { # cancel
        return;
    }


    my @dir = <"$directory/*">;
    foreach my $file (@dir) {
        my @filename = split (/\//, $file);
        my $tmp = $dest . $filename[$#filename];
        print "Copy \`$file\` to \`$tmp\`...\n";
        copy ($file, $tmp) or die "Copy failed: $!\n";
    }

} # configShell


sub menuPackage {
    my $packageList = $_[0];

    print "\n";
    print "The following list presents packages that you can install ";
    print "along with their configuration file if there is any available\n";
    print "You can choose several packages by separating them with a space\n";

    for (keys %{$packageList->{package}}) {
        print "\t - $_\n";
    }

    my @listpackage = ();

    my $tmp = 0;
    while ($tmp == 0) {
        print "\nChoice (cancel to cancel): ";
        my $in = "";
        chomp ($in = <STDIN>);

        if ($in eq "cancel") {
            push (@listpackage, "cancel");
            return @listpackage;
        }

        my @packages = split (/ /, $in);

        foreach my $pack (@packages) {
            if (! exists $packageList->{package}->{$pack}) {
                print "Unknown $pack. Ignoring...\n";
            } else {
                push (@listpackage, $pack);
                $tmp = $tmp + 1;
            }
        }
    }

    return @listpackage;

} # menuPackage


sub vimPlugin {
    print "\n";
    print "This script uses pathogen in order to install any plugin.";

    my $vimPlugins = readVimPlugins();

    if ( ! -f "$ENV{HOME}/.vim/autoload/pathogen.vim") {
        chomp(my $execommand = $vimPlugins->{pathogen});
        my @exec = split (/; /, $execommand);
        print "\n";

        foreach my $command (@exec) {
            print "Executing \`$command\` ...\n";
            $command =~ s/~/$ENV{HOME}/;
            system ($command);
        }
    }

    my @vimplugins = menuVimPlugins($vimPlugins);
    if ($vimplugins[0] eq "cancel") {
        return;
    }

    foreach my $choice (@vimplugins) {
        chomp(my $execommand = $vimPlugins->{plugins}->{$choice});
        my @exec = split (/; /, $execommand);
        print "\n";

        my $currentDir = `pwd`;
        chomp($currentDir);
        chdir("$ENV{HOME}/.vim/bundle");
        foreach my $command (@exec) {
            print "Executing \`$command\` ...\n";
            $command =~ s/~/$ENV{HOME}/;
            system ($command);
        }
        chdir("$currentDir");
    }

} # vimPlugin


sub menuVimPlugins {
    my $vimPlugins = $_[0];

    print "\n";
    print "The following list presents vim plugins that you can install\n";
    print "You can choose several plugins by separating them with a space\n";

    for (keys %{$vimPlugins->{plugins}}) {
        print "\t - $_\n";
    }

    my @plugins = ();

    print "\nChoice (cancel to cancel): ";
    my $in = "";
    chomp ($in = <STDIN>);

    if ($in eq "cancel") {
        push (@plugins, "cancel");
        return @plugins;
    }

    my @listPlugins = split (/ /, $in);

    foreach my $pack (@listPlugins) {
        if (! exists $vimPlugins->{plugins}->{$pack}) {
            print "Unknown $pack. Ignoring.\n";
        } else {
            push (@plugins, $pack);
        }
    }

    return @plugins;

} # menuVimPlugins

sub pipInstall {
    if (not -x qx(find /usr/bin -name pip | tr -d "\n")) {
        if (not -x qx(find /usr/bin -name wget | tr -d "\n")) {
            print "`wget` is required to download `pip`. Please install `wget`...\n";
            sleep 1;
            return;
        }
        print "Downloading and installing pip...\n";
        my $command = "wget https://bootstrap.pypa.io/get-pip.py";
        system ($command);
        system ("sudo python get-pip.py");
        unlink ("get-pip.py");

    }

    my $listPython = readListPython();
    my $command = "sudo pip install";

    print "Do you want to do an update? (y/n) ";
    my $in = "";
    chomp ($in = <STDIN>);

    if ($in eq "y") {
        $command .= " -U";
    }

    # print menu
    foreach my $tmp (@{$listPython->{package}}) {
        print "\t - $tmp\n";
    }

    while (1) {
        print "\nChoice (cancel to cancel): ";
        chomp ($in = <STDIN>);

        if ($in eq "cancel") {
            return;
        }

        my @packages = split (/ /, $in);

        foreach my $pack (@packages) {
            if ($pack ~~ @{$listPython->{package}}) {
                system ($command . " $pack");
                print "\n";
            } else {
                print "Unknown $pack. Ignoring...\n";
            }
        }
    }

} # pipInstall


sub main {
    my $packageList = readPackageList();
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
        print "\t1 - Update && Upgrade\n\t2 - Install package\n";
        print "\t3 - Shell\n\t4 - Vim plugins\n\t5 - Python (pip)";
        print "\n\t6 - Quit\n\n";

        print "Choice: ";

        my $choice = <STDIN>;
        chomp ($choice);
        while ($choice ne "1" && $choice ne "2" &&
                $choice ne "3" && $choice ne "4" &&
                $choice ne "5" && $choice ne "6") {
            print "Option not available...\nChoose an existing option: ";
            chomp ($choice = <STDIN>);
        }

        if ("1" eq $choice) {
            update (@pm);
        }
        elsif ("2" eq $choice) {
            installPackage($packageList, @pm);
        }
        elsif ("3" eq $choice) {
            configShell(@pm);
        }
        elsif ("4" eq $choice) {
            vimPlugin();
        }
        elsif ("5" eq $choice) {
            pipInstall();
        }
        else {
            print "Thank you for using instart!\n\n";
            exit;
        }
    }

} # main
