    .__                 __                 __   
    |__| ____   _______/  |______ ________/  |_ 
    |  |/    \ /  ___/\   __\__  \\_  __ \   __\
    |  |   |  \\___ \  |  |  / __ \|  | \/|  |  
    |__|___|  /____  > |__| (____  /__|   |__|  
            \/     \/            \/             

# Description
Instart is a script especially useful when installing and setting up a new
GNU/Linux distribution. It reads a list of package to be installed along
with their configuration files so time is not wasted doing something that
has already been done again and again before.

# How it works
Once the script is executed, users have three choices beside leaving the
program:

    - Update && upgrade packages/system
    - Install new package
    - Install and/or get config file for shell

If one chooses to install new packages, the list of available package
(`list_package.yml`) is shown. From that list, one needs to write the name
-- as it appears on the screen -- of the package wanted.
Once the package is installed on the system, and if there is any file
available, configuration files are copied to a specified location (that can
eventually be changed).

# Requirements
In order to run this script `YAML::XS` module is needed.

In addition, the user executing the script has to be a sudoers in order
to install the different packages.

## Available package manager
Only two package manager can be used as of today:

    - apt-get
    - pacman
    
## Available packages
The following is the list of available packages. This list can (and will) 
grow by adding packages in `list_package.yml`:

    - alsa-utils
    - axel
    - calcurse
    - cmus
    - curl
    - ddd
    - dunst
    - feh
    - firefox
    - gcc
    - gdb
    - git
    - gpicview
    - htop
    - i3
    - kile (+ texlive)
    - lynx
    - make
    - mplayer
    - ranger
    - rawtherapee
    - scrot
    - stellarium
    - terminator
    - tmux
    - vim
    - xorg
    - zathura

## Available shell
Two shells are available. Depending which is selected, the script will
install them or just copy the configuration files.

    - bash
    - zsh + oh-my-zsh
