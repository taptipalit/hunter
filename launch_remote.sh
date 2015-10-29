#!/bin/bash

hostFileName="$1"
numClientPerHost="$2"
videoServerIp="$3"
log1="$4"
log2="$5"
log3="$6"
log4="$7"
numSessions="$8"
remoteOutputPath="$9"
rate="${10}"

user="${11}"

i=1
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ] || [ -z "$6" ] || [ -z "$7" ] || [ -z "$8" ] || [ -z "$9" ] || [ -z "${10}" ] || [ -z "${11}" ]
then
    	echo "Usage:"
	echo "launch_remote.sh <host_list_file> <num_clients_per_host> <video_server_ip> <log1> <log2> <log3> <log4> <num_sessions> <remote_output_path> <rate> <remote_ssh_user>"	
	exit 1
fi

while read hostLine
do
	host="$(echo $hostLine | awk '{print $1}')"

	echo "Launching clients on $host";
	clientIp1="$(echo $hostLine | awk '{print $2}')"
	clientIp2="$(echo $hostLine | awk '{print $3}')"
	clientIp3="$(echo $hostLine | awk '{print $4}')"
	clientIp4="$(echo $hostLine | awk '{print $5}')"
	for i in $(seq 1 $numClientPerHost)
 	do
		cmd="./httperf --hog --server $videoServerIp --videosesslog=[$log1,$log2,$log3,$log4],[0.1,0.3,0.4,0.2],[$clientIp1,$clientIp2,$clientIp3,$clientIp4] --epoll --recv-buffer=524288 --port 80 --output-log=$remoteOutputPath/result$i.log --num-sessions=$numSessions --rate=$rate"; 
		echo "Running command $cmd"
		ssh "$user@$host -p 22" "docker exec client_docker $cmd" > "stdout$i" &
	done 
	wait
	# Copy over the logs
	cmd="scp -r $user@$host:$remoteOutputPath/result\* ./output/"
	echo $cmd
	eval $cmd
	ssh "$user@$host" "rm  $remoteOutputPath/result*"
done < "$hostFileName"

