#!/bin/bash

#  traceAndAnalyze.sh
#  ThreadAnalyzer
#
#  Created by Kalpesh Padia on 7/9/14.
#  Copyright (c) 2014 Yahoo! Inc. All rights reserved.

# initialize to 0
OPTIONS=0

#help message
USAGE="$0 {-p pid | -P processName} [-n niceValue] [-c classWhiteList] [-f functionWhiteList] [-u userClassList] [-b bufferSize] [-s switchRate] [-w {YES(default) | NO}] [-h]" 

# parse command line arguments
while getopts ":p:P:c:f:n:u:b:s:w:h" opt; do
    case $opt in
# pid
        p)
            # supply either of -p or -P
            if [[ $PROCESS ]]
            then
                echo "Supply one of -p or -P"
                echo $USAGE
                exit 1
            fi

            # if already supplied, ignore
            if [[ $PID ]]
            then
                echo "Supply each option only once"
                echo $USAGE
                exit 1
            fi

            # verify that an integer is passed as param
            if [[ $OPTARG =~ ^[0-9]+$ ]]
            then
                # assign this param to variable PID
                PID=$OPTARG
            else
                echo "-p requires a process id (postive integer)"
                echo $USAGE
                exit 1
            fi
            # increment the count of number of options passed
            OPTIONS=$(($OPTIONS + 1))
        ;;

# process name
        P)
            # supply either of -p or -P
            if [[ $PID ]]
            then
                echo "Supply one of -p or -P"
                echo $USAGE
                exit 1
            fi

            # if already supplied, ignore
            if [[ $PROCESS ]]
            then
                echo "Supply each option only once"
                echo $USAGE
                exit 1
            fi

            # assign this param to variable PROCESS
            PROCESS=$OPTARG
            # increment the count of number of options passed
            OPTIONS=$(($OPTIONS + 1))
        ;;

# class white list supplied
        c)
            # if already supplied, ignore
            if [[ $CLASSLIST ]]
            then
                echo "Supply each option only once"
                echo $USAGE
                exit 1
            fi

            # assign this param to variable 
            CLASSLIST=$OPTARG
            # increment the count of number of options passed
            OPTIONS=$(($OPTIONS + 1))
        ;;

# function white list supplied
        f)
            # if already supplied, ignore
            if [[ $FUNCLIST ]]
            then
                echo "Supply each option only once"
                echo $USAGE
                exit 1
            fi
            
            # assign this param to variable 
            FUNCLIST=$OPTARG
            # increment the count of number of options passed
            OPTIONS=$(($OPTIONS + 1))
        ;;

# renice the running process before attaching dtrace
        n)
            # if already supplied, ignore
            if [[ $RENICE ]]
            then
                echo "Supply each option only once"
                echo $USAGE
                exit 1
            fi
            
            # verify that an integer is passed as param
            if [[ $OPTARG =~ ^-?[0-9]+$ ]]
            then
                # check if the value is between -20 and 20
                if [[ $OPTARG -lt -20 ]] || [[ $OPTARG -gt 20 ]]
                then
                    echo "-n requires an integer between -20 and 20"
                    echo $USAGE
                    exit 1
                else
                    # assign this param to variable PID
                    RENICE=$OPTARG
                fi
            else
                echo "-n requires an integer between -20 and 20"
                echo $USAGE
                exit 1
            fi

            # increment the count of number of options passed
            OPTIONS=$(($OPTIONS + 1))
        ;;

# user class list supplied
        u)
            # if already supplied, ignore
            if [[ $USERCLASS ]]
            then
                echo "Supply each option only once"
                echo $USAGE
                exit 1
            fi

            # assign this param to variable 
            USERCLASS=$OPTARG
            # increment the count of number of options passed
            OPTIONS=$(($OPTIONS + 1))
        ;;

# bufferSize
        b)
            # if already supplied, ignore
            if [[ $BUFFERSIZE ]]
            then
                echo "Supply each option only once"
                echo $USAGE
                exit 1
            fi

            # verify that an integer is passed as param
            if [[ $OPTARG =~ ^[0-9]+$ ]]
            then
                # assign this param to variable BUFFERSIZE
                BUFFERSIZE=$OPTARG
            else
                echo "-b requires a positive integer for buffer size (in MB)"
                echo $USAGE
                exit 1
            fi
            # increment the count of number of options passed
            OPTIONS=$(($OPTIONS + 1))
        ;;

# switchRate
        s)
            # if already supplied, ignore
            if [[ $SWITCHRATE ]]
            then
                echo "Supply each option only once"
                echo $USAGE
                exit 1
            fi

            # verify that an integer is passed as param
            if [[ $OPTARG =~ ^[0-9]+$ ]]
            then
                # assign this param to variable SWITCHRATE
                SWITCHRATE=$OPTARG
            else
                echo "-s requires a positive integer for switch rate (in Hz)"
                echo $USAGE
                exit 1
            fi
            # increment the count of number of options passed
            OPTIONS=$(($OPTIONS + 1))
        ;;

