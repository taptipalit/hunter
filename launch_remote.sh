#!/bin/bash

hostFileName="$1"
cmdFileName="$2"
remoteOutputPath="$3"
numSessions="$4"
rate="$5"

user="$6"

i=1
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ] || [ -z "$6" ] 
then
    	echo "Usage:"
	echo "launch_remote.sh <host_list_file> <command_list_file> <remote_output_path> <num_sessions> <rate> <remote_ssh_user>"	
	exit 1
fi

while read host;
	do echo "Launching clients on $host";
	ssh "$user@$host" "mkdir $remoteOutputPath"
	while read cmd;
		do echo "Running command $cmd --output-log=$remoteOutputPath/result$i.log --num-sessions=$numSessions --rate=$rate";
		ssh "$user@$host -p 10000" "$cmd --output-log=$remoteOutputPath/result$i.log --num-sessions=$numSessions --rate=$rate" > "stdout$i" &
		i=$((i+1))
	done < "$cmdFileName"
	wait
	# Copy over the logs
	cmd="scp -r $user@$host:$remoteOutputPath ."
	echo $cmd
	eval $cmd
	ssh "$user@$host" "rm -rf $remoteOutputPath"
done < "$hostFileName"

