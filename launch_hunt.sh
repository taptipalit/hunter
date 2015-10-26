#!/bin/bash

hostFileName="$1"
cmdFileName="$2"
remoteOutputPath="$3"
user="$4"

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] 
then
	echo "Usage:"
	echo "launch_hunt.sh <host_list_file> <command_list_file> <remote_output_path> <remote_ssh_user>"
	exit 
fi

rate=4
numSessions=100

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

totalConns=0
totalErrors=0

while :
do
	cp ./stdout* $backUpStdoutDir/
	./launch_remote.sh "$hostFileName" "$cmdFileName" "$remoteOutputPath" "$numSessions" "$rate" "$user"
	if [ $? -ne 0 ]; then
		echo 'Failed launching remote... exiting.'
		exit
	fi
	# Open each file in output directory
	for outputFile in $outputDirPath;
	do
		echo $outputFile
		numConns="$(grep 'Total: connections' $outputFile | awk '{print $3}')"
		numErrors="$(grep 'Errors: total' $outputFile | awk '{print $3}')"
		echo $numErrors
		totalConns="$((totalConns+numConns))"
		totalErrors="$((totalErrors+numErrors))"
	done
	percFailure=$((totalErrors/totalConns*100))
	if [ "$percFailure" -gt 5 ]; then
		echo 'Benchmark failed. Please see the stdout directory for last successful run.'	
		exit 0
	fi
	rate=$((rate+2))
	numSessions=$((numSessions+50))
done

	
