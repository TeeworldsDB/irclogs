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

wget -r -np -nH --cut-dirs=1 -R index.html https://ddnet.tw/irclogs/ || exit 1
mv *.log ../ddnet
mv teeworlds/*.log ../teeworlds

cleanup
echo "done."

