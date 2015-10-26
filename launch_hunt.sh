#!/bin/bash

hostFileName="$1"
cmdFileName="$2"
remoteOutputPath="$3"
user="$4"

success=1
rate=4
numSessions=100

outputDir="./output"
if [ -d "$outputDir" ]; then
	rm -rf "$outputDir"
fik
backUpStdoutDir="./stdoutDir"
if [ -d "$backUpStdoutDir" ]; then
	rm -rf "$backupStdoutDir"
fi

mkdir "$backUpStdoutDir"

totalConns=0
totalErrors=0

while [ $success -eq 1 ]
do
	cp ./stdout* $backUpStdoutDir
	./launch_remote.sh "$hostFileName $cmdFileName $remoteOutputPath $numSessions $rate $user"
	# Open each file in output directory
	for outputFile in $outputDir;
	do
		numConns="$(grep 'Total: connections' $outputFile | awk '{print $3}')"
		numErrors="$(grep 'Errors: total' $outputFile | awk '{print $3}')"
		totalConns="$((totalConns+numConns))"
		totalErrors="$((totalErrors+numErrors))"
	done
	percFailure=$((totalErrors/totalConns*100))
	if [ "$percFailure" -gt 5 ]; then
		echo 'Benchmark failed. Please see the stdout directory for last successful run.'	
		exit 0
	fi
done

	
