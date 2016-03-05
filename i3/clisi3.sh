#!/bin/bash
# a dynamic Command Line Status printer

#Copyright 2012 Wesley (kbmonkey) Werner

#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.

#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.

# For when just piping to your WM bar isn't enough ;)

# USAGE
# Call this in your ~/.i3/config bar section instead of i3status

# ~/.i3/config example using Super+alt+F1 to F4:
#

# bindcode $mod+Mod1+67 exec echo 'mode1' > /tmp/clis-mode
# bindcode $mod+Mod1+68 exec echo 'mode2' > /tmp/clis-mode
# bindcode $mod+Mod1+69 exec echo 'mode3' > /tmp/clis-mode
# bindcode $mod+Mod1+70 exec echo 'mode4' > /tmp/clis-mode
#
# NOTIFICATIONS
#
# Write notification strings to /tmp/clis-mode
# to show a quick message.
#
# launch clis at login autostart: clis &
# enjoy toggling your bar infos back and forth :)
#
# kbmonkey!
#
# CHANGES
#
# 2013-04-13
# + adapted for i3wm
#
################################################################################

# help text lists the modes available
HELPLINE="S-alt-F2 Top; S-alt-F4 Todo"

# append to help text the WM shortcuts
HELPLINE=""$HELPLINE

################################################################################
i3status | (read line && echo $line && read line && echo $line && while :
do
    read line
    
    # get the mode and notification text
    if [ -e "/tmp/clis-mode" ]; then
        ACTION=`cat /tmp/clis-mode` 
    else ACTION=mode3
    fi
    if [ -e "/tmp/clis-notify" ]; then
        NOTIFY=`cat /tmp/clis-notify`
    else NOTIFY=""
    fi

    # there are notifications
    if [[ "$NOTIFY" != "" ]]; then
        # override the action to bypass the default help text
        ACTION="notify"
        # set the notification text
        INFOLINE="$NOTIFY"
        # remove the notification file
        rm /tmp/clis-notify
        # write to notification history
        echo `date +"%D %T"` "-" $NOTIFY >> /tmp/clis-history
        # foo
        fi
    
    # set music currently playing (if any) as well as position/duration
    INFOMUSIC="`basename \"$(cmus-remote -C status | head -n 2 | tail -n 1 | grep -oP '/(.+)*')\"`"
    INFOMUSIC+=" - $(cmus-remote -C status | head -n 4 | tail -n 1 | grep -oP '[0-9]+') / $(cmus-remote -C status | head -n 3 | tail -n 1 | grep -oP '[0-9]+')"

    # set the text to display based on what mode is set
    case "$ACTION" in
    mode2)
        # top processes
        INFOLINE="`ps -eo '%C%% %c' | sort -k1 -n -r | head -2 | tr '\n' ' '`"
        ;;
    mode3)
        # next calcurse appointment and top todo item
        # must remove tabs and linebreaks
        INFOLINE=`calcurse --day 30 | tr '\n' ' ' | tr '\t' ' '`
        INFOLINE="$INFOLINE `cat ~/.calcurse/todo | head -n 2 | paste -sd -`"
        ;;
    notify)
        # notification text
        # this is here simply to bypass the *) test from setting the $HELPLINE
        ;;  
    *)
        # hotkey help
        INFOLINE=$HELPLINE
        ;;
    esac

    # append the time
    #INFOLINE="$INFOLINE #! `date +%T`"
    INFOLINE="$INFOLINE"

    # emit the i3status text along with our custom string
    tmp="{ \"full_text\":\"${INFOMUSIC}\" }," 
    dat="[$tmp { \"full_text\": \"${INFOLINE}\" },"
    echo "${line/[/$dat}" || exit 1
   
done)