# use whitelist
        w)
            # if already supplied, ignore
            if [[ $USEWHITELIST ]]
            then
                echo "Supply each option only once"
                echo $USAGE
                exit 1
            fi

            # verify that option is one of yes or no 
            if [[ $OPTARG =~ ^[yY][eE][sS]$ ]]
            then
                # assign this param to variable USEWHITELIST
                USEWHITELIST="YES"
            elif [[ $OPTARG =~ ^[Nn][oO]$ ]]
            then
                # assign this param to variable USEWHITELIST
                USEWHITELIST="NO"
            else
                echo "-w requires Yes or No as input"
                echo $USAGE
                exit 1
            fi
            # increment the count of number of options passed
            OPTIONS=$(($OPTIONS + 1))
        ;;

# print help
        h)
            echo $USAGE
            exit 0
        ;;

# invalid option
        \?)
            echo "Invalid option: -$OPTARG" >&2
            echo $USAGE
            exit 1
        ;;

# no argument supplied
        :)
            if [[ $OPTARG == 'p' ]]
            then
                if [[ $PROCESS ]]
                then
                    echo "Supply one of -p or -P"
                fi
            elif [[ $OPTARG == 'P' ]]
            then
                if [[ $PID ]]
                then
                    echo "Supply one of -p or -P"
                fi
            else
                echo "Option -$OPTARG requires an argument" >&2
            fi

            echo $USAGE
            exit 1
        ;;
    esac
done

# check for appropriate number of options
if [[ $OPTIONS -eq 0 ]]
then
    echo "Invalid number of arguments"
    echo $USAGE
    exit 1
fi

# check if process id or process name is supplied
if [[ -z $PID ]] && [[ -z $PROCESS ]]
then
    echo "At least one of -p or -P must be supplied"
    echo $USAGE
    exit 1
fi

# if not provided, initialize bufferSize to 32MB
if [[ -z $BUFFERSIZE ]]
then
    BUFFERSIZE=32
fi

# if not provided, initialize switchRate to 16Hz
if [[ -z $SWITCHRATE ]]
then
    SWITCHRATE=16
fi

echo "Some commands will be run as root. Please enter your root password when requested."

# if process name is supplied, convert to process id
if [[ $PROCESS ]]
then
    echo "Obtaining pid for the process with name $PROCESS"
    PID=`ps -ae | grep "$PROCESS" | head -n1 | sed 's/^ *//' | cut -d ' ' -f1`
    echo "Obtained pid successfully: $PID"
    echo ""
fi

# renice if required
if [[ -z $RENICE ]]
then
    RENICE=10
    echo "Changing the process priority of $PID to $RENICE (default)"
else
    echo "Changing the process priority of $PID to $RENICE"
fi

RETURNSTATUS=1
until [[ $RETURNSTATUS -eq 0 ]]
do

    sudo renice $RENICE $PID
    RETURNSTATUS=$?
done
echo "Process priority change successful"
echo ""

# attach dtrace
FNAME="trace_`date +%m%d%y_%H%M%S`.txt"
RETURNSTATUS=1
until [[ $RETURNSTATUS -eq 0 ]]
do
    echo "Attaching dtrace now.."
    sudo dtrace -s message_tracker.d -q -b ${BUFFERSIZE}m -x switchrate=${SWITCHRATE}hz -p $PID > $FNAME
    RETURNSTATUS=$?
done

# sort the file
echo "dtrace done. Now sorting trace output.."
echo ""
sort -n $FNAME > sorted_$FNAME


# prepare to start analysis
echo "Starting analysis now.."
# if not provided, turn on whitelists
if [[ -z $USEWHITELIST ]]
then
    USEWHITELIST="YES"
fi

# if whitelists are on, then check for presence of classlists
if [[ $USEWHITELIST == 'YES' ]]
then
    # if not provided, initialize to defaults
    if [[ -z $CLASSLIST ]]
    then
        CLASSLIST="classWhiteList.txt"
    fi
    if [[ -z $FUNCLIST ]]
    then
        FUNCLIST="functionWhiteList.txt"
    fi

    # run the analysis program
    if [[ -z $USERCLASS ]]
    then
        ./ThreadAnalyzer -f $FUNCLIST -c $CLASSLIST sorted_$FNAME
    else
        ./ThreadAnalyzer -f $FUNCLIST -c $CLASSLIST -u $USERCLASS sorted_$FNAME
    fi
else
    # turn off whitelists
    CLASSLIST=""
    FUNCLIST=""
    USERCLASS=""

    # run the analysis program
    ./ThreadAnalyzer sorted_$FNAME
fi

#all done
exit 0