#! /bin/bash

startdir=$PWD
cd /e/Wrath\ of\ the\ Lich\ King\ Beta/Interface/AddOns

echo ""

for folder in `ls -d */.git`
do
	cd $folder/..
	mydir=`pwd | sed "s/.*\///"`

	if [ ! -f "README.textile" ]
	then
		echo "---- $mydir needs a readme ----"
	fi

	cd ..
done

cd "$startdir"
echo ""
exit 0
