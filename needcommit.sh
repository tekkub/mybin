#! /bin/bash

startdir=$PWD
cd /c/Program\ Files/World\ of\ Warcraft/Interface/AddOns

echo ""

for folder in `ls -d */.git`
do
	cd $folder/..
	mydir=`pwd | sed "s/.*\///"`

	if ! git-status | grep "nothing to commit (working directory clean)" > /dev/null
	then
		echo "---- $mydir has uncommitted changes ----"
	fi

	cd ..
done

cd "$startdir"
echo ""
exit 0
