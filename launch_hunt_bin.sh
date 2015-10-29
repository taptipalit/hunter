#!/bin/bash

hostFileName="$1"
numClientsPerHost="$2"
videoServerIp="$3"
log1="$4"
log2="$5"
log3="$6"
log4="$7"
remoteOutputPath="$8"
user="$9"

totalMinNumSessions="${10}"
totalMaxNumSessions="${11}"

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ] || [ -z "$6" ] || [ -z "$7" ] || [ -z "$8" ] || [ -z "$9" ] || [ -z "${10}" ] || [ -z "${11}" ]
then
	echo "Usage:"
	echo "launch_hunt_bin.sh <host_list_file> <num_clients_per_host> <video_server_ip> <log1> <log2> <log3> <log4>  <remote_output_path> <remote_ssh_user> <min_num_sessions> <max_num_sessions>"
	exit 
fi

# Distribute the load
numHosts=$(wc -l < $hostFileName)
numTotalClients=$(echo "$numHosts*$numClientsPerHost" | bc)
minNumSessions=$(echo "$totalMinNumSessions/$numTotalClients" | bc)
maxNumSessions=$(echo "$totalMaxNumSessions/$numTotalClients" | bc)

# echo "Total clients = $numTotalClients"
# echo "Minimum number of sessions = $minNumSessions"
# echo "Maximum number of sessions = $maxNumSessions"

benchmarkSuccess=1

rate=4

outputDir="./output"
outputDirPath="./output/*"

if [ -d "$outputDir" ]; then
	rm -rf "$outputDir"
fi
backUpStdoutDir="./stdoutDir"
if [ -d "$backUpStdoutDir" ]; then
	rm -rf "$backUpStdoutDir"
fi

mkdir "$backUpStdoutDir"

# Launches remote with the specified number of sessions. 
# Sets benchmarkSuccess to 1 or 0 depending on success/failure
function launchRemote () {
	totalConns=0
	totalErrors=0
	
	numSessions="$1"
	rate=$((numSessions/10))
	cp ./stdout* $backUpStdoutDir/
	./launch_remote.sh "$hostFileName" "$numClientsPerHost" "$videoServerIp" "$log1" "$log2" "$log3" "$log4" "$numSessions" "$remoteOutputPath" "$rate" "$user"
	if [ $? -ne 0 ]; then
		echo 'Failed launching remote... exiting.'
		exit
	fi
	# Open each file in output directory
	for outputFile in $outputDirPath;
	do
		numConns="$(grep 'Total: connections' $outputFile | awk '{print $3}')"
		numErrors="$(grep 'Errors: total' $outputFile | awk '{print $3}')"
		totalConns="$((totalConns+numConns))"
		totalErrors="$((totalErrors+numErrors))"
	done
	percFailure=$(echo "$totalErrors/$totalConns*100" | bc -l)
	percFailure=$(echo "$percFailure/1" | bc)
	#echo "Total conns = $totalConns"
	#echo "Total errors = $totalErrors"
	echo "Percentage failure = $percFailure"
	if [ "$percFailure" -gt 5 ]; then
		echo 'Benchmark failed. Please see the stdout directory for last successful run.'	
		benchmarkSuccess=0
	else
		benchmarkSuccess=1
	fi
}

# Test for minNumSessions
launchRemote $minNumSessions

if [ $benchmarkSuccess -eq 0 ]
then
	echo "Benchmark failed for $minNumSessions sessions"
	echo "Minimum Limit for number of sessions too high."
	exit 0
else
	echo "Benchmark succeeded for $minNumSessions sessions"
fi


# Test for maxNumSessions
launchRemote $maxNumSessions

if [ $benchmarkSuccess -eq 1 ]
then
	echo "Benchmark succeeded for $maxNumSessions sessions"
	echo "Maximum limit for number of sessions too low."
	exit 0
else
	echo "Benchmark failed for $maxNumSessions sessions"
fi

lowLimSessions=$minNumSessions
hiLimSessions=$maxNumSessions

# Launch binary search
while :
do
	diff=$((maxNumSessions-minNumSessions))
	if [ $diff -le 50 ]
	then
		maxThroughput=$(echo "$numSessions*$numTotalClients" | bc)
		echo "Benchmark succeeded for maximum sessions: $maxThroughput"
		exit 0
	fi
	delta=$(((maxNumSessions-minNumSessions)/2))
	numSessions=$((minNumSessions+delta))
	launchRemote $numSessions
	if [ "$benchmarkSuccess" -eq 0 ]
	then
		maxNumSessions=$numSessions
	else
		minNumSessions=$numSessions
	fi
done
