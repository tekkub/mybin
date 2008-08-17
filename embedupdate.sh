#! /bin/bash

filepath=$1
filename=`echo "$filepath" | sed "s/.*\///"`

for newfilename in `/bin/find -name "$filename"`
do
	echo "Replacing $newfilename"
	cp $filepath $newfilename
done

exit 0

