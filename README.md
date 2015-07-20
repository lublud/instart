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
One the script is executed, users can either update and upgrade packages 
and system or install new ones. If they choose to install new packages,
the list of available package (taken from a YAML file) is shown. They then
need to write the name -- as it is shown -- of the package they want to
install.
Once the package is installed on the system, and if there is any config
file available, they are copied to a specified location (can be changed).

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

    - axel
    - cmus
    - ddd
    - gcc
    - gdb
    - git
    - i3
    - lynx
    - make
    - scrot
    - stellarium
    - terminator
    - vim
    - xorg
    - zathura
