#!/bin/bash

if [ ! -d .git ]
then
    echo "Error: Make sure you are at the root of the git repo"
    exit 1
fi
if ! git remote -v | grep -q irc
then
    echo "Error: This is not a irc git repository"
    exit 1
fi

log() {
	echo "[*] $1"
}
err() {
	echo "[-] $1" 1>&2
}

function cleanup() {
    if [ -d tmp/ ]
    then
        rm -rf tmp/
    fi
}

cleanup
mkdir -p tmp/ || exit 1
mkdir -p ddnet/ || exit 1
mkdir -p teeworlds/ || exit 1
cd tmp/ || exit 1

git pull

download_full() {
	log "doing full download updating all logfiles ..."
	wget -r -np -nH --cut-dirs=1 -R index.html https://ddnet.org/irclogs/ || exit 1
	mv ./*.log ../ddnet
	mv teeworlds/*.log ../teeworlds
}

download_partial_newest() {
	# this only includes ddnet not the teeworlds/ subdirectory
	# this only redownloads logs from 2024 and later
	local from_year=2024
	local max_year_last_digit
	max_year_last_digit="$((from_year - 1))"
	max_year_last_digit="${max_year_last_digit:3}"
	log "doing partial download starting from year $from_year ..."
	curl -L https://ddnet.org/irclogs > index.html || exit 1
	if [ "$from_year" -gt 2029 ]
	then
		err "Error: this half a decade old code refuses to work"
		exit 1
	fi
	local logfile
	while read -r logfile
	do
		local url
		url="https://ddnet.org/irclogs/$logfile"
		log "downloading $url ..."
		if ! curl -O "$url"
		then
			err "Error: curl failed to download $url"
			exit 1
		fi
	done < <(grep -Eo '<a href="[^"]+"' index.html |
		cut -d'"' -f2 |
		grep '.log$' |
		sort |
		tac |
		grep -vE '^201' |
		grep -vE "^202[0-$max_year_last_digit]")
	# TODO: this will break in 2030

	mv ./*.log ../ddnet
}

arg_full=0

for arg in "$@"
do
	if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]
	then
		echo "usage: $0 [--full]"
		exit 0
	elif [ "$arg" == "--full" ]
	then
		arg_full=1
	else
		echo "unknown arg '$arg'"
		exit 1
	fi
done

if [ "$arg_full" == "1" ]
then
	download_full
else
	download_partial_newest
fi

cleanup
echo "done."

