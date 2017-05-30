#!/bin/bash
#author		:	Jigar Joshi & Nirmal Pathak
#version	:	3.0
#date		:	20140322
#description	:	Script to earn bing rewards.

#Browser profile user list.
PROFILE=( 'user1' 'user2' 'user3' )

#iterate through words and broswers
for P in "${PROFILE[@]}"
do
#read random words to a temporary file
	shuf -n 32 /usr/share/dict/words > ~/binger-words.txt
	firefox -P $P "http://www.bing.com/rewards"&
	while read line
	do
#		echo $line
		WID=`xdotool search --name "Bing" | head -1`
		xdotool windowactivate $WID
		xdotool key ctrl+l
		xdotool type "http://www.bing.com/search?q=$line&pc=MOZI"
		xdotool key Return
		sleep 5
	done <  ~/binger-words.txt
	sleep 5
	xdotool key ctrl+q
	#remove temporary file
	rm ~/binger-words.txt
done
