#! /bin/bash

touch changelog.txt

tag=`git-describe --tags --abbrev=0 HEAD`
while [ $tag ]
do
	lasttag=`git-describe --tags --abbrev=0 $tag^`
	echo "$tag" >> changelog.txt
	if [ $lasttag ]
	then
		git-log $lasttag..$tag --no-merges --pretty=medium >> changelog.txt
	else
		git-log $tag --no-merges --pretty=medium >> changelog.txt
	fi
	echo "" >> changelog.txt
	tag=$lasttag
done

exit 0
