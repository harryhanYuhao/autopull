#!/bin/sh
# This script attempts to be posix compliant
# if no arguments are supplied exit
# if one argument is supplied, pull the repo
# if more than one argument is supplied, parse the options


# version number
autopull_VERSION_MAJOR=0
autopull_VERSION_MINOR=1
autopull_LISENCE="GNU GPLv3"

# Core functionalities
# cache file record the time of git pull to determine if the directory shall be pulled
cachedFileDir="$HOME/.cache/autopull/"

lockFileName="autopull.lock"
lockFilePath="${cachedFileDir}${lockFileName}"
autopullExecuted=0

#Defualt frequency is 1 day
checkTimeCommand="date -Idate"
curTime=""

# determine if directory shall be pulled
# return 1 if is shall not, 0 if it shall
# input: directory name in which git pull shall be executed
pullStatus () {
	if ! [ -d $1 ]; then
		echo "$1 not found!"
		return 1
	fi

	cacheFileName="`echo $1 | tr '/' '%'`_pulled"
	cacheFilePath="${cachedFileDir}${cacheFileName}"

	if ! [ -f $cacheFilePath ]; then
		echo "create file $cacheFilePath"
		if ! [ -d $cachedFileDir ]; then
			mkdir -p $cachedFileDir
		fi
		cd $cachedFileDir
		touch $cacheFileName
		cd $HOME
		curTime=`$checkTimeCommand`
		return 0
	fi

  # in such case, both the pulling directory and the cached file exist
  # check when was the cached file updated
  recordedTime=`cat ${cacheFilePath}`
  curTime=`$checkTimeCommand`

  if ! [ "$recordedTime" = "$curTime" ]; then
	  return 0
  else
	  return 1
  fi
}

# record the time of git pull to cached file
recordSuccessPullToCachedFile () {
	((autopullExecuted++))
	cacheFileName="`echo $1 | tr '/' '%'`_pulled"
	cacheFilePath="${cachedFileDir}${cacheFileName}"
	echo $curTime > $cacheFilePath
	return 0
}

pullRepo () {
	# check if the directory is shall be pulled
	# if pullStatus return 0, the if is executed
	# if it return 1, the else is executed 
	if pullStatus $1 ; then
		echo "$1 shall be pulled!"
		cd $1
		# nohup git pull > /dev/null 2>&1 
		git pull
		if [ $? -eq 0 ]; then
			recordSuccessPullToCachedFile $1
		else
			echo "$1 pull failed!"
		fi 
		cd $HOME
	fi
}

atomic_lock () {
	if [ -f $lockFilePath ]; then
		exit 1;
	fi
	mkdir -p $cachedFileDir
	cd $cachedFileDir
	touch $lockFileName
	cd $HOME
}

atomic_unlock () {
	rm $lockFilePath
}

# Auxiliary functions
# print version 

printVersion () {
	echo "autopull.sh  v${autopull_VERSION_MAJOR}.${autopull_VERSION_MINOR}"
	echo "By Yuhao Han"
	echo "LICENSE: ${autopull_LISENCE}"
}


help () {
	echo "NAME"
	echo "      autopull.sh - Automating pull git repo"
	echo
	echo "SYNOPSIS:"
	echo "      autopull.sh [options]... directory [directory] ..."
	echo
	echo "DESCRIPTION:"
	echo "      Automating pull git repo. Pull the repo and record pull time"
	echo "      Can be placed in bashrc to pull repo automatically"
	echo
	echo "  -D, --day:" 
	echo "      pull if it has been 1 day since last pull"
	echo 
	echo "  -H, --hour:"
	echo "      pull if it has been 1 hour since last pull"
	echo 
	echo "  -M, --minute:"
	echo "      pull if it has been 1 minute since last pull"
	echo 
	echo "  -S, --second:"
	echo "      pull if it has been 1 second since last pull"
	echo 
	echo "  -h, --help:"
	echo "      print this help message"
	echo 
	echo "  -v, --version:"
	echo "      print version"
	echo
	echo "Example:"
	echo "  autopull.sh ~/repo # pulling ~/repo if it has been 1 day since last pull"
	echo "  autopull.sh -H ~/repo # pull if it has been 1 hour since last pull"
	echo
	echo "LICENSE:"
	echo "      ${autopull_LISENCE}"
}

###########################
# Start of execution 
###########################

if [ $# -eq 0 ]; then
	help
	exit 0
fi

while [ $# -gt 0 ]; do 
	case $1 in 
		-D|--day)
			checkTimeCommand="date -Idate"
			shift
			;;
		-H|--hour)
			checkTimeCommand="date -Ihour"
			shift
			;;
		-M|--minute)
			checkTimeCommand="date -Iminute"
			shift
			;;
		-S|--second)
			checkTimeCommand="date -Isecond"
			shift
			;;
		-h|--help)
			help
			exit 0
			;;
		-v|--version)
			printVersion
			exit 0
			;;
		-*|--*)
			echo "Invalid option: $1"
			help
			exit 1
			;;
		*)
			pullDirCandidates="$pullDirCandidates ${1}"
			shift
			;;
	esac
done

# start of pulling

# avoid parallel execution:

if [ -f $lockFilePath ]; then
	exit 1;
fi

atomic_lock

for i in $pullDirCandidates; do
	# if the last characters of the string is '/', remove it
	while [ `echo $i | tail -c 2` = '/' ]; do
		i=${i%?}
	done
	pullRepo $i
done

if [[ $autopullExecuted == 0 ]]; then
	echo "autopull no repo updated!" 
	echo "autopull no repo updated!" | logger
else 
	buf="autopull exectued ${autopullExecuted} times\n pulled ${pullDirCandidates}"
	echo -e $buf
	echo -e $buf | logger
fi

atomic_unlock
